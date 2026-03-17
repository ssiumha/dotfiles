" autoload/webdav/operations.vim - File and folder operations
" Functions for creating, renaming, and deleting files and folders

" Create new markdown file in specified directory
" Parameters: current_path (string)
function! webdav#operations#create_file(current_path)
  " Get server info from current buffer
  let server_name = webdav#server#get_buffer_info()
  if server_name is v:null
    return
  endif

  " Prompt for file name
  let filename = input('New file name (without extension): ')
  if empty(trim(filename))
    echo "\nCancelled"
    return
  endif

  " Add .md extension automatically
  let filename = trim(filename) . '.md'

  " Build full path
  let file_path = webdav#core#join_path(a:current_path, filename)

  " Create initial content with title
  let title = substitute(filename, '\.md$', '', '')
  let initial_content = '# ' . title

  try
    " Write initial content to temp file
    let temp_file = tempname()
    call writefile([initial_content], temp_file, 'b')

    " Create file on server via PUT (no ETag for new file)
    let server_info = webdav#server#get_info(server_name)
    let cmd = webdav#http#build_request('PUT', file_path, server_info, temp_file, '', '')
    if empty(cmd)
      call delete(temp_file)
      return
    endif

    let result = webdav#http#execute(cmd)
    call delete(temp_file)

    if !result.success
      echoerr "Error creating file: HTTP request failed"
      echoerr result.response
      return
    endif
    let response = result.response

    " Parse response to check success
    let http_code = webdav#core#extract_http_code(response)

    if http_code >= 200 && http_code < 300
      echo "\nCreated: " . filename

      " Fetch version info from server (nginx may not return ETag/Last-Modified in PUT response)
      let version_info = webdav#http#check_version(file_path, server_info)
      let etag = empty(version_info.error) ? version_info.etag : ''
      let last_modified = empty(version_info.error) ? version_info.last_modified : ''

      " Fallback to extracting from PUT response if GET fails
      if empty(etag) && empty(last_modified)
        let parsed = webdav#http#parse_response(response)
        let etag = webdav#http#extract_header(parsed.headers, 'ETag')
        let last_modified = webdav#http#extract_header(parsed.headers, 'Last-Modified')
      endif

      " Open new file in editor
      tabnew
      call webdav#buffer#setup(file_path, server_name, server_info, etag, last_modified, initial_content)
    else
      echoerr "Error creating file: HTTP " . http_code
      echoerr response
    endif
  catch
    echoerr "Exception creating file: " . v:exception
  endtry
endfunction

" Create new folder in current directory
" Parameters: current_path (string)
function! webdav#operations#create_folder(current_path)
  " Get server info from current buffer
  let server_name = webdav#server#get_buffer_info()
  if server_name is v:null
    return
  endif

  " Prompt for folder name
  let foldername = input('New folder name: ')
  if empty(trim(foldername))
    echo "\nCancelled"
    return
  endif

  " Ensure folder name ends with /
  let foldername = trim(foldername)
  if foldername !~ '/$'
    let foldername .= '/'
  endif

  " Build full path
  let folder_path = webdav#core#join_path(a:current_path, foldername)

  " Create folder via MKCOL
  let server_info = webdav#server#get_info(server_name)
  let cmd = webdav#http#build_request('MKCOL', folder_path, server_info)
  if empty(cmd)
    return
  endif

  let result = webdav#http#execute(cmd)

  if !result.success
    echoerr "Error creating folder: HTTP request failed"
    echoerr result.response
    return
  endif
  let response = result.response

  " Parse response to check success
  let http_code = webdav#core#extract_http_code(response)

  if http_code >= 200 && http_code < 300
    echo "\nCreated folder: " . foldername
    " Refresh current list
    call webdav#ui#list(a:current_path)
  else
    echoerr "Error creating folder: HTTP " . http_code
    echoerr response
  endif
endfunction

" Rename (move) file or folder in current directory
function! webdav#operations#rename()
  " Get server info from current buffer
  let server_name = webdav#server#get_buffer_info()
  if server_name is v:null
    return
  endif

  " Get current line item
  let line = getline('.')
  if empty(trim(line)) || line =~ '^"'
    echo "Cannot rename special items"
    return
  endif

  " Skip special action items
  if line == '+New' || line == '+Folder' || line == '../'
    echo "Cannot rename special items"
    return
  endif

  " Determine if it's a folder (ends with /)
  let is_folder = (line =~ '/$')
  let current_name = line

  " Build source path
  let source_path = webdav#core#join_path(b:webdav_current_path, current_name)

  " Prompt for new name with current name as default
  let prompt = is_folder ? 'Rename folder to: ' : 'Rename file to: '
  let new_name = input(prompt, current_name)
  if empty(trim(new_name)) || trim(new_name) == current_name
    echo "\nCancelled"
    return
  endif

  let new_name = trim(new_name)

  " Ensure folder name ends with /
  if is_folder && new_name !~ '/$'
    let new_name .= '/'
  endif

  " Build destination path
  " Support moving to different directories (e.g., "nested/file.txt" or "/other/path/file.txt")
  if new_name =~ '^/'
    " Absolute path
    let dest_path = new_name
  else
    " Relative path (could include subdirectories)
    let dest_path = webdav#core#join_path(b:webdav_current_path, new_name)
  endif

  " Check if destination already exists
  let server_info = webdav#server#get_info(server_name)
  let check_cmd = webdav#http#build_request('PROPFIND', dest_path, server_info)
  if !empty(check_cmd)
    " Modify PROPFIND to only check if resource exists (Depth: 0)
    let check_cmd = substitute(check_cmd, '-H "Depth: 1"', '-H "Depth: 0"', '')
    let check_result = webdav#http#execute(check_cmd)

    if check_result.success
      " Parse HTTP status
      let http_code = webdav#core#extract_http_code(check_result.response)

      if http_code == 207 || (http_code >= 200 && http_code < 300)
        " Destination exists - ask for confirmation
        echohl WarningMsg
        echo "\nDestination already exists: " . new_name
        echohl None
        let choice = confirm('Overwrite?', "&Yes\n&No", 2)
        if choice != 1
          echo "\nCancelled"
          return
        endif
      endif
    endif
  endif

  " Execute MOVE request
  let cmd = webdav#http#build_request('MOVE', source_path, server_info, dest_path)
  if empty(cmd)
    return
  endif

  let result = webdav#http#execute(cmd)

  if !result.success
    echoerr "Error renaming: HTTP request failed"
    echoerr result.response
    return
  endif
  let response = result.response

  " Parse response status
  let http_code = webdav#core#extract_http_code(response)

  if http_code >= 200 && http_code < 300
    echo "\nRenamed: " . current_name . " -> " . new_name
    " Refresh current list
    call webdav#ui#list(b:webdav_current_path)
  elseif http_code == 409
    echoerr "Error: Parent collection does not exist or conflict occurred"
    echoerr response
  elseif http_code == 412
    echoerr "Error: Precondition failed (destination may already exist)"
    echoerr response
  else
    echoerr "Error renaming: HTTP " . http_code
    echoerr response
  endif
endfunction

" Delete file or empty folder
function! webdav#operations#delete()
  " SAFETY: Only work in webdavlist buffers
  if &filetype != 'webdavlist'
    return
  endif

  " Get server info from current buffer
  let server_name = webdav#server#get_buffer_info()
  if server_name is v:null
    return
  endif

  " Get current line item
  let line = getline('.')
  if empty(trim(line)) || line =~ '^"'
    echo "Cannot delete special items"
    return
  endif

  " SAFETY: Block deletion of special items
  if line == '+New' || line == '+Folder' || line == '../'
    echo "Cannot delete special items"
    return
  endif

  " Determine if it's a folder (ends with /)
  let is_folder = (line =~ '/$')
  let item_name = line

  " Build path
  let path = webdav#core#join_path(b:webdav_current_path, item_name)

  " SAFETY: For folders, check if empty
  if is_folder
    echo "Checking if folder is empty..."
    let empty_status = webdav#http#folder_empty(path, server_name)

    if empty_status == -1
      echoerr "Error: Could not verify folder status"
      return
    endif

    if empty_status == 0
      echoerr "Error: Folder is not empty. Delete contents first."
      return
    endif
  endif

  " Confirmation prompt (skip in test mode)
  if !exists('$WEBDAV_TEST_MODE') || $WEBDAV_TEST_MODE != '1'
    let choice = confirm('Delete "' . item_name . '"?', "&Yes\n&No", 2)
    if choice != 1
      echo "Cancelled"
      return
    endif
  endif

  " Execute DELETE request
  let server_info = webdav#server#get_info(server_name)
  let cmd = webdav#http#build_request('DELETE', path, server_info)
  if empty(cmd)
    return
  endif

  let result = webdav#http#execute(cmd)

  if !result.success
    echoerr "Error deleting: HTTP request failed"
    echoerr result.response
    return
  endif
  let response = result.response

  " Parse response status
  let http_code = webdav#core#extract_http_code(response)

  if http_code >= 200 && http_code < 300
    echo "\nDeleted: " . item_name

    " Invalidate cache for this file's directory
    call webdav#cache#invalidate(server_name, server_info, path)

    " Refresh current list
    call webdav#ui#list(b:webdav_current_path)
  elseif http_code == 404
    echoerr "Error: Item not found"
  elseif http_code == 409
    echoerr "Error: Folder is not empty or has dependencies"
    echoerr response
  else
    echoerr "Error deleting: HTTP " . http_code
    echoerr response
  endif
endfunction
