" Dataview field completion via C-n/C-p
" Detects `[` context and offers dataview field candidates
" Date fields → emoji shorthand (🗓️2026-02-09), id → inline ([id:: val])

let s:dataview_fields = [
  \ {'word': 'due',        'emoji': '🗓️', 'menu': '🗓️ 마감일'},
  \ {'word': 'created',    'emoji': '➕', 'menu': '➕ 생성일'},
  \ {'word': 'start',      'emoji': '🛫', 'menu': '🛫 시작일'},
  \ {'word': 'scheduled',  'emoji': '⏳', 'menu': '⏳ 예정일'},
  \ {'word': 'completion', 'emoji': '✅', 'menu': '✅ 완료일'},
  \ {'word': 'id',         'emoji': '',   'menu': '🔖 앵커 ID'},
  \ ]

function! NoteComplete(findstart, base)
  if a:findstart
    let line = getline('.')
    let col = col('.') - 1

    " Find the `[` that starts this context — return its position (include `[`)
    let i = col - 1
    while i >= 0
      if line[i] == '['
        let between = line[i+1 : col-1]
        if between !~ ']'
          return i
        endif
      endif
      let i -= 1
    endwhile
    return -3
  endif

  " base includes leading `[` — strip for matching
  let match_base = substitute(a:base, '^\[', '', '')
  let today = strftime('%Y-%m-%d')
  let candidates = []

  for f in s:dataview_fields
    if f.word =~? '^' . match_base
      if !empty(f.emoji)
        " Date field: emoji shorthand (replaces `[`, CompleteDone removes `]`)
        let word = f.emoji . today
        let ud = 'emoji'
      else
        " id field: inline format (keep `[`, auto-pair provides `]`)
        let word = '[' . f.word . ':: ' . NoteGenerateAnchorId()
        let ud = ''
      endif
      call add(candidates, {
        \ 'word': word,
        \ 'abbr': f.word,
        \ 'menu': f.menu,
        \ 'user_data': ud,
        \ })
    endif
  endfor
  return candidates
endfunction

" Remove trailing `]` left by auto-pair after emoji completion
function! s:OnNoteCompleteDone()
  let item = v:completed_item
  if empty(item) || get(item, 'user_data', '') !=# 'emoji'
    return
  endif
  let col = col('.')
  let line = getline('.')
  if col <= len(line) && line[col - 1] ==# ']'
    call setline('.', line[:col-2] . line[col:])
  endif
endfunction

augroup NoteComplete
  autocmd!
  autocmd CompleteDone *.md call s:OnNoteCompleteDone()
augroup END

function! s:InBracketContext()
  let line = getline('.')
  let col = col('.') - 1
  let i = col - 1
  while i >= 0
    if line[i] == ']' | return 0 | endif
    if line[i] == '['
      if i > 0 && line[i-1] == '[' | return 0 | endif
      return 1
    endif
    let i -= 1
  endwhile
  return 0
endfunction

function! NoteSmartCN()
  if pumvisible() | return "\<C-n>" | endif
  if s:InBracketContext() | return "\<C-x>\<C-u>" | endif
  return "\<C-n>"
endfunction

function! NoteSmartCP()
  if pumvisible() | return "\<C-p>" | endif
  if s:InBracketContext() | return "\<C-x>\<C-u>" | endif
  return "\<C-p>"
endfunction
