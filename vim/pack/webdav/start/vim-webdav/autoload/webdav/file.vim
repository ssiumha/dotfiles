" autoload/webdav/file.vim - File operations (GET/PUT)
" Functions for retrieving and saving WebDAV files

" Retrieve file from WebDAV server
" Parameters: path (string), server_name (string, optional)
function! webdav#file#get(path, server_name = '')
  " Determine server to use
  if !empty(a:server_name)
    " Use explicitly provided server
    let server_name = a:server_name
  elseif exists('b:webdav_managed') && b:webdav_managed
    " Use current buffer's server info
    let server_name = get(b:, 'webdav_server', '')
  else
    let server_name = ''
  endif

  " Use curl for WebDAV GET (with headers)
  let server_info = webdav#server#get_info(server_name)
  if empty(server_info)
    return
  endif
  let cmd = webdav#http#build_request('GET', a:path, server_info)

  " DEBUG: Show the actual curl command
  call webdav#core#debug_log("DEBUG: curl command = " . cmd)

  " Get response with headers (no need to escape % for system() call)
  let result = webdav#http#execute(cmd)
  if !result.success
    echoerr "Error: HTTP request failed"
    echoerr result.response
    return
  endif
  let response = result.response

  " Parse HTTP response
  let parsed = webdav#http#parse_response(response)
  let headers = parsed.headers
  let body = parsed.body

  " Extract HTTP status code
  let http_code = webdav#core#extract_http_code(response)

  " Handle 404 - file doesn't exist yet, create empty buffer
  if http_code == 404
    call webdav#buffer#setup(a:path, server_name, server_info, '', '', '')
    call webdav#recent#track(a:path, server_info.url, server_name)
    return
  endif

  " DEBUG: Show headers received (headers is a string, not a list)
  let header_lines = split(headers, '\r\?\n')
  call webdav#core#debug_log("DEBUG: Headers count = " . len(header_lines))
  for header in header_lines
    call webdav#core#debug_log("DEBUG: Header - " . header)
  endfor

  " Extract version information from headers
  let etag = webdav#http#extract_header(headers, 'ETag')
  let last_modified = webdav#http#extract_header(headers, 'Last-Modified')

  " DEBUG: Show extracted values
  call webdav#core#debug_log("DEBUG: ETag = " . etag)
  call webdav#core#debug_log("DEBUG: Last-Modified = " . last_modified)
  call webdav#core#debug_log("DEBUG: Body length = " . len(body))

  " SAFETY CHECK: Require at least one version tracking mechanism
  " Exception: Allow empty files without version tracking
  if empty(etag) && empty(last_modified)
    if !empty(body)
      echoerr "Error: Server does not provide ETag or Last-Modified headers"
      echoerr "Cannot safely edit file without conflict detection"
      echoerr "Response headers received:"
      for header in header_lines
        echoerr "  " . header
      endfor
      return
    endif
    " Empty file - proceed without version tracking (safe since no data to lose)
  endif

  " Setup buffer with content and metadata
  call webdav#buffer#setup(a:path, server_name, server_info, etag, last_modified, body)

  " Track this file in recent files list
  call webdav#recent#track(a:path, server_info.url, server_name)
endfunction

" Save WebDAV buffer with conflict detection
function! webdav#file#put()
  " Validate buffer is ready for save
  if !webdav#buffer#validate()
    return
  endif

  try
    " Get server info from buffer (using server name if available)
    let server_name = get(b:, 'webdav_server', '')
    let server_info = webdav#server#get_info(server_name)

    " Use base_url if set (for external path files opened via wikilink)
    if exists('b:webdav_base_url')
      let server_info = copy(server_info)
      let server_info.url = b:webdav_base_url
    endif

    " Get our stored version info
    let our_etag = exists('b:webdav_etag') ? b:webdav_etag : ''
    let our_last_modified = exists('b:webdav_last_modified') ? b:webdav_last_modified : ''

    " Always check server version before PUT (for both conflict detection and new file creation)
    echo "Checking server version..."
    let server_version = webdav#http#check_version(b:webdav_original_path, server_info)

    " Handle case where we have no version info (new file from 404)
    if empty(our_etag) && empty(our_last_modified)
      " Check if file exists on server now
      if !empty(server_version.error)
        if server_version.error =~ 'HTTP 404'
          " File still doesn't exist - this is a new file creation
          echo "Creating new file on server..."
        else
          " Server check failed for other reason
          echohl WarningMsg
          echo "Warning: Cannot check server version: " . server_version.error
          echo "Cannot detect if file exists or conflicts"
          echohl None
          let proceed = input('Proceed with save anyway? (y/N): ')
          if tolower(proceed) != 'y'
            echo "\nSave cancelled"
            return
          endif
        endif
      else
        " File exists on server but we have no version tracking
        echohl WarningMsg
        echo "Warning: File exists on server but no version tracking"
        echo "Cannot detect conflicts - save may overwrite other changes"
        echohl None
        let proceed = input('Proceed with save anyway? (y/N): ')
        if tolower(proceed) != 'y'
          echo "\nSave cancelled"
          return
        endif
      endif
    endif

    " Check for conflicts if we have version info
    if !empty(our_etag) || !empty(our_last_modified)
      if !empty(server_version.error)
        echoerr "Warning: Could not check server version: " . server_version.error
        let proceed = input('Proceed with save anyway? (y/N): ')
        if tolower(proceed) != 'y'
          echo "\nSave cancelled"
          return
        endif
      else
        " Compare versions (prefer ETag if both sides have it, otherwise use Last-Modified)
        let conflict_detected = 0

        if !empty(our_etag) && !empty(server_version.etag)
          " Compare ETags
          if our_etag != server_version.etag
            let conflict_detected = 1
          endif
        elseif !empty(our_last_modified) && !empty(server_version.last_modified)
          " Compare Last-Modified timestamps
          if our_last_modified != server_version.last_modified
            let conflict_detected = 1
          endif
        endif

        if conflict_detected
          echohl WarningMsg
          echo "Conflict: Server file has been modified by another client"
          echohl None
          echo "Your version: " . (empty(our_etag) ? our_last_modified : our_etag)
          echo "Server version: " . (empty(server_version.etag) ? server_version.last_modified : server_version.etag)
          echo ""
          echo "Options:"
          echo "  d - Show diff and merge (recommended)"
          echo "  o - Overwrite server version with your changes (your changes win)"
          echo "  c - Cancel save and open server version for manual merge"
          echo "  any other key - Cancel save"
          let choice = nr2char(getchar())
          echo "\n"

          if choice == 'd' || choice == 'D'
            echo "Opening diff for merge..."
            call webdav#conflict#diff()
            return
          elseif choice == 'o' || choice == 'O'
            echo "Overwriting server version..."
          elseif choice == 'c' || choice == 'C'
            echo "Opening server version for manual merge..."
            call webdav#conflict#resolve()
            return
          else
            echo "Save cancelled"
            return
          endif
        endif
      endif
    endif

    " Write buffer content to temp file
    let temp_file = tempname()
    call writefile(getline(1, '$'), temp_file, 'b')

    " Make PUT request (without conditional headers since nginx ignores them)
    " We've already done manual conflict detection above
    let cmd = webdav#http#build_request('PUT', b:webdav_original_path, server_info, temp_file, '', '')
    if empty(cmd)
      return
    endif

    " Execute PUT request
    let result = webdav#http#execute(cmd)
    if !result.success
      echoerr "Error: HTTP request failed"
      echoerr result.response
      return
    endif
    let response = result.response

    " Parse HTTP status line and headers
    let http_code = webdav#core#extract_http_code(response)

    " Handle response
    if http_code >= 200 && http_code < 300
      " Success: Fetch fresh version info after save
      " This is necessary because nginx may not return updated ETag/Last-Modified in PUT responses
      let fresh_version = webdav#http#check_version(b:webdav_original_path, server_info)
      if empty(fresh_version.error)
        let b:webdav_etag = fresh_version.etag
        let b:webdav_last_modified = fresh_version.last_modified
      else
        " Fallback to extracting from PUT response if GET fails
        call webdav#buffer#update_version(response)
      endif

      setlocal nomodified
      echo "Saved to WebDAV: " . b:webdav_original_path

      " Invalidate cache for this file's directory
      call webdav#cache#invalidate(server_name, server_info, b:webdav_original_path)
    elseif http_code == 412
      " Conflict: Server file was modified
      echoerr "Conflict: Server file has been modified"
      echo "Opening latest version in new tab..."
      call webdav#conflict#resolve()
    elseif http_code >= 400 && http_code < 500
      echoerr "Error saving to WebDAV: HTTP " . http_code . " (Client Error)"
    elseif http_code >= 500
      echoerr "Error saving to WebDAV: HTTP " . http_code . " (Server Error)"
    else
      echoerr "Error saving to WebDAV: HTTP " . http_code
    endif
  catch
    echoerr "Exception saving to WebDAV: " . v:exception
  finally
    " Cleanup temp file
    if exists('temp_file') && filereadable(temp_file)
      call delete(temp_file)
    endif
  endtry
endfunction

" Retrieve file using absolute base URL (for wikilink external paths)
" Parameters: base_url (string), path (string), server_name (string)
function! webdav#file#get_absolute(base_url, path, server_name)
  " Get server info for auth credentials
  let server_info = webdav#server#get_info(a:server_name)
  if empty(server_info)
    return
  endif

  " Build curl command with base_url
  let auth = empty(server_info.user) ? '' : '--user ' . shellescape(server_info.user . ':' . server_info.pass)
  let encoded_path = webdav#core#url_encode(a:path)
  let url = a:base_url . encoded_path

  call webdav#core#debug_log("DEBUG REQUEST (absolute): base_url=" . string(a:base_url))
  call webdav#core#debug_log("DEBUG REQUEST (absolute): path=" . string(a:path))
  call webdav#core#debug_log("DEBUG REQUEST (absolute): final url=" . string(url))

  let cmd = 'curl -i -s ' . auth . ' ' . shellescape(url)
  call webdav#core#debug_log("DEBUG: curl command = " . cmd)

  " Execute request
  let result = webdav#http#execute(cmd)
  if !result.success
    echoerr "Error: HTTP request failed"
    echoerr result.response
    return
  endif
  let response = result.response

  " Parse HTTP response
  let parsed = webdav#http#parse_response(response)
  let headers = parsed.headers
  let body = parsed.body

  " Extract HTTP status code
  let http_code = webdav#core#extract_http_code(response)

  " Handle 404 - file doesn't exist yet
  if http_code == 404
    call webdav#buffer#setup(a:path, a:server_name, server_info, '', '', '')
    let b:webdav_base_url = a:base_url
    call webdav#recent#track(a:path, a:base_url, a:server_name)
    return
  endif

  " Extract version information
  let etag = webdav#http#extract_header(headers, 'ETag')
  let last_modified = webdav#http#extract_header(headers, 'Last-Modified')

  " Safety check
  if empty(etag) && empty(last_modified) && !empty(body)
    echoerr "Error: Server does not provide ETag or Last-Modified headers"
    return
  endif

  " Setup buffer with original server_info (for URL validation)
  " Store base_url separately for PUT requests
  call webdav#buffer#setup(a:path, a:server_name, server_info, etag, last_modified, body)
  let b:webdav_base_url = a:base_url
  call webdav#recent#track(a:path, a:base_url, a:server_name)
endfunction
