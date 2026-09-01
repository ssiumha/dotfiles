" autoload/webdav/palette.vim - <space><space> command palette
" One key in two buffers: a listing acts on the line under the cursor, a
" document acts on the file it holds. webdav#buffer#context() absorbs that
" difference so every action below reads one shape.

" A listing shows a move by reloading; a document has to follow the file to
" its new path, and the buffer left behind under the old name goes away.
function! s:after_move(ctx, dest) abort
  if a:ctx.kind ==# 'list'
    call webdav#ui#list(a:ctx.dir, a:ctx.server)
    return
  endif
  let old = bufnr('%')
  call WebDAVGet(a:dest, a:ctx.server)
  if bufnr('%') != old && bufexists(old)
    execute 'silent! bwipeout ' . old
  endif
endfunction

function! s:rename(ctx) abort
  let prompt = a:ctx.is_folder ? 'Rename folder to: ' : 'Rename file to: '
  let new_name = input(prompt, a:ctx.name)
  if empty(trim(new_name)) || trim(new_name) ==# a:ctx.name
    echo "\nCancelled"
    return
  endif

  let new_name = trim(new_name)
  if a:ctx.is_folder && new_name !~ '/$'
    let new_name .= '/'
  endif

  " A name carrying directories moves as well as renames, same as the R key
  let dest = new_name =~ '^/' ? new_name : webdav#core#join_path(a:ctx.dir, new_name)

  if !webdav#operations#move_path(a:ctx.target, dest, a:ctx.server)
    return
  endif

  echo "\nRenamed: " . a:ctx.name . ' -> ' . new_name
  call s:after_move(a:ctx, dest)
endfunction

function! s:move(ctx) abort
  let server_info = webdav#server#get_info(a:ctx.server)
  if empty(server_info)
    return
  endif

  if !executable('fzf')
    echoerr 'Error: fzf is not installed'
    return
  endif

  let vault_root = webdav#wikilink#get_vault_root(a:ctx.server)
  let base_path = empty(vault_root) ? '/' : vault_root
  if base_path !~ '/$'
    let base_path .= '/'
  endif

  " scan-bfs.sh only emits paths below the base, so './' stands for the base
  let source = "printf './\\n'; " . webdav#fzf#build_scan_cmd(
        \ base_path, server_info, get(g:, 'webdav_fzf_max_depth', 3), 'dirs')

  call fzf#run(fzf#wrap({
    \ 'source': source,
    \ 'sink*': function('s:move_sink', [a:ctx, base_path]),
    \ 'options': [
    \   '--prompt', 'Move to> ',
    \   '--print-query',
    \   '--header', 'Enter: move ' . a:ctx.name . ' into the selected folder',
    \ ],
    \ 'down': '40%'
  \ }))
endfunction

function! s:move_sink(ctx, base_path, result) abort
  if len(a:result) < 1
    return
  endif

  " --print-query without --expect gives [query, selection]
  let selection = len(a:result) > 1 ? a:result[1] : ''
  let folder = webdav#core#clean_string(empty(selection) ? a:result[0] : selection)
  if empty(folder)
    echo 'No folder selected'
    return
  endif
  if folder ==# './'
    let folder = ''
  endif

  let dest = webdav#core#join_path(webdav#core#join_path(a:base_path, folder), a:ctx.name)
  if dest ==# a:ctx.target
    echo 'Already there: ' . dest
    return
  endif

  if !webdav#operations#move_path(a:ctx.target, dest, a:ctx.server)
    return
  endif

  echo 'Moved to: ' . dest
  call s:after_move(a:ctx, dest)
endfunction

function! s:delete(ctx) abort
  if !webdav#operations#delete_path(a:ctx.target, a:ctx.server, a:ctx.is_folder)
    return
  endif

  echo "\nDeleted: " . a:ctx.name

  " The listing reuses its own buffer, so this only wipes the document one
  let old = bufnr('%')
  call webdav#ui#list(a:ctx.dir, a:ctx.server)
  if bufnr('%') != old && bufexists(old)
    execute 'silent! bwipeout ' . old
  endif
endfunction

function! s:new_file(ctx) abort
  call webdav#operations#create_file(a:ctx.dir)
endfunction

function! s:new_folder(ctx) abort
  call webdav#operations#create_folder(a:ctx.dir)
endfunction

function! s:find(ctx) abort
  call webdav#fzf#open_at(a:ctx.dir, a:ctx.server)
endfunction

function! s:parent(ctx) abort
  if a:ctx.kind ==# 'file'
    call webdav#ui#list(a:ctx.dir, a:ctx.server)
  else
    call webdav#ui#go_up()
  endif
endfunction

function! s:reload(ctx) abort
  if a:ctx.kind ==# 'file'
    call webdav#buffer#reload()
  else
    call webdav#ui#list(a:ctx.dir, a:ctx.server)
  endif
endfunction

" when: 'always' | 'target' (needs a resource under the cursor) | 'file'
" Entries carry either 'cmd' (an ex-command) or 'run' (a Funcref taking ctx).
let s:actions = [
      \ {'label': 'Rename',          'desc': 'change name or path (MOVE)', 'when': 'target', 'run': function('s:rename')},
      \ {'label': 'Move to folder',  'desc': 'pick a folder (MOVE)',       'when': 'target', 'run': function('s:move')},
      \ {'label': 'Delete',          'desc': 'remove (DELETE)',            'when': 'target', 'run': function('s:delete')},
      \ {'label': 'New file',        'desc': 'create .md here',            'when': 'always', 'run': function('s:new_file')},
      \ {'label': 'New folder',      'desc': 'create folder here (MKCOL)', 'when': 'always', 'run': function('s:new_folder')},
      \ {'label': 'Find file',       'desc': 'recursive fzf from here',    'when': 'always', 'run': function('s:find')},
      \ {'label': 'Grep vault',      'desc': 'search file contents',       'when': 'always', 'cmd': 'WebDAVGrepFzf'},
      \ {'label': 'Backlinks',       'desc': 'notes linking here',         'when': 'file',   'cmd': 'WebDAVBacklinks'},
      \ {'label': 'Recent files',    'desc': 'recently opened',            'when': 'always', 'cmd': 'WebDAVRecentFzf'},
      \ {'label': 'Parent listing',  'desc': 'browse the folder above',    'when': 'always', 'run': function('s:parent')},
      \ {'label': 'Diff with server','desc': 'compare against remote',     'when': 'file',   'cmd': 'WebDAVDiff'},
      \ {'label': 'Save',            'desc': 'upload buffer (PUT)',        'when': 'file',   'cmd': 'WebDAVPut'},
      \ {'label': 'Reload',          'desc': 'fetch again',                'when': 'always', 'run': function('s:reload')},
      \ ]

function! s:entries(ctx) abort
  let entries = []

  for action in s:actions
    if action.when ==# 'target' && empty(a:ctx.target)
      continue
    endif
    if action.when ==# 'file' && a:ctx.kind !=# 'file'
      continue
    endif
    call add(entries, action)
  endfor

  " Note entries come from the user's g:webdav_note_patterns rather than a list
  " repeated here, so configuring a pattern is what puts it in the palette.
  for name in sort(keys(get(g:, 'webdav_note_patterns', {})))
    call add(entries, {'label': 'Note: ' . name, 'desc': 'open or create',
          \ 'when': 'always', 'cmd': 'WebDAVNote ' . name})
  endfor

  return entries
endfunction

function! s:run(ctx, entries, selection) abort
  let entry = get(a:entries, str2nr(matchstr(a:selection, "\t\\zs\\d\\+$")), {})
  if empty(entry)
    return
  endif

  if has_key(entry, 'cmd')
    execute entry.cmd
  else
    call entry.run(a:ctx)
  endif
endfunction

function! webdav#palette#open() abort
  let ctx = webdav#buffer#context()
  if empty(ctx)
    echo 'Not a WebDAV buffer'
    return
  endif

  if !executable('fzf')
    echoerr 'Error: fzf is not installed'
    return
  endif

  let entries = s:entries(ctx)

  " Index rides along after a tab so --with-nth 1 shows only label + desc
  let source = []
  for idx in range(len(entries))
    call add(source, printf("%-17s %s\t%d", entries[idx].label, entries[idx].desc, idx))
  endfor

  call fzf#run(fzf#wrap({
    \ 'source': source,
    \ 'sink': function('s:run', [ctx, entries]),
    \ 'options': [
    \   '--prompt', 'WebDAV> ',
    \   '--header', 'target: ' . (empty(ctx.target) ? ctx.dir : ctx.target),
    \   '--delimiter', '\t',
    \   '--with-nth', '1',
    \   '--no-sort',
    \ ],
    \ 'down': '40%'
  \ }))
endfunction
