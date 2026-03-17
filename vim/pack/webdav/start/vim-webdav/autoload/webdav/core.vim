" autoload/webdav/core.vim - Core utility functions
" Helper functions used throughout the plugin

" Helper function to clean string (remove all newlines and trim whitespace)
function! webdav#core#clean_string(str)
  " Remove all newlines/carriage returns, then trim leading/trailing whitespace
  return trim(substitute(a:str, '[\r\n]', '', 'g'))
endfunction

" Helper function for debug logging
" Usage: call webdav#core#debug_log("message")
" Enable with: :let g:webdav_debug = 1
function! webdav#core#debug_log(msg)
  if get(g:, 'webdav_debug', 0)
    echom a:msg
  endif
endfunction

" Helper function to URL encode a string (but keep slashes)
function! webdav#core#url_encode(str)
  " CRITICAL: Clean input BEFORE encoding (remove newlines, otherwise they become %0A)
  let clean_str = webdav#core#clean_string(a:str)

  " URL encode using perl - pass string as argument to avoid shell pipe issues
  " This avoids problems with echo -n where '-n' itself can get encoded
  let encoded = system("perl -MURI::Escape -e 'print uri_escape($ARGV[0], q{^A-Za-z0-9/._~-})' " . shellescape(clean_str))

  " Also clean system() output for defense-in-depth
  return webdav#core#clean_string(encoded)
endfunction

" Helper function to safely join paths with proper slash handling
" Ensures base_path ends with / and relative_item doesn't start with /
" Example: webdav#core#join_path('/test', 'folder/') -> '/test/folder/'
" Example: webdav#core#join_path('/test/', 'file.txt') -> '/test/file.txt'
function! webdav#core#join_path(base_path, relative_item)
  " Ensure base_path ends with /
  let safe_base = a:base_path
  if safe_base !~ '/$'
    let safe_base .= '/'
  endif

  " Ensure relative_item doesn't start with / (to avoid double slashes)
  let safe_item = a:relative_item
  if safe_item =~ '^/'
    let safe_item = substitute(safe_item, '^/', '', '')
  endif

  return safe_base . safe_item
endfunction

" Compute parent directory path
" Example: '/test/folder/' -> '/test/', '/test/file.txt' -> '/test/'
function! webdav#core#parent_path(path)
  let clean = substitute(a:path, '/$', '', '')
  if clean !~ '/'
    return '/'
  endif
  let parent = substitute(clean, '/[^/]*$', '/', '')
  if parent !~ '/$'
    let parent .= '/'
  endif
  return parent
endfunction

" Helper function to extract HTTP status code from response
" Returns integer HTTP code (e.g., 200, 404, 500)
function! webdav#core#extract_http_code(response)
  let status_line = matchstr(a:response, '^HTTP/[^ ]* \zs\d\+')
  return str2nr(status_line)
endfunction
