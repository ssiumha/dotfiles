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

let b:undo_ftplugin = "setlocal buftype< bufhidden< noswapfile< nomodifiable< nowrap< cursorline< conceallevel< statusline<"
      \ . " | silent! nunmap <buffer> <CR>"
      \ . " | silent! nunmap <buffer> t"
      \ . " | silent! nunmap <buffer> -"
      \ . " | silent! nunmap <buffer> r"
      \ . " | silent! nunmap <buffer> R"
      \ . " | silent! nunmap <buffer> D"
