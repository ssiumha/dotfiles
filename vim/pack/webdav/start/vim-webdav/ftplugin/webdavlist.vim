" Vim filetype plugin file
" Language: WebDAV Directory Listing
" Maintainer: vim-webdav
" Last Change: 2025

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Buffer-local settings
setlocal buftype=nofile
setlocal bufhidden=wipe
setlocal noswapfile
setlocal nomodifiable
setlocal nowrap
setlocal cursorline

" Conceal settings (optional - hide some visual clutter)
setlocal conceallevel=0

" Status line
if has('statusline')
  setlocal statusline=%{get(b:,'webdav_current_path','')}%=WebDAV\ List
endif

" Key mappings for navigation
nnoremap <buffer> <CR> :call webdav#ui#open()<CR>
nnoremap <buffer> t :call webdav#ui#open_in_tab()<CR>
nnoremap <buffer> - :call webdav#ui#go_up()<CR>
nnoremap <buffer> r :call webdav#ui#list(b:webdav_current_path, b:webdav_server)<CR>
nnoremap <buffer> R :call webdav#operations#rename()<CR>
nnoremap <buffer> D :call webdav#operations#delete()<CR>

" NOTE: map/unmap commands absorb a literal '|' into their {lhs}, so they
" cannot be chained with '| nunmap ...'. Wrap each in execute() so the '|'
" acts as a real command separator and every unmap actually runs.
let b:undo_ftplugin = "setlocal buftype< bufhidden< swapfile< modifiable< nowrap< cursorline< conceallevel< statusline<"
      \ . " | exe 'silent! nunmap <buffer> <CR>'"
      \ . " | exe 'silent! nunmap <buffer> t'"
      \ . " | exe 'silent! nunmap <buffer> -'"
      \ . " | exe 'silent! nunmap <buffer> r'"
      \ . " | exe 'silent! nunmap <buffer> R'"
      \ . " | exe 'silent! nunmap <buffer> D'"
