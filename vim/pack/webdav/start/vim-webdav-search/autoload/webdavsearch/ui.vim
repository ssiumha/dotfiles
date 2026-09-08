" autoload/webdavsearch/ui.vim - pickers and quickfix over the search index

" Search parameters shared by every content query.
" scope is a vault-relative prefix, '' for the whole vault. keep is a tag the
" caller asked for explicitly, which then outranks the standing exclusions —
" picking a tag that is excluded by default should still show its notes.
function! s:params(scope, keep) abort
  let params = {'limit': g:webdav_search_limit}

  if !empty(a:scope)
    let params.path = [a:scope]
  endif

  let excluded = filter(copy(g:webdav_search_exclude_tags), 'v:val !=# a:keep')
  if !empty(excluded)
    let params.exclude_tag = excluded
  endif

  return params
endfunction

function! s:scope_label(scope) abort
  return empty(a:scope) ? 'all' : a:scope
endfunction

" The picker opens on titles because that is how you look for a note you know
" exists; content is a keystroke away for when you only remember a phrase.
let s:modes = {'title': 'content', 'content': 'title'}

" Turn one NDJSON object per line into
" "display\tpath\tline\tmatched_in\ttext". fzf shows field 1 and the sink reads
" the rest, so a path holding a colon still parses, and building a wikilink has
" the kind of match and its text to work from.
function! s:hit_formatter() abort
  return 'ruby -rjson -ne ' . shellescape(
        \ 'h = JSON.parse($_) rescue next; t = h["text"].to_s.strip; ' .
        \ 'puts "%s:%s: %s\t%s\t%s\t%s\t%s" % ' .
        \ '[h["path"], h["line"], t, h["path"], h["line"], h["matched_in"], t]')
endfunction

" Shell command producing formatted hits. query is either a literal, or {q} for
" fzf to substitute on reload.
function! s:fetch_cmd(scope, mode, query) abort
  let base = webdavsearch#api#curl_cmd('/api/vault/search',
        \ extend({'format': 'ndjson', 'in': a:mode}, s:params(a:scope, '')))
  return base . ' --data-urlencode q=' . a:query . ' | ' . s:hit_formatter()
endfunction

" The wikilink the vault uses is a basename, so moving a note does not break
" the link. A heading match points inside the note; an alias keeps the word you
" searched for while still pointing at the file.
function! s:insert_wikilink(parts) abort
  let base = fnamemodify(a:parts[1], ':t:r')
  let matched_in = get(a:parts, 3, 'filename')
  let text = get(a:parts, 4, '')

  if matched_in ==# 'heading'
    let link = base . '#' . substitute(text, '^#\+\s*', '', '')
  elseif matched_in ==# 'alias' && !empty(text) && text !=# base
    let link = base . '|' . text
  else
    let link = base
  endif

  execute 'normal! a[[' . link . ']]'
  " carry on typing right behind the link, wherever in the line it went
  call feedkeys('a', 'n')
endfunction

function! s:handle(scope, mode, action, result) abort
  let query = get(a:result, 0, '')
  let key = get(a:result, 1, '')

  " fzf cannot swap a change:reload command at runtime, so both switches mean
  " starting again with the query carried over — the same move
  " webdav#fzf#handle_sink makes for ctrl-r. The action rides along so Tab does
  " not turn a link insertion into a jump.
  if key ==# 'ctrl-a'
    call s:live_search('', a:mode, query, a:action)
    return
  endif
  if key ==# 'tab'
    call s:live_search(a:scope, s:modes[a:mode], query, a:action)
    return
  endif

  let parts = split(get(a:result, 2, ''), "\t")
  if len(parts) < 3
    return
  endif

  if a:action ==# 'insert'
    call s:insert_wikilink(parts)
  else
    call webdavsearch#api#open(parts[1], str2nr(parts[2]))
  endif
endfunction

" Live content search: fzf holds no list of its own, it re-asks the index on
" every keystroke. --disabled turns off local filtering so the server decides
" what matches, the same shape vimrc's :Rg uses for ripgrep.
function! s:live_search(scope, mode, query, action) abort
  if !executable('fzf')
    echoerr 'Error: fzf is not installed'
    return
  endif

  " With a carried-over query there is no change event to fire the first fetch,
  " so the source runs it once with that query baked in.
  let source = empty(a:query) ? 'true' : s:fetch_cmd(a:scope, a:mode, shellescape(a:query))

  let header = a:action ==# 'insert' ? 'enter: insert a link  |  ' : ''
  let header .= 'tab: ' . s:modes[a:mode]
  if !empty(a:scope)
    let header .= '  |  ctrl-a: widen to the whole vault'
  endif

  let options = [
        \ '--prompt', s:mode_label(a:mode) . '(' . s:scope_label(a:scope) . ')> ',
        \ '--header', header,
        \ '--delimiter', '\t',
        \ '--with-nth', '1',
        \ '--disabled',
        \ '--print-query',
        \ '--expect', 'ctrl-a,tab',
        \ '--bind', 'change:reload:[ -z {q} ] || ' . s:fetch_cmd(a:scope, a:mode, '{q}'),
        \ ]

  if !empty(a:query)
    let options += ['--query', a:query]
  endif

  call fzf#run(fzf#wrap({
    \ 'source': source,
    \ 'sink*': function('s:handle', [a:scope, a:mode, a:action]),
    \ 'options': options,
    \ 'down': '80%'
  \ }))
endfunction

function! s:mode_label(mode) abort
  return a:mode ==# 'title' ? 'Title' : 'Content'
endfunction

" Fill quickfix from hits. Entries carry the WebDAV buffer name so <CR> opens
" the note on the server rather than a local path that does not exist.
function! s:to_quickfix(title, results, index) abort
  let items = []
  for hit in a:results
    let name = webdavsearch#api#buffer_name(get(hit, 'path', ''))
    if empty(name)
      continue
    endif
    call add(items, {
          \ 'filename': name,
          \ 'lnum': get(hit, 'line', 1),
          \ 'col': get(hit, 'column', 1),
          \ 'text': get(hit, 'text', ''),
          \ })
  endfor

  call setqflist([], ' ', {'title': a:title, 'items': items})
  copen
  echo printf('%d results — %s', len(items), webdavsearch#api#staleness(a:index))
endfunction

" Vault-relative path of the note in this buffer, or '' when there is none.
function! s:current_path() abort
  if !exists('b:webdav_original_path')
    echo 'Not a WebDAV document buffer'
    return ''
  endif
  return substitute(b:webdav_original_path, '^/', '', '')
endfunction

" :WebDAVSearch searches below the folder you are in; the bang searches the
" whole vault.
function! webdavsearch#ui#search(query, whole_vault) abort
  let scope = a:whole_vault ? '' : webdavsearch#api#scope(webdav#buffer#context())
  call s:run_search(scope, a:query)
endfunction

" No query opens the live picker; a query answers once into quickfix, which is
" what a repeatable or scripted search wants.
function! s:run_search(scope, query) abort
  if empty(trim(a:query))
    call s:live_search(a:scope, 'title', '', 'open')
    return
  endif

  " A query given on the command line has no Tab to press, so it searches both
  " rather than guessing which half you meant
  let params = extend({'q': trim(a:query), 'in': 'all'}, s:params(a:scope, ''))
  let data = webdavsearch#api#get('/api/vault/search', params)
  if empty(data)
    return
  endif

  call s:to_quickfix(printf('Vault(%s): %s', s:scope_label(a:scope), trim(a:query)),
        \ get(data, 'results', []), get(data, 'index', {}))
endfunction

" Run a search over one whole server's subtree, named rather than inferred.
" The dashboard and any other caller outside a WebDAV buffer has no folder to
" scope to, so it says which one it means.
function! webdavsearch#ui#search_in(args) abort
  let parts = split(trim(a:args), '\s\+')
  if empty(parts)
    echo 'Usage: WebDAVSearchIn {server} [query]'
    return
  endif

  let server = parts[0]
  let scope = webdavsearch#api#server_scope(server)
  if scope is v:null
    echoerr "Error: '" . server . "' is not a server under the vault root"
    return
  endif

  call s:run_search(scope, join(parts[1:], ' '))
endfunction

" Server names, for :WebDAVSearchIn completion
function! webdavsearch#ui#complete_servers(...) abort
  return join(sort(keys(webdav#server#scan())), "\n")
endfunction

" Pick a note and drop a wikilink to it at the cursor. Vault-wide: when you are
" writing you link to anything, not only to what is nearby.
function! webdavsearch#ui#insert_link() abort
  call s:live_search('', 'title', '', 'insert')
endfunction

function! webdavsearch#ui#backlinks() abort
  let path = s:current_path()
  if empty(path)
    return
  endif

  let data = webdavsearch#api#get('/api/vault/backlinks',
        \ {'path': path, 'limit': g:webdav_search_limit})
  if empty(data)
    return
  endif

  call s:to_quickfix('Backlinks: ' . path,
        \ get(data, 'results', []), get(data, 'index', {}))
endfunction

" state=unresolved is the broken-link check; the default lists every link.
function! webdavsearch#ui#links(state) abort
  let path = s:current_path()
  if empty(path)
    return
  endif

  let data = webdavsearch#api#get('/api/vault/links',
        \ {'path': path, 'state': empty(a:state) ? 'all' : a:state})
  if empty(data)
    return
  endif

  call s:to_quickfix('Links: ' . path,
        \ get(data, 'results', []), get(data, 'index', {}))
endfunction

function! s:pick_tag(selection) abort
  let tag = matchstr(a:selection, '^\S\+')
  if empty(tag)
    return
  endif

  " Asking for a tag by name beats excluding it by default
  let params = extend({'tag': [tag]}, s:params('', tag))
  let data = webdavsearch#api#get('/api/vault/search', params)
  if empty(data)
    return
  endif

  call s:to_quickfix('Tag: ' . tag, get(data, 'results', []), get(data, 'index', {}))
endfunction

function! webdavsearch#ui#tags() abort
  if !executable('fzf')
    echoerr 'Error: fzf is not installed'
    return
  endif

  let data = webdavsearch#api#get('/api/vault/tags', {'limit': 500})
  if empty(data)
    return
  endif

  let source = []
  for entry in get(data, 'results', [])
    call add(source, printf('%-30s %d', entry.tag, get(entry, 'count', 0)))
  endfor

  if empty(source)
    echo 'No tags in the index'
    return
  endif

  call fzf#run(fzf#wrap({
    \ 'source': source,
    \ 'sink': function('s:pick_tag'),
    \ 'options': [
    \   '--prompt', 'Tag> ',
    \   '--header', webdavsearch#api#staleness(get(data, 'index', {})),
    \ ],
    \ 'down': '40%'
  \ }))
endfunction
