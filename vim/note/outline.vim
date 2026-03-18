let s:tmp_current_hash = tempname()
let s:tmp_current_path = tempname()
let s:tmp_all_hash = tempname()
let s:tmp_all_path = tempname()

" fzf 표시용 문자열 (idx\tfilename:lnum\tdisplay)
function! s:FormatLine(idx, bufnr, lnum, display) abort
  let name = fnamemodify(bufname(a:bufnr), ':t')
  return printf("%d\t%s:%d\t%s", a:idx, name, a:lnum, a:display)
endfunction

" 버퍼에서 헤더 추출 (hash + path 두 형식)
function! s:ExtractHeaders(bufnr, lines_hash, lines_path, idx) abort
  let stack = []  " breadcrumb 스택: [[level, text], ...]
  let lnum = 0
  let buf_lines = a:bufnr == bufnr('%') ? getline(1, '$') : getbufline(a:bufnr, 1, '$')

  for line in buf_lines
    let lnum += 1
    if line =~# '^#\+\s'
      let a:idx[0] += 1
      let hashes = matchstr(line, '^#\+')
      let level = strlen(hashes)
      let text = substitute(line, '^#\+\s*', '', '')

      " 스택 정리: 현재 레벨보다 깊거나 같은 것 제거
      while len(stack) > 0 && stack[-1][0] >= level
        call remove(stack, -1)
      endwhile
      call add(stack, [level, text])

      " breadcrumb 생성
      let path = join(map(copy(stack), 'v:val[1]'), ' › ')

      call add(a:lines_hash, s:FormatLine(a:idx[0], a:bufnr, lnum, hashes . ' ' . text))
      call add(a:lines_path, s:FormatLine(a:idx[0], a:bufnr, lnum, path))
    endif
  endfor
endfunction

" 현재 버퍼 헤더 추출 → qf + 임시파일
function! s:BuildCurrentBuffer() abort
  let lines_hash = []
  let lines_path = []
  let idx = [0]

  call s:ExtractHeaders(bufnr('%'), lines_hash, lines_path, idx)

  " qf 저장 (hash 형식)
  let items = []
  for line in lines_hash
    let parts = split(line, "\t")
    let [filename, lnum] = split(parts[1], ':')
    call add(items, {'bufnr': bufnr('%'), 'lnum': str2nr(lnum), 'text': parts[2]})
  endfor
  call setqflist([], 'r', {'title': 'Outline', 'items': items})

  call writefile(lines_hash, s:tmp_current_hash)
  call writefile(lines_path, s:tmp_current_path)
endfunction

" 전체 버퍼 헤더 추출 → 임시파일
function! s:BuildAllBuffers() abort
  let lines_hash = []
  let lines_path = []
  let idx = [0]

  for bufnr in range(1, bufnr('$'))
    let ft = getbufvar(bufnr, '&filetype')
    if buflisted(bufnr) && (ft ==# 'markdown' || ft ==# 'webdav')
      call s:ExtractHeaders(bufnr, lines_hash, lines_path, idx)
    endif
  endfor

  call writefile(lines_hash, s:tmp_all_hash)
  call writefile(lines_path, s:tmp_all_path)
endfunction

" fzf 선택 후 이동
function! s:GotoOutline(line) abort
  let parts = split(a:line, "\t")
  let [filename, lnum] = split(parts[1], ':')
  execute 'buffer' filename
  execute lnum
  normal! zv
endfunction

" 마크다운 아웃라인
function! MarkdownOutline() abort
  call s:BuildCurrentBuffer()
  call s:BuildAllBuffers()

  let binds = [
    \ 'ctrl-a:reload(cat ' . s:tmp_all_path . ')+change-prompt(All/> )',
    \ 'ctrl-b:reload(cat ' . s:tmp_current_path . ')+change-prompt(Outline/> )',
    \ 'ctrl-h:reload(cat ' . s:tmp_current_hash . ')+change-prompt(Outline#> )',
    \ 'ctrl-p:reload(cat ' . s:tmp_current_path . ')+change-prompt(Outline/> )',
    \ ]

  call fzf#run(fzf#wrap({
    \ 'source': readfile(s:tmp_current_path),
    \ 'options': [
    \   '--prompt=Outline/> ',
    \   '--no-sort',
    \   '--reverse',
    \   '--delimiter=\t',
    \   '--with-nth=2..',
    \   '--header=^a:all ^b:current | ^h:hash ^p:path',
    \   '--bind', binds[0],
    \   '--bind', binds[1],
    \   '--bind', binds[2],
    \   '--bind', binds[3],
    \ ],
    \ 'sink': function('s:GotoOutline'),
    \ }))
endfunction
