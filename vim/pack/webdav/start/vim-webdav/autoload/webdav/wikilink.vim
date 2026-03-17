" autoload/webdav/wikilink.vim - Obsidian-style wikilink support
" Functions for parsing and following [[wikilinks]]

" Extract wikilink at cursor position
" Returns: {'target': 'link_target', 'found': 1} or {'found': 0}
function! webdav#wikilink#extract_at_cursor()
  let line = getline('.')
  let col = col('.') - 1  " 0-based index

  " Find all [[...]] patterns in the line
  let start = 0
  while 1
    let match_start = match(line, '\[\[', start)
    if match_start == -1
      break
    endif

    let match_end = match(line, '\]\]', match_start)
    if match_end == -1
      break
    endif

    " Check if cursor is within this match (inclusive of brackets)
    if col >= match_start && col <= match_end + 1
      " Extract content between [[ and ]]
      let content = line[match_start + 2 : match_end - 1]

      " Handle alias syntax: [[target|alias]] -> target
      let pipe_pos = stridx(content, '|')
      if pipe_pos != -1
        let content = content[0 : pipe_pos - 1]
      endif

      " Handle heading syntax: [[target#heading]] -> target
      let hash_pos = stridx(content, '#')
      if hash_pos != -1
        let content = content[0 : hash_pos - 1]
      endif

      return {'target': content, 'found': 1}
    endif

    let start = match_end + 2
  endwhile

  return {'found': 0}
endfunction

" Resolve wikilink target to WebDAV path
" Parameters:
"   target: link target (e.g., '/notes/file', '../file', 'filename')
"   current_path: current file's WebDAV path (e.g., '/vault/notes/daily/note.md')
"   vault_root: vault root path (e.g., '/vault')
" Returns: resolved absolute path
function! webdav#wikilink#resolve(target, current_path, vault_root)
  let target = webdav#core#clean_string(a:target)

  if empty(target)
    return ''
  endif

  " Add .md extension if not present
  let target = s:ensure_extension(target)

  let vault_root = a:vault_root

  " Determine link type and resolve
  if target =~ '^/'
    " Absolute path: vault_root + target
    return s:normalize_path(vault_root . target)
  elseif target =~ '^\.\.\/' || target =~ '^\./' || target =~ '/'
    " Relative path: resolve from current file's directory
    let current_dir = fnamemodify(a:current_path, ':h')
    let resolved = current_dir . '/' . target
    return s:normalize_path(resolved)
  else
    " Filename only: search vault-wide (Obsidian behavior)
    let current_dir = fnamemodify(a:current_path, ':h')
    let local_path = s:normalize_path(current_dir . '/' . target)

    " Try vault-wide search via PROPFIND cache
    let server_name = exists('b:webdav_server') ? b:webdav_server : ''
    let vault_path = s:search_vault_cache(target, vault_root, server_name)
    if !empty(vault_path)
      return vault_path
    endif

    " Fallback: current directory
    return local_path
  endif
endfunction

" Ensure path has .md extension (if no extension present)
function! s:ensure_extension(path)
  let ext = fnamemodify(a:path, ':e')
  if empty(ext)
    return a:path . '.md'
  endif
  return a:path
endfunction

" Normalize path (resolve ../, ./, and double slashes)
function! s:normalize_path(path)
  let parts = split(a:path, '/')
  let result = []

  for part in parts
    if part == '.' || empty(part)
      continue
    elseif part == '..'
      if !empty(result)
        call remove(result, -1)
      endif
    else
      call add(result, part)
    endif
  endfor

  return '/' . join(result, '/')
endfunction

" Search vault-wide for a filename using PROPFIND scan cache
" Returns: resolved absolute path, or '' if not found
function! s:search_vault_cache(filename, vault_root, server_name) abort
  let server_info = webdav#server#get_info(a:server_name)
  if empty(server_info) || empty(server_info.url)
    return ''
  endif

  let cache_key = webdav#cache#get_key(a:server_name, server_info.url)
  let scan_cache = webdav#cache#get_data()
  let base_path = empty(a:vault_root) ? '/' : a:vault_root
  if base_path !~ '/$'
    let base_path .= '/'
  endif

  if !has_key(scan_cache, cache_key) || !has_key(scan_cache[cache_key], base_path)
    return ''
  endif

  let files = scan_cache[cache_key][base_path]
  let target_name = '/' . a:filename
  for f in files
    if f =~# escape(target_name, '.') . '$'
      return s:normalize_path(base_path . f)
    endif
  endfor

  return ''
endfunction

" Get vault root for server
" Reads from g:webdav_vault_roots configuration
function! webdav#wikilink#get_vault_root(server_name)
  let vault_roots = get(g:, 'webdav_vault_roots', {})

  " Check server-specific setting
  if !empty(a:server_name) && has_key(vault_roots, a:server_name)
    return vault_roots[a:server_name]
  endif

  " Check default setting
  if has_key(vault_roots, 'default')
    return vault_roots['default']
  endif

  return ''
endfunction

" Open wikilink under cursor
" Returns: 1 if link opened, 0 if no link found
function! webdav#wikilink#open()
  " Validate WebDAV buffer
  if !exists('b:webdav_managed') || !b:webdav_managed
    echo "Not a WebDAV buffer"
    return 0
  endif

  " Extract wikilink at cursor
  let link = webdav#wikilink#extract_at_cursor()
  if !link.found
    echo "No wikilink under cursor"
    return 0
  endif

  " Get current file info
  let current_path = b:webdav_original_path
  let server_name = get(b:, 'webdav_server', '')
  let vault_root = webdav#wikilink#get_vault_root(server_name)

  " Debug output
  if get(g:, 'webdav_debug', 0)
    echom '[wikilink] target=' . link.target . ' current=' . current_path . ' vault_root=' . vault_root
  endif

  " Resolve path
  let resolved_path = webdav#wikilink#resolve(link.target, current_path, vault_root)

  if get(g:, 'webdav_debug', 0)
    echom '[wikilink] resolved=' . resolved_path
  endif

  if empty(resolved_path)
    echoerr "Could not resolve wikilink: " . link.target
    return 0
  endif

  " Open the file in a new tab
  tabnew
  call webdav#file#get(resolved_path, server_name)
  return 1
endfunction
