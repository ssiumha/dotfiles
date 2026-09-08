" autoload/webdavsearch/api.vim - client for the vault search index
" Speaks the contract in doc/vault-search-api.openapi.yaml and nothing else.
" The base URL never lives in this repository; it comes from g:webdav_search_url
" or $WEBDAV_SEARCH_URL.

function! webdavsearch#api#enabled() abort
  return !empty(get(g:, 'webdav_search_url', ''))
endfunction

" Build a curl command for one endpoint.
" Values go through --data-urlencode so curl does the percent-encoding; the
" vault holds Korean filenames and hand-rolled encoding in vimscript gets the
" UTF-8 wrong. A list value repeats the parameter, which is what the spec's
" repeatable parameters expect.
function! webdavsearch#api#curl_cmd(endpoint, params) abort
  let cmd = 'curl -s --max-time 10 -G ' . shellescape(g:webdav_search_url . a:endpoint)
  for [key, value] in items(a:params)
    if type(value) == v:t_list
      for item in value
        let cmd .= ' --data-urlencode ' . shellescape(key . '=' . item)
      endfor
    else
      let cmd .= ' --data-urlencode ' . shellescape(key . '=' . value)
    endif
  endfor
  return cmd
endfunction

" One request, decoded. Returns {} on any failure so callers can bail quietly
" rather than each repeating the same error handling.
function! webdavsearch#api#get(endpoint, params) abort
  let response = system(webdavsearch#api#curl_cmd(a:endpoint, a:params))

  if v:shell_error != 0 || empty(trim(response))
    echohl WarningMsg
    echo 'Search index unreachable'
    echohl None
    return {}
  endif

  try
    let data = json_decode(response)
  catch
    echohl WarningMsg
    echo 'Search index returned malformed JSON'
    echohl None
    return {}
  endtry

  if type(data) != v:t_dict
    return {}
  endif

  if has_key(data, 'error')
    echohl WarningMsg
    echo 'Search index: ' . get(data, 'detail', data.error)
    echohl None
    return {}
  endif

  return data
endfunction

" What the answering index was built from, for a picker header or a message.
" Shown as the raw stamp rather than an age: indexed_at is UTC and turning it
" into "3m ago" without the offset would report the wrong number.
function! webdavsearch#api#staleness(index) abort
  let stamp = get(a:index, 'indexed_at', '')
  return empty(stamp) ? 'index unknown' : 'indexed ' . stamp
endfunction

" Open a vault-relative path. Reading is the WebDAV plugin's job, so this goes
" through its public wrapper instead of touching its internals.
function! webdavsearch#api#open(path, ...) abort
  let lnum = a:0 > 0 ? a:1 : 0
  tabnew
  call WebDAVGet('/' . a:path, g:webdav_search_server)
  if lnum > 0
    execute 'normal! ' . lnum . 'G'
  endif
endfunction

" Vault-relative prefix of a server's root, '' when it is the vault root.
" Returns v:null for an unknown server, or one outside the vault, so a caller
" can tell "no scope" from "cannot scope".
function! webdavsearch#api#server_prefix(server) abort
  let root = webdav#server#get_info(g:webdav_search_server)
  if empty(root) || empty(get(root, 'url', ''))
    return v:null
  endif

  " An empty name means the buffer was opened on the default server, which is
  " the vault root in every configuration this plugin works in
  if empty(a:server)
    return ''
  endif

  " scan() rather than get_info(), which errors out loud on an unknown name
  let servers = webdav#server#scan()
  if !has_key(servers, a:server)
    return v:null
  endif

  let url = servers[a:server].url
  if url ==# root.url
    return ''
  endif
  if stridx(url, root.url) != 0
    return v:null
  endif
  return url[len(root.url) :]
endfunction

" Scope for a buffer, for :WebDAVSearch.
" ctx.dir is relative to the server that buffer was opened on, so a note opened
" through a server rooted part-way down the vault reports '/' while the vault
" calls it that server's own prefix. The server prefix is what closes that gap;
" without it the search silently widens.
function! webdavsearch#api#scope(ctx) abort
  let prefix = webdavsearch#api#server_prefix(get(a:ctx, 'server', ''))
  if prefix is v:null
    return ''
  endif
  return substitute(prefix . get(a:ctx, 'dir', '/'), '^/', '', '')
endfunction

" Scope covering a whole server's subtree, for :WebDAVSearchIn. Lets a picker
" opened outside any WebDAV buffer still say where to look.
function! webdavsearch#api#server_scope(server) abort
  let prefix = webdavsearch#api#server_prefix(a:server)
  if prefix is v:null
    return v:null
  endif
  return substitute(prefix . '/', '^/', '', '')
endfunction

" Buffer name the WebDAV plugin gives a note, so quickfix entries jump through
" its BufReadCmd instead of looking for a local file that is not there.
function! webdavsearch#api#buffer_name(path) abort
  let info = webdav#server#get_info(g:webdav_search_server)
  if empty(info) || empty(get(info, 'url', ''))
    return ''
  endif
  return 'webdav://' . info.url . '/' . a:path
endfunction
