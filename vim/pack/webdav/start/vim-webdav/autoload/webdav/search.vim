" autoload/webdav/search.vim - Server-side search via PROPFIND + curl GET
" No local file sync — streams each file and greps inline

" Get .md file list from PROPFIND cache (or scan if needed)
function! s:get_md_files(server_name) abort
  let server_info = webdav#server#get_info(a:server_name)
  if empty(server_info) || empty(server_info.url)
    return []
  endif

  let vault_root = webdav#wikilink#get_vault_root(a:server_name)
  let base_path = empty(vault_root) ? '/' : vault_root . '/'
  let cache_key = webdav#cache#get_key(a:server_name, server_info.url)
  let scan_cache = webdav#cache#get_data()

  if !has_key(scan_cache, cache_key) || !has_key(scan_cache[cache_key], base_path)
    echo "Scanning..."
    let files = webdav#fzf#scan_recursive(base_path, a:server_name)
    if !has_key(scan_cache, cache_key)
      let scan_cache[cache_key] = {}
    endif
    let scan_cache[cache_key][base_path] = files
  endif

  let files = get(get(scan_cache, cache_key, {}), base_path, [])
  return filter(copy(files), 'v:val =~# "\.md$"')
endfunction

" Build curl auth args
function! s:curl_auth(server_info) abort
  if !empty(a:server_info.user) && !empty(a:server_info.pass)
    return ' -u ' . shellescape(a:server_info.user . ':' . a:server_info.pass)
  endif
  return ''
endfunction

" Grep vault content by streaming each file via curl GET
" Results displayed in quickfix list
function! webdav#search#grep(pattern, ...) abort
  let server_name = a:0 > 0 ? a:1 : (exists('b:webdav_server') ? b:webdav_server : '')
  let server_info = webdav#server#get_info(server_name)
  if empty(server_info) || empty(server_info.url)
    echoerr "Error: Server not configured"
    return
  endif

  let md_files = s:get_md_files(server_name)
  if empty(md_files)
    echo "No markdown files found"
    return
  endif

  let auth = s:curl_auth(server_info)
  let total = len(md_files)
  let qf_items = []

  for idx in range(total)
    let f = md_files[idx]
    let encoded = webdav#core#url_encode('/' . f)
    let url = server_info.url . encoded
    let cmd = 'curl -s --max-time 5' . auth . ' ' . shellescape(url)
    let cmd .= ' | grep -n ' . shellescape(a:pattern)
    let results = systemlist(cmd)

    for line in results
      let parts = matchlist(line, '^\(\d\+\):\(.*\)$')
      if !empty(parts)
        call add(qf_items, {
          \ 'filename': f,
          \ 'lnum': str2nr(parts[1]),
          \ 'col': 1,
          \ 'text': parts[2],
          \ })
      endif
    endfor

    if (idx + 1) % 10 == 0 || idx + 1 == total
      redraw
      echo printf("Searching: %d/%d files (%d matches)", idx + 1, total, len(qf_items))
    endif
  endfor

  if empty(qf_items)
    echo "No matches found for: " . a:pattern
    return
  endif

  call setqflist(qf_items)
  copen
  echo printf("Found %d matches for: %s", len(qf_items), a:pattern)
endfunction

" Interactive grep with fzf — file list from PROPFIND, preview via curl
function! webdav#search#grep_fzf(...) abort
  let server_name = a:0 > 0 ? a:1 : (exists('b:webdav_server') ? b:webdav_server : '')
  let server_info = webdav#server#get_info(server_name)
  if empty(server_info) || empty(server_info.url)
    echoerr "Error: Server not configured"
    return
  endif

  let md_files = s:get_md_files(server_name)
  if empty(md_files)
    echo "No markdown files found"
    return
  endif

  let auth = s:curl_auth(server_info)

  " Preview: curl GET file content
  let preview_cmd = 'curl -s --max-time 5' . auth . ' ' . shellescape(server_info.url) . '/{}'
  if executable('bat')
    let preview_cmd .= ' | bat --color=always --style=plain -l md'
  endif

  call fzf#run(fzf#wrap({
    \ 'source': md_files,
    \ 'sink*': function('s:grep_fzf_sink', [server_name]),
    \ 'options': [
    \   '--prompt', 'Search> ',
    \   '--header', 'Enter: open | Preview: file content',
    \   '--print-query',
    \   '--expect', '',
    \   '--preview', preview_cmd,
    \   '--preview-window', 'down:50%',
    \ ],
    \ 'down': '80%'
  \ }))
endfunction

function! s:grep_fzf_sink(server_name, result) abort
  if len(a:result) < 3 | return | endif

  let selection = a:result[2]
  if empty(selection) | return | endif

  let webdav_path = '/' . selection
  tabnew
  call webdav#file#get(webdav_path, a:server_name)
endfunction

" Show backlinks: files that link to the current file
function! webdav#search#backlinks() abort
  if !get(b:, 'webdav_managed', 0)
    echo "Not a WebDAV buffer"
    return
  endif

  let filename = fnamemodify(b:webdav_original_path, ':t:r')
  let pattern = '\[\[' . escape(filename, '.[]*') . '\(\]\]\|||\#\)'
  let server_name = get(b:, 'webdav_server', '')

  call webdav#search#grep(pattern, server_name)
endfunction
