" autoload/webdav/fzf.vim - FZF integration for WebDAV browsing
" Functions for recursive scanning and fzf-based file selection

" Module-local variables
let s:last_fzf_args = []  " Store last fzf args for ctrl-r reload

" Parse server name and path from command arguments
" Returns: {'server_name': '', 'path': '/', 'error': ''}
function! webdav#fzf#resolve_args(args)
  let result = {'server_name': '', 'path': '/', 'error': ''}

  if len(a:args) == 0
    " No arguments - use current server and root path
    return result
  endif

  let first_arg = a:args[0]

  " Check if first argument is a path (starts with /)
  if first_arg =~ '^/'
    " It's a path - use current server
    let result.path = first_arg
    if len(a:args) > 1
      let result.error = 'Too many arguments'
    endif
  else
    " It's a server name
    let servers = webdav#server#scan()

    if !has_key(servers, first_arg)
      let result.error = "Server '" . first_arg . "' not found"
      return result
    endif

    let result.server_name = first_arg

    " Check for second argument (path)
    if len(a:args) > 1
      let result.path = a:args[1]
      if result.path !~ '^/'
        let result.error = 'Path must start with /'
        return result
      endif
    endif

    if len(a:args) > 2
      let result.error = 'Too many arguments'
    endif
  endif

  return result
endfunction

" Recursively scan WebDAV directory tree using BFS
" Returns: List of file paths (relative to base_path)
function! webdav#fzf#scan_recursive(base_path, server_name = '')
  let server_info = webdav#server#get_info(a:server_name)
  if empty(server_info)
    return []
  endif

  " Clean base_path for consistent use in path calculations
  let clean_base_path = webdav#core#clean_string(a:base_path)

  let files = []
  let queue = [clean_base_path]
  let visited = {}

  " DEBUG: Log base_path at start
  call webdav#core#debug_log("DEBUG SCAN START: base_path=" . string(a:base_path))
  call webdav#core#debug_log("DEBUG SCAN START: clean_base_path=" . string(clean_base_path))

  while len(queue) > 0
    let current_path = remove(queue, 0)

    " Skip if already visited (avoid infinite loops)
    if has_key(visited, current_path)
      continue
    endif
    let visited[current_path] = 1

    " PROPFIND Depth: 1 for current directory (use server_info from function start)
    let cmd = webdav#http#build_request('PROPFIND', current_path, server_info)
    if empty(cmd)
      continue
    endif

    let listing = systemlist(cmd)

    " Process each item in listing
    for item in listing
      " Clean item (remove ALL newlines and whitespace, including mid-string)
      let clean_item = webdav#core#clean_string(item)
      if empty(clean_item)
        continue
      endif

      " Build full path and ensure it's clean (current_path might be contaminated from queue)
      let full_path = webdav#core#clean_string(webdav#core#join_path(current_path, clean_item))

      if clean_item =~ '/$'
        " It's a directory - add to queue for BFS
        call add(queue, full_path)
      else
        " It's a file - add to results (store path relative to base)
        " Use clean_base_path to ensure proper pattern matching
        let relative_path = substitute(full_path, '^' . escape(clean_base_path, '/'), '', '')
        " Ensure no trailing whitespace/newlines in final result
        call add(files, webdav#core#clean_string(relative_path))
      endif
    endfor
  endwhile

  " DEBUG: Log first few files
  if len(files) > 0
    call webdav#core#debug_log("DEBUG SCAN RESULT: First file=" . string(files[0]))
    if len(files) > 1
      call webdav#core#debug_log("DEBUG SCAN RESULT: Second file=" . string(files[1]))
    endif
  endif

  return files
endfunction

" Handle fzf file selection
function! webdav#fzf#open_file(base_path, server_name, selection)
  if empty(a:selection)
    return
  endif

  " DEBUG: Log inputs
  call webdav#core#debug_log("DEBUG OPEN: a:base_path=" . string(a:base_path))
  call webdav#core#debug_log("DEBUG OPEN: a:selection=" . string(a:selection))

  " Use CleanString for consistency (removes all newlines and trims)
  let clean_selection = webdav#core#clean_string(a:selection)
  let clean_base_path = webdav#core#clean_string(a:base_path)

  " Build full path
  let full_path = webdav#core#join_path(clean_base_path, clean_selection)

  " DEBUG: Log cleaned values
  call webdav#core#debug_log("DEBUG OPEN: clean_base_path=" . string(clean_base_path))
  call webdav#core#debug_log("DEBUG OPEN: clean_selection=" . string(clean_selection))
  call webdav#core#debug_log("DEBUG OPEN: full_path=" . string(full_path))

  " Debug: Show what we're opening
  echo "Opening: " . full_path

  " Check if it's a directory (ends with /)
  if clean_selection =~ '/$'
    " Directory selected - show error or open list
    echoerr "Error: Cannot open directory as file: " . full_path
    echoerr "Use WebDAVList to browse directory contents"
    return
  endif

  " Verify it doesn't look like a directory path
  if full_path =~ '/$'
    echoerr "Error: Path ends with /  (directory): " . full_path
    return
  endif

  " Open file in new tab
  tabnew
  call WebDAVGet(full_path, a:server_name)
endfunction

" Handle fzf sink with ctrl-o/ctrl-r support
" Parameters:
"   base_path - base directory path
"   result - array from fzf with --print-query --expect:
"            [query, key, selection] where key is pressed key ('' or 'ctrl-o')
function! webdav#fzf#handle_sink(base_path, fzf_args, server_name, result)
  if len(a:result) < 2
    return
  endif

  let query = a:result[0]
  let key = a:result[1]
  let selection = len(a:result) > 2 ? a:result[2] : ''

  if key == 'ctrl-r'
    " ctrl-r pressed: reload with force_refresh
    call webdav#fzf#main(a:fzf_args, 1)
  elseif key == 'ctrl-o'
    " ctrl-o pressed: use query as filename and open/create
    let clean_query = webdav#core#clean_string(query)
    if empty(clean_query)
      echo "No query entered"
      return
    endif
    " Auto-append .md if no extension is present
    if clean_query !~ '\.\w\+$'
      let clean_query .= '.md'
    endif
    let file_path = webdav#core#join_path(a:base_path, clean_query)
    tabnew
    call WebDAVGet(file_path, a:server_name)
  elseif key == 'ctrl-l'
    " ctrl-l pressed: insert markdown link
    if empty(selection)
      echo "No file selected"
      return
    endif
    call webdav#fzf#insert_link(a:base_path, a:server_name, selection)
  else
    " Normal selection (Enter pressed)
    if empty(selection)
      " No selection - try using query as filename (like ctrl-o)
      let clean_query = webdav#core#clean_string(query)
      if !empty(clean_query)
        " Auto-append .md if no extension
        if clean_query !~ '\.\w\+$'
          let clean_query .= '.md'
        endif
        let file_path = webdav#core#join_path(a:base_path, clean_query)
        tabnew
        call WebDAVGet(file_path, a:server_name)
      else
        echo "No file selected"
      endif
      return
    endif
    call webdav#fzf#open_file(a:base_path, a:server_name, selection)
  endif
endfunction

" Resolve script directory at load time (not inside functions)
let s:plugin_root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h:h')

" Build streaming scan shell command
function! webdav#fzf#build_scan_cmd(base_path, server_info, max_depth) abort
  let script = s:plugin_root . '/scripts/scan-bfs.sh'
  let auth_arg = ''
  if !empty(a:server_info.user) && !empty(a:server_info.pass)
    let auth_arg = '-u ' . a:server_info.user . ':' . a:server_info.pass
  endif
  return 'bash ' . shellescape(script)
    \ . ' ' . shellescape(a:server_info.url)
    \ . ' ' . shellescape(a:base_path)
    \ . ' ' . a:max_depth
    \ . ' ' . shellescape(auth_arg)
endfunction

" Main fzf interface with streaming BFS scan
" Usage: :WebDAVFzf [server_name] [path] or :WebDAVFzf [path]
" :WebDAVFzf! - Force cache refresh
function! webdav#fzf#main(args, force_refresh)
  " Store args for ctrl-r reload
  let s:last_fzf_args = a:args

  " Parse arguments
  let resolved = webdav#fzf#resolve_args(a:args)

  if !empty(resolved.error)
    echoerr "Error: " . resolved.error
    if resolved.error =~ 'not found'
      let servers = webdav#server#scan()
      echo "Available servers: " . join(sort(keys(servers)), ', ')
    endif
    return
  endif

  " Show server being used
  if !empty(resolved.server_name)
    echo "Using server: " . resolved.server_name
  endif

  " Ensure path ends with /
  let base_path = resolved.path
  if base_path !~ '/$'
    let base_path .= '/'
  endif

  " Get server info for cache key
  let server_name = resolved.server_name
  let server_info = webdav#server#get_info(server_name)

  " Check if fzf is available
  if !executable('fzf')
    echoerr "Error: fzf is not installed"
    return
  endif

  " Determine source: cached list or streaming scan
  let max_depth = get(g:, 'webdav_fzf_max_depth', 3)
  let cache_key = webdav#cache#get_key(server_name, server_info.url)
  let scan_cache = webdav#cache#get_data()

  if !has_key(scan_cache, cache_key)
    let scan_cache[cache_key] = {}
  endif

  if !a:force_refresh && has_key(scan_cache[cache_key], base_path)
    let source = scan_cache[cache_key][base_path]
    echo "Using cached results: " . len(source) . " files"
  else
    " Use streaming shell command as fzf source
    let source = webdav#fzf#build_scan_cmd(base_path, server_info, max_depth)
  endif

  " Build fzf options (responsive layout based on terminal width)
  let preview_window = &columns <= 120 ? 'down:40%' : 'right:50%'
  let fzf_options = [
    \ '--prompt', 'WebDAV> ',
    \ '--header', 'ctrl-o: create/open | ctrl-l: insert link | Enter: select | ctrl-r: refresh',
    \ '--print-query',
    \ '--expect', 'ctrl-o,ctrl-r,ctrl-l',
    \ '--preview-window', preview_window
    \ ]

  " Add preview if enabled
  if g:webdav_preview_enabled
    " Build curl command
    let curl_cmd = 'curl -s --max-time 5'

    " Add authentication if available
    if !empty(server_info.user) && !empty(server_info.pass)
      let curl_cmd .= ' -u ' . shellescape(server_info.user . ':' . server_info.pass)
    endif

    " Add URL with base_path + selected file
    let curl_cmd .= ' ' . shellescape(server_info.url . base_path) . '{}'

    " Use bat if available and enabled, otherwise fallback to head
    if g:webdav_preview_use_bat && executable('bat')
      let preview_cmd = curl_cmd . ' | bat --color=always --style=plain --paging=never -l md'
    else
      let preview_cmd = curl_cmd . ' | head -n ' . g:webdav_preview_lines
    endif

    let fzf_options += ['--preview', preview_cmd]
  endif

  " Launch fzf (80% window size for better visibility)
  " source: string → streaming shell command, list → cached results
  call fzf#run(fzf#wrap({
    \ 'source': source,
    \ 'sink*': function('webdav#fzf#handle_sink', [base_path, a:args, resolved.server_name]),
    \ 'options': fzf_options,
    \ 'down': '80%'
  \ }))
endfunction

" Insert markdown link at cursor position
" Parameters: base_path, server_name, selection
function! webdav#fzf#insert_link(base_path, server_name, selection)
  if empty(a:selection)
    return
  endif

  " Clean selection and build full path
  let clean_selection = webdav#core#clean_string(a:selection)
  let full_path = webdav#core#join_path(a:base_path, clean_selection)

  " Build link path (server:path format)
  if !empty(a:server_name)
    let link_path = a:server_name . ':' . full_path
  else
    let link_path = full_path
  endif

  " Extract filename without extension for link text
  let filename = fnamemodify(clean_selection, ':t:r')

  " Build markdown link
  let link = '[' . filename . '](' . link_path . ')'

  " Insert at cursor position (append to current line)
  let current_line = line('.')
  let current_text = getline(current_line)

  " Append link to current line
  call setline(current_line, current_text . link)

  echo "Inserted: " . link
endfunction
