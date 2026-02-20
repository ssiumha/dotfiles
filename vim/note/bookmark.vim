" Bookmark picker using floaterm + bmf script
" Requires: floaterm plugin, ~/dots/bin/bmf

if exists('g:loaded_note_bookmark')
  finish
endif
let g:loaded_note_bookmark = 1

function! BookmarkPick() abort
  let cmd = $HOME . '/dots/bin/bmf'
  call floaterm#terminal#open(-1, [&shell, &shellcmdflag, cmd], {}, {})
endfunction

command! BookmarkPick call BookmarkPick()
