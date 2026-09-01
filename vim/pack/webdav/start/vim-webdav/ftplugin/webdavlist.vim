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

" Key mappings for navigation, from the table webdav#ui#hint_line() also renders
let b:undo_ftplugin = "setlocal buftype< bufhidden< swapfile< modifiable< nowrap< cursorline< conceallevel< statusline<"

" NOTE: map/unmap commands absorb a literal '|' into their {lhs}, so they
" cannot be chained with '| nunmap ...'. Wrap each in execute() so the '|'
" acts as a real command separator and every unmap actually runs.
for s:keymap in webdav#ui#keymaps()
  execute printf('nnoremap <buffer> %s :%s<CR>', s:keymap.key, s:keymap.rhs)
  let b:undo_ftplugin .= " | exe 'silent! nunmap <buffer> " . s:keymap.key . "'"
endfor
unlet! s:keymap
