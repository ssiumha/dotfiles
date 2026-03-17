" autoload/webdav/ui.vim - Navigation and UI functions
" Functions for server selection, directory listing, and file/folder navigation

" Interactive server selection menu
" Parameters: optional server_name (variadic)
function! webdav#ui#main(...)
  " Scan for servers
  let servers = webdav#server#scan()

  " Check if any servers are configured
  if empty(servers)
    " Fallback to default environment variables if available
    if !empty($WEBDAV_DEFAULT_URL)
      echo "No WEBDAV_UI_* servers found. Using WEBDAV_DEFAULT_* variables."
      tabnew
      call webdav#ui#list('/', '')
      return
    else
      echoerr "Error: No WebDAV servers configured."
      echoerr "Set WEBDAV_UI_<NAME>=https://user:pass@host/path environment variables"
      return
    endif
  endif

  " Check if server name was provided as argument
  let server_name = a:0 > 0 ? trim(a:1) : ''

  if !empty(server_name)
    " Direct selection by name
    if has_key(servers, server_name)
      let server = servers[server_name]
      echo "Connected to '" . server_name . "' - " . server.url
      tabnew
      call webdav#ui#list('/', server_name)
      return
    else
      " Server not found - show available servers
      echoerr "Error: Server '" . server_name . "' not found."
      echo "Available servers: " . join(sort(keys(servers)), ', ')
      return
    endif
  endif

  " No argument - show interactive selection
  " Build selection list
  let choices = ["Select WebDAV Server:"]
  let server_list = []
  let idx = 1

  for name in sort(keys(servers))
    let server = servers[name]
    let display_url = server.url
    " Mask password in display
    let display_user = empty(server.user) ? '' : ' (' . server.user . '@...)'
    call add(choices, idx . '. ' . name . ': ' . display_url . display_user)
    call add(server_list, {'name': name, 'info': server})
    let idx += 1
  endfor

  " Show interactive selection
  let selection = inputlist(choices)

  " Validate selection
  if selection < 1 || selection > len(server_list)
    echo "\nCancelled or invalid selection."
    return
  endif

  " Set selected server as current
  let selected = server_list[selection - 1]

  " Automatically open root directory listing
  echo "\nConnected to '" . selected.name . "' - " . selected.info.url
  tabnew
  call webdav#ui#list('/', selected.name)
endfunction

" Display directory listing for WebDAV path
" Parameters: path (default '/'), server_name (default '')
function! webdav#ui#list(path = '/', server_name = '')
  " Determine server to use
  if !empty(a:server_name)
    " Use explicitly provided server
    let server_name = a:server_name
    let current_path = a:path
  elseif exists('b:webdav_managed') && b:webdav_managed
    " Use current buffer's directory and server
    if exists('b:webdav_original_path')
      " WebDAV file buffer - extract directory from file path
      let file_path = b:webdav_original_path
      let current_path = a:path == '/' ? substitute(file_path, '[^/]*$', '', '') : a:path
    elseif exists('b:webdav_current_path')
      " WebDAVList buffer - use current path directly
      let current_path = a:path == '/' ? b:webdav_current_path : a:path
    else
      let current_path = a:path
    endif
    let server_name = get(b:, 'webdav_server', '')
  else
    let current_path = a:path
    let server_name = ''
  endif

  let server_info = webdav#server#get_info(server_name)
  if empty(server_info)
    return
  endif
  let cmd = webdav#http#build_request('PROPFIND', current_path, server_info)

  setlocal buftype=nofile bufhidden=wipe
  setlocal modifiable

  " Clear buffer if it has content (for refresh)
  if line('$') > 1 || len(getline(1)) > 0
    silent! %delete _
  endif

  " Add header with full URL, action items, and parent directory
  call setline(1, '" WebDAV: ' . server_info.url . current_path)
  call append(1, '../')
  call append(2, '+New')
  call append(3, '+Folder')

  " Use systemlist() instead of $read to avoid E499 with URL-encoded paths
  let lines = systemlist(cmd)
  call append(line('$'), lines)

  " Remove empty lines and self-reference (.)
  execute 'silent! g/^\.\?$/d'
  " Path prefix removal is now handled in perl

  let b:webdav_current_path = current_path
  let b:webdav_server = server_name
  let b:webdav_managed = 1

  " Set filetype AFTER content is loaded
  setlocal filetype=webdavlist
  setlocal nomodifiable

  " Move cursor to top (first line)
  normal! gg
endfunction

" Check if line is a navigable item (not comment, empty, or action item)
function! s:is_navigable(line) abort
  return !empty(trim(a:line)) && a:line !~ '^"' && a:line != '+New' && a:line != '+Folder'
endfunction

" Handle opening files/folders from list buffer (Enter key handler)
function! webdav#ui#open()
  let line = getline('.')
  if !s:is_navigable(line)
    if line == '+New'
      call webdav#operations#create_file(b:webdav_current_path)
    elseif line == '+Folder'
      call webdav#operations#create_folder(b:webdav_current_path)
    endif
    return
  endif

  let current_server = get(b:, 'webdav_server', '')

  if line == '../'
    call webdav#ui#list(webdav#core#parent_path(b:webdav_current_path), current_server)
    return
  endif

  let path = webdav#core#join_path(b:webdav_current_path, line)

  if line =~ '/$'
    call webdav#ui#list(path, current_server)
  else
    call WebDAVGet(path, current_server)
  endif
endfunction

" Open in new tab (t key handler)
function! webdav#ui#open_in_tab()
  let line = getline('.')
  if !s:is_navigable(line)
    if line == '+New'
      call webdav#operations#create_file(b:webdav_current_path)
    elseif line == '+Folder'
      call webdav#operations#create_folder(b:webdav_current_path)
    endif
    return
  endif

  let current_server = get(b:, 'webdav_server', '')

  if line == '../'
    tabnew
    call webdav#ui#list(webdav#core#parent_path(b:webdav_current_path), current_server)
    return
  endif

  let path = webdav#core#join_path(b:webdav_current_path, line)

  tabnew
  if line =~ '/$'
    call webdav#ui#list(path, current_server)
  else
    call WebDAVGet(path, current_server)
  endif
endfunction

" Go to parent directory (- key handler)
function! webdav#ui#go_up()
  let current_server = get(b:, 'webdav_server', '')
  let vault_root = webdav#wikilink#get_vault_root(current_server)
  if !empty(vault_root) && b:webdav_current_path == vault_root
    echo "Already at vault root: " . vault_root
    return
  endif
  call webdav#ui#list(webdav#core#parent_path(b:webdav_current_path), current_server)
endfunction

" FZF-based server selection menu (alternative to webdav#ui#main)
function! webdav#ui#main_fzf()
  " Scan for servers
  let servers = webdav#server#scan()

  " Check if any servers are configured
  if empty(servers)
    " Fallback to default environment variables if available
    if !empty($WEBDAV_DEFAULT_URL)
      echo "No WEBDAV_UI_* servers found. Using WEBDAV_DEFAULT_* variables."
      tabnew
      call webdav#ui#list('/', '')
      return
    else
      echoerr "Error: No WebDAV servers configured."
      echoerr "Set WEBDAV_UI_<NAME>=https://user:pass@host/path environment variables"
      return
    endif
  endif

  " Check if fzf is available
  if !executable('fzf')
    echoerr "Error: fzf is not installed"
    return
  endif

  " Build server list for fzf
  let server_list = []
  for name in sort(keys(servers))
    let server = servers[name]
    let display_url = server.url
    " Mask password in display
    let display_user = empty(server.user) ? '' : ' (' . server.user . '@...)'
    call add(server_list, name . ': ' . display_url . display_user)
  endfor

  " Launch fzf for server selection
  call fzf#run(fzf#wrap({
    \ 'source': server_list,
    \ 'sink': function('s:webdavuifzf_sink', [servers]),
    \ 'options': ['--prompt', 'WebDAV Server> ', '--header', 'Select server to browse'],
    \ 'down': '40%'
  \ }))
endfunction

" Handle fzf server selection (script-local helper for main_fzf)
function! s:webdavuifzf_sink(servers, selection)
  if empty(a:selection)
    return
  endif

  " Parse server name from selection (format: "name: url (user@...)")
  let server_name = matchstr(a:selection, '^\zs[^:]\+\ze:')

  if empty(server_name) || !has_key(a:servers, server_name)
    echoerr "Error: Failed to parse server name from selection"
    return
  endif

  let server_info = a:servers[server_name]
  echo "Connected to '" . server_name . "' - " . server_info.url
  tabnew
  call webdav#ui#list('/', server_name)
endfunction
