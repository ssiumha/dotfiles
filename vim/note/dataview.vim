" Load day.vim for PickDate function
runtime note/day.vim

" Base62 for anchor ID generation
let s:base62 = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'

function! NoteBase62Encode(num)
  if a:num == 0 | return '0' | endif
  let result = ''
  let n = a:num
  while n > 0
    let result = s:base62[n % 62] . result
    let n = n / 62
  endwhile
  return result
endfunction

function! NoteRandomBase62(len)
  let result = ''
  for i in range(a:len)
    let result .= s:base62[rand() % 62]
  endfor
  return result
endfunction

function! NoteGenerateAnchorId()
  return NoteBase62Encode(localtime()) . NoteRandomBase62(3)
endfunction

" Dataview emoji shorthand mappings (date fields only)
" https://blacksmithgu.github.io/obsidian-dataview/annotation/metadata-tasks/
let s:emoji_to_field = {
  \ '🗓️': 'due',
  \ '✅': 'completion',
  \ '➕': 'created',
  \ '🛫': 'start',
  \ '⏳': 'scheduled',
  \ }
let s:field_to_emoji = {}
for [emoji, field] in items(s:emoji_to_field)
  let s:field_to_emoji[field] = emoji
endfor

function! s:ExtractDataviewFields()
  let line = getline('.')
  let fields = []

  " Extract [key:: value] inline fields
  let start = 0
  while 1
    let ms = match(line, '\[', start)
    if ms == -1 | break | endif
    let me = match(line, '\]', ms)
    if me == -1 | break | endif
    let content = line[ms+1 : me-1]
    if content =~ '::'
      let [key, val] = split(content, '::\s*', 1)
      call add(fields, {'key': key, 'val': val, 'type': 'inline'})
    endif
    let start = me + 1
  endwhile

  " Extract emoji shorthand fields (🗓️2025-11-11 format)
  for [emoji, field] in items(s:emoji_to_field)
    let pattern = emoji . '\(\d\{4}-\d\{2}-\d\{2}\)'
    let match_result = matchlist(line, pattern)
    if !empty(match_result)
      call add(fields, {'key': field, 'val': match_result[1], 'type': 'emoji', 'emoji': emoji})
    endif
  endfor

  return fields
endfunction

function! s:ApplyDataviewFields(fields)
  let line = getline('.')

  " Remove existing inline fields [key:: value]
  let line = substitute(line, '\s*\[[^\[\]]*::[^\[\]]*\]', '', 'g')

  " Remove existing emoji shorthand fields
  for emoji in keys(s:emoji_to_field)
    let line = substitute(line, '\s*' . emoji . '\d\{4}-\d\{2}-\d\{2}', '', 'g')
  endfor

  " Apply fields
  for f in a:fields
    if has_key(s:field_to_emoji, f.key)
      " Date field: use emoji shorthand
      let line .= ' ' . s:field_to_emoji[f.key] . f.val
    else
      " Other field: use inline field syntax
      let line .= ' [' . f.key . ':: ' . f.val . ']'
    endif
  endfor
  call setline('.', line)
endfunction

function! DataviewProperty() abort
  let fields = s:ExtractDataviewFields()
  let items = map(copy(fields), {_, f -> f.key . ':: ' . f.val})

  let header = "enter:edit  ctrl-n:new  ctrl-d:delete\n"
  let header .= "🗓️due ✅completion ➕created 🛫start ⏳scheduled  id:anchor"

  call fzf#run(fzf#wrap({
    \ 'source': items,
    \ 'options': ['--prompt=Field> ', '--print-query', '--expect=ctrl-d,ctrl-n', '--header=' . header],
    \ 'sink*': {lines -> s:HandlePropertySelection(lines, fields)},
    \ }))
endfunction

function! s:HandlePropertySelection(lines, fields)
  " --print-query 형식: [query, action, selected]
  let query = a:lines[0]
  let action = len(a:lines) >= 2 ? a:lines[1] : ''
  let selected = len(a:lines) >= 3 ? a:lines[2] : ''

  " ctrl-n: 현재 query를 key로 새 필드 추가
  if action == 'ctrl-n'
    let key = query
    if empty(key) | return | endif
    " FZF 종료 대기 후 floaterm 실행
    call timer_start(100, { -> s:InputValueDeferred(key, '', a:fields, -1) })
    return
  endif

  if empty(selected) | return | endif

  let idx = index(map(copy(a:fields), {_, f -> f.key . ':: ' . f.val}), selected)
  if idx == -1 | return | endif

  if action == 'ctrl-d'
    call remove(a:fields, idx)
    call s:ApplyDataviewFields(a:fields)
  else
    let key = a:fields[idx].key
    let current_val = a:fields[idx].val
    " FZF 종료 대기 후 floaterm 실행
    call timer_start(100, { -> s:InputValueDeferred(key, current_val, a:fields, idx) })
  endif
endfunction

" FZF 종료 후 값 입력 처리
" idx == -1: 새 필드 추가, idx >= 0: 기존 필드 수정
function! s:InputValueDeferred(key, current_val, fields, idx) abort
  " id 필드 신규 추가 시 자동 생성
  if a:key ==# 'id' && a:idx == -1
    let val = NoteGenerateAnchorId()
    call s:AddFieldAndApply(a:fields, a:key, val)
    echo 'Anchor: ' . val
    return
  endif

  if has_key(s:field_to_emoji, a:key)
    " 날짜 필드: PickDate (floaterm)
    let initial = empty(a:current_val) ? strftime('%Y-%m-%d') : a:current_val
    call PickDate(initial, { val ->
      \ a:idx == -1
      \   ? s:AddFieldAndApply(a:fields, a:key, val)
      \   : s:UpdateFieldAndApply(a:fields, a:idx, val)
      \ })
  else
    " 일반 필드: input()
    let val = input(a:key . ': ', a:current_val)
    if !empty(val)
      if a:idx == -1
        call s:AddFieldAndApply(a:fields, a:key, val)
      else
        call s:UpdateFieldAndApply(a:fields, a:idx, val)
      endif
    endif
  endif
endfunction

function! s:AddFieldAndApply(fields, key, val) abort
  if empty(a:val) | return | endif
  call add(a:fields, {'key': a:key, 'val': a:val})
  call s:ApplyDataviewFields(a:fields)
endfunction

function! s:UpdateFieldAndApply(fields, idx, val) abort
  if empty(a:val) | return | endif
  let a:fields[a:idx].val = a:val
  call s:ApplyDataviewFields(a:fields)
endfunction
