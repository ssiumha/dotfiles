" autoload/webdav/conflict.vim - Conflict resolution functions
" Functions for detecting and resolving version conflicts

" Open server version in new tab for manual merge
function! webdav#conflict#resolve()
  if !exists('b:webdav_original_path')
    echoerr "Error: WebDAV path not found"
    return
  endif

  let original_path = b:webdav_original_path

  " Open server version in new tab
  tabnew
  call WebDAVGet(original_path, '')

  echo "Conflict resolution: Left tab (previous) = your local changes, Right tab (current) = server version"
  echo "Manually merge changes and save again"
endfunction

" Compare current buffer with server version using vimdiff
function! webdav#conflict#diff()
  " Validation
  if !webdav#buffer#validate()
    return
  endif

  " Step 1: Backup local changes
  let local_lines = getline(1, '$')
  let local_modified = &modified

  " Step 2: Get server info
  let server_name = get(b:, 'webdav_server', '')
  let server_info = webdav#server#get_info(server_name)
  let original_path = b:webdav_original_path

  " Step 3: Fetch latest version from server
  echo "Fetching server version..."
  let cmd = webdav#http#build_request('GET', original_path, server_info)
  if empty(cmd)
    return
  endif

  let result = webdav#http#execute(cmd)
  if !result.success
    echoerr "Error: Failed to fetch server version"
    echoerr result.response
    return
  endif
  let response = result.response

  " Step 4: Parse response
  let http_code = webdav#core#extract_http_code(response)

  if http_code < 200 || http_code >= 300
    echoerr "Error: HTTP " . http_code
    return
  endif

  let parsed = webdav#http#parse_response(response)
  let server_body = parsed.body
  let server_etag = webdav#http#extract_header(parsed.headers, 'ETag')
  let server_last_modified = webdav#http#extract_header(parsed.headers, 'Last-Modified')

  " Step 5: Save local changes to temp file with timestamp
  let timestamp = strftime('%Y%m%d-%H%M%S')
  let basename = fnamemodify(original_path, ':t')
  let extension = fnamemodify(original_path, ':e')
  let temp_file = tempname() . '-' . basename

  call writefile(local_lines, temp_file)

  " Step 6: Replace current buffer with server version
  setlocal modifiable
  %delete _
  call setline(1, split(server_body, '\n', 1))

  " Step 7: Update metadata to server's latest
  let b:webdav_etag = server_etag
  let b:webdav_last_modified = server_last_modified
  setlocal nomodified

  " Step 8: Store temp file path for cleanup
  let b:webdav_diff_temp = temp_file

  " Step 9: Set up autocmd for cleanup on save
  augroup webdav_diff_cleanup
    autocmd! BufWritePost <buffer>
    autocmd BufWritePost <buffer> call s:cleanup()
  augroup END

  " Step 10: Open diff (responsive layout based on terminal width)
  if &columns <= 120
    execute 'diffsplit ' . fnameescape(temp_file)
  else
    execute 'vertical diffsplit ' . fnameescape(temp_file)
  endif

  " Step 11: Configure right (temp) buffer
  setlocal readonly nomodifiable bufhidden=wipe
  execute 'file [Local\ Changes] ' . fnameescape(original_path)

  " Step 12: Focus on left (server) buffer
  wincmd h

  " Step 13: User guidance
  echohl MoreMsg
  echo "Diff ready: Left=Server (editable), Right=Your changes (readonly)"
  echohl None

  if local_modified
    echo "Merge changes and :w to save. Temp file will be auto-deleted on save."
  else
    echo "No local changes detected."
  endif
endfunction

" Cleanup temp diff file after successful save (script-local helper)
function! s:cleanup()
  if exists('b:webdav_diff_temp') && filereadable(b:webdav_diff_temp)
    call delete(b:webdav_diff_temp)
    unlet b:webdav_diff_temp

    " Remove autocmd
    autocmd! webdav_diff_cleanup BufWritePost <buffer>

    echo "Saved. Diff temp file cleaned up."
  endif
endfunction
