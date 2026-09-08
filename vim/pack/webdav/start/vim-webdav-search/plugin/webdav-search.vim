" vim-webdav-search - search a vault through an index API
"
" A layer beside vim-webdav, not part of it. WebDAV reads and writes files;
" searching needs an index, which lives behind an HTTP API. Results open as
" webdav:// buffers, so the two feel like one thing without being one.
"
" The dependency runs one way: this plugin calls vim-webdav, never the reverse.
"
" Configure outside this repository, next to $WEBDAV_UI_*:
"   let g:webdav_search_url = '...'   or $WEBDAV_SEARCH_URL
"   let g:webdav_search_server = 'home'

if exists('g:loaded_webdav_search')
  finish
endif
let g:loaded_webdav_search = 1

let g:webdav_search_url = get(g:, 'webdav_search_url', $WEBDAV_SEARCH_URL)
let g:webdav_search_server = get(g:, 'webdav_search_server', 'home')
let g:webdav_search_limit = get(g:, 'webdav_search_limit', 200)

" Tags whose notes stay out of search results. Which ones is a property of
" your vault, not of this plugin, so the list belongs in your configuration.
" Asking for a tag by name in :WebDAVSearchTags overrides it.
let g:webdav_search_exclude_tags = get(g:, 'webdav_search_exclude_tags', [])

" Nothing is registered without an address, so a machine that cannot reach the
" index keeps vim-webdav's own search and its <space>pr mapping untouched.
if empty(g:webdav_search_url)
  finish
endif

command! -bang -nargs=* WebDAVSearch call webdavsearch#ui#search(<q-args>, <bang>0)
command! WebDAVSearchBacklinks call webdavsearch#ui#backlinks()
command! -nargs=? WebDAVSearchLinks call webdavsearch#ui#links(<q-args>)
command! WebDAVSearchTags call webdavsearch#ui#tags()
command! WebDAVSearchInsertLink call webdavsearch#ui#insert_link()
command! -nargs=+ -complete=custom,webdavsearch#ui#complete_servers
      \ WebDAVSearchIn call webdavsearch#ui#search_in(<q-args>)

" Palette entries. 'Search:' marks the ones answered by the index, next to the
" WebDAV-only entries the other plugin already contributes.
"
" Guarded by g:loaded_webdav alone: exists('*webdav#palette#register') is false
" here because the autoload script has not been sourced yet, and testing it
" would skip registration every time. Calling it is what loads the script; the
" catch covers a vim-webdav old enough to lack the extension point.
if exists('g:loaded_webdav')
  try
    call webdav#palette#register({'label': 'Search: contents (here)',
          \ 'desc': 'below the folder you are in', 'cmd': 'WebDAVSearch'})
    call webdav#palette#register({'label': 'Search: contents (vault)',
          \ 'desc': 'the whole vault', 'cmd': 'WebDAVSearch!'})
    call webdav#palette#register({'label': 'Search: tags',
          \ 'desc': 'pick a tag, then its notes', 'cmd': 'WebDAVSearchTags'})
    call webdav#palette#register({'label': 'Search: backlinks',
          \ 'desc': 'notes linking here, aliases included',
          \ 'when': 'file', 'cmd': 'WebDAVSearchBacklinks'})
    call webdav#palette#register({'label': 'Search: links',
          \ 'desc': 'links this note points at',
          \ 'when': 'file', 'cmd': 'WebDAVSearchLinks'})
    call webdav#palette#register({'label': 'Search: insert link',
          \ 'desc': 'pick a note, drop a [[wikilink]]',
          \ 'when': 'file', 'cmd': 'WebDAVSearchInsertLink'})
  catch /E117:/
  endtry
endif

" ftplugin belongs to vim-webdav, so keys go on through FileType, which runs
" after it. <space>pr moves to content search because that is what the key
" means everywhere else; without an index it stays on vim-webdav's picker.
function! s:map_buffer() abort
  nnoremap <buffer> <space>pr :WebDAVSearch<CR>
  nnoremap <buffer> <space>pR :WebDAVSearch!<CR>
  if exists('b:undo_ftplugin')
    let b:undo_ftplugin .= " | exe 'silent! nunmap <buffer> <space>pr'"
    let b:undo_ftplugin .= " | exe 'silent! nunmap <buffer> <space>pR'"
  endif

  " Link insertion only where there is text to insert into; a listing is
  " nomodifiable. <C-c><C-k> joins note.vim's <C-c> family.
  if &filetype ==# 'webdav'
    inoremap <buffer> <C-c><C-k> <C-o>:call webdavsearch#ui#insert_link()<CR>
    if exists('b:undo_ftplugin')
      let b:undo_ftplugin .= " | exe 'silent! iunmap <buffer> <C-c><C-k>'"
    endif
  endif
endfunction

augroup webdav_search_keys
  autocmd!
  autocmd FileType webdav,webdavlist call s:map_buffer()
augroup END
