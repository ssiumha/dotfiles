" autoload/webdav/note.vim - Note creation and date calculation
" Functions for template-based note creation with date patterns

" Calculate date with offset based on unit (day, month, week)
" Parameters: unit (string), offset (integer)
" Returns: timestamp (seconds since epoch)
function! webdav#note#calculate_date(unit, offset)
  " No offset - return current time
  if a:offset == 0
    return localtime()
  endif

  " Build date command based on unit
  if a:unit == 'day'
    let unit_str = 'day'
    let unit_abbr = 'd'
  elseif a:unit == 'month'
    let unit_str = 'month'
    let unit_abbr = 'm'
  elseif a:unit == 'week'
    let unit_str = 'week'
    let unit_abbr = 'w'
  else
    echoerr "Unknown unit: " . a:unit
    return localtime()
  endif

  " Try BSD/macOS date first (date -v)
  let sign = a:offset > 0 ? '+' : ''
  let bsd_cmd = 'date -v ' . sign . a:offset . unit_abbr . ' +%s 2>/dev/null'
  let result = system(bsd_cmd)

  if v:shell_error == 0 && !empty(trim(result))
    return str2nr(trim(result))
  endif

  " Fallback to GNU date (date -d)
  let gnu_cmd = 'date -d "' . sign . a:offset . ' ' . unit_str . '" +%s 2>/dev/null'
  let result = system(gnu_cmd)

  if v:shell_error == 0 && !empty(trim(result))
    return str2nr(trim(result))
  endif

  " If both fail, fallback to simple day calculation
  if a:unit == 'day'
    return localtime() + (a:offset * 86400)
  endif

  " For month/week, just return current time if date command unavailable
  echoerr "Warning: date command not available, using current time"
  return localtime()
endfunction

" Open or create a note based on pattern
" Parameters: pattern_name (string), ... (variadic for offset)
" Usage: webdav#note#open('daily', -1)
function! webdav#note#open(pattern_name, ...)
  " Get pattern configuration
  if !exists('g:webdav_note_patterns')
    echoerr "Error: g:webdav_note_patterns not configured"
    return
  endif

  if !has_key(g:webdav_note_patterns, a:pattern_name)
    echoerr "Error: Pattern '" . a:pattern_name . "' not found"
    echo "Available patterns: " . join(sort(keys(g:webdav_note_patterns)), ', ')
    return
  endif

  let pattern = g:webdav_note_patterns[a:pattern_name]

  " Validate pattern has required fields
  if !has_key(pattern, 'server') || !has_key(pattern, 'path') || !has_key(pattern, 'template') || !has_key(pattern, 'unit')
    echoerr "Error: Pattern '" . a:pattern_name . "' is missing required fields (server, path, template, unit)"
    return
  endif

  " Get server info
  let server_info = webdav#server#get_info(pattern.server)
  if empty(server_info.url)
    echoerr "Error: Server '" . pattern.server . "' not found or not configured"
    return
  endif

  " Parse offset (default: 0)
  let offset = a:0 > 0 ? str2nr(a:1) : 0

  " Calculate date
  let timestamp = webdav#note#calculate_date(pattern.unit, offset)

  " Handle title prompt if pattern requires it
  let title = ''
  if has_key(pattern, 'prompt_title')
    " v:null = no prefix, empty string = default %y%m%d, otherwise custom format
    if pattern.prompt_title is v:null
      let date_prefix = ''
    elseif empty(pattern.prompt_title)
      let date_prefix = strftime('%y%m%d ', timestamp)
    else
      let date_prefix = strftime(pattern.prompt_title, timestamp)
    endif

    let user_input = input('Title: ', date_prefix)

    " Cancel if empty
    if empty(trim(user_input))
      echo "\nCancelled"
      return
    endif

    let title = trim(user_input)
  endif

  " Generate file path and template content using strftime
  let file_path = strftime(pattern.path, timestamp)
  let template_content = strftime(pattern.template, timestamp)

  " Replace {title} placeholder if title was provided
  if !empty(title)
    let file_path = substitute(file_path, '{title}', title, 'g')
    let template_content = substitute(template_content, '{title}', title, 'g')
  endif

  " Check if file exists
  let exists_status = webdav#http#file_exists(file_path, server_info)

  if exists_status == 1
    " File exists - open it
    echo "Opening existing note: " . file_path
    tabnew
    call webdav#file#get(file_path, pattern.server)
  elseif exists_status == 0
    " File doesn't exist - create it
    echo "Creating new note: " . file_path
    try
      " Write template content to temp file
      let temp_file = tempname()
      call writefile([template_content], temp_file, 'b')

      " Create file via PUT
      let cmd = webdav#http#build_request('PUT', file_path, server_info, temp_file, '', '')
      if empty(cmd)
        call delete(temp_file)
        return
      endif

      let result = webdav#http#execute(cmd)
      call delete(temp_file)

      if !result.success
        echoerr "Error creating note: HTTP request failed"
        echoerr result.response
        return
      endif
      let response = result.response

      " Parse response to check success
      let http_code = webdav#core#extract_http_code(response)

      if http_code >= 200 && http_code < 300
        echo "Created: " . file_path

        " Fetch version info
        let version_info = webdav#http#check_version(file_path, server_info)
        let etag = empty(version_info.error) ? version_info.etag : ''
        let last_modified = empty(version_info.error) ? version_info.last_modified : ''

        " Open new file in editor
        tabnew
        call webdav#buffer#setup(file_path, pattern.server, server_info, etag, last_modified, template_content)
      else
        echoerr "Error creating note: HTTP " . http_code
        echoerr response
      endif
    catch
      echoerr "Exception creating note: " . v:exception
    endtry
  else
    echoerr "Error: Could not check if file exists"
  endif
endfunction
