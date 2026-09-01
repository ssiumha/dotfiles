" Vim filetype plugin file
" Language: WebDAV File Buffer
" Maintainer: vim-webdav
" Last Change: 2025

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Buffer-local settings for WebDAV-managed files
setlocal noswapfile

" Show WebDAV info in status line
if has('statusline')
  let server_name = get(b:, 'webdav_server', '')
  if !empty(server_name)
    setlocal statusline=%f\ [WebDAV:\ %{get(b:,'webdav_server','')}]%=%y\ %l,%c\ %P
  else
    setlocal statusline=%f\ [WebDAV]%=%y\ %l,%c\ %P
  endif
endif

" Key mapping: - to open parent directory listing
nnoremap <buffer> <silent> - :WebDAVList<CR>

" Key mappings for wikilink navigation
" gf: follow wikilink under cursor (like vim's gf for goto file)
nnoremap <buffer> <silent> gf :call webdav#wikilink#open()<CR>

" Note: <CR> mapping is handled by note.vim's OpenWiki() which dispatches to
" webdav#wikilink#open() for WebDAV buffers

" Wrap each unmap in execute() — map/unmap commands swallow a literal '|'
" into their {lhs}, so chaining with '| nunmap ...' silently skips all but
" the first. execute() makes the '|' a real separator.
let b:undo_ftplugin = "setlocal swapfile< statusline< | exe 'silent! nunmap <buffer> -' | exe 'silent! nunmap <buffer> gf'"

" The palette and the <space>p pickers act on this buffer the same way they act
" on a listing, so they come from the table ftplugin/webdavlist.vim maps
for s:keymap in filter(copy(webdav#ui#keymaps()), 'v:val.shared')
  execute printf('nnoremap <buffer> %s :%s<CR>', s:keymap.key, s:keymap.rhs)
  let b:undo_ftplugin .= " | exe 'silent! nunmap <buffer> " . s:keymap.key . "'"
endfor
unlet! s:keymap
