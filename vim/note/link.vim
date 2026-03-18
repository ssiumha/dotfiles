" Link handling for markdown notes

" ============================================================
" Helper functions
" ============================================================

" 메뉴 선택 헬퍼: 프롬프트 표시 후 키 입력 반환
function! s:MenuSelect(prompt) abort
  echo a:prompt
  let c = nr2char(getchar())
  redraw
  return c
endfunction

function! s:ReplaceLink(start, end, new_link) abort
  let line = getline('.')
  call setline('.', line[0:a:start-1] . a:new_link . line[a:end:])
endfunction

function! s:BuildWikiLink(target, alias) abort
  return empty(a:alias) ? '[[' . a:target . ']]' : '[[' . a:target . '|' . a:alias . ']]'
endfunction

function! s:BuildMarkdownLink(title, url) abort
  return '[' . a:title . '](' . a:url . ')'
endfunction

" ============================================================
" Link parsing
" ============================================================

function! ParseWikiLink(link)
  if a:link =~# '^id:'
    return {'type': 'anchor', 'id': substitute(a:link, '^id:', '', '')}
  endif
  if a:link =~ '^@'
    return {'type': 'self', 'path': a:link[1:]}
  endif
  if a:link =~# '^\(https\?\|file\)://'
    return {'type': 'external', 'url': a:link}
  endif
  let parts = split(a:link, ':', 1)
  if len(parts) >= 2 && parts[1] =~ '^/'
    return {'type': 'webdav', 'server': parts[0], 'path': join(parts[1:], ':')}
  else
    return {'type': 'local', 'path': a:link}
  endif
endfunction

function! s:ExtractWikilinkFull()
  let [line, col, start] = [getline('.'), col('.') - 1, 0]
  while 1
    let [ms, me] = [match(line, '\[\[', start), match(line, '\]\]', start)]
    if ms == -1 || me == -1 | break | endif
    if col >= ms && col <= me + 1
      let content = line[ms + 2 : me - 1]
      let p = stridx(content, '|')
      return p != -1
        \ ? {'found': 1, 'target': content[:p-1], 'alias': content[p+1:], 'start': ms, 'end': me + 2}
        \ : {'found': 1, 'target': content, 'alias': '', 'start': ms, 'end': me + 2}
    endif
    let start = me + 2
  endwhile
  return {'found': 0}
endfunction

function! s:ExtractMarkdownLinkFull()
  let [line, col, start] = [getline('.'), col('.') - 1, 0]
  while 1
    let ms = match(line, '\[', start)
    if ms == -1 | break | endif
    let be = match(line, '\]', ms)
    if be == -1 | break | endif
    if be + 1 < len(line) && line[be + 1] == '('
      let pe = match(line, ')', be + 2)
      if pe != -1 && col >= ms && col <= pe
        return {'found': 1, 'title': line[ms+1:be-1], 'url': line[be+2:pe-1], 'start': ms, 'end': pe + 1}
      endif
    endif
    let start = be + 1
  endwhile
  return {'found': 0}
endfunction

function! InsertWikilink() abort
  let target = input('Target: ')
  if empty(target) | return | endif
  let alias = input('Alias: ')
  exe 'normal! a' . s:BuildWikiLink(target, alias)
endfunction

function! InsertMarkdownLink() abort
  let url = input('URL: ')
  if empty(url) | return | endif
  let title = input('Title: ', url)
  exe 'normal! a' . s:BuildMarkdownLink(title, url)
endfunction

function! EditLinkAtCursor() abort
  let w = s:ExtractWikilinkFull()
  if w.found
    let t = input('Target: ', w.target)
    if empty(t) | return | endif
    let a = input('Alias: ', w.alias)
    if empty(a) && !empty(w.alias) | return | endif
    call s:ReplaceLink(w.start, w.end, s:BuildWikiLink(t, a))
    return
  endif

  let m = s:ExtractMarkdownLinkFull()
  if m.found
    let u = input('URL: ', m.url)
    if empty(u) | return | endif
    let t = input('Title: ', m.title)
    if empty(t) | return | endif
    call s:ReplaceLink(m.start, m.end, s:BuildMarkdownLink(t, u))
    return
  endif

  echo "No link under cursor"
endfunction

function! InsertLink() abort
  let c = s:MenuSelect("Link: [w]iki [m]arkdown")
  if c ==# 'w' | call InsertWikilink()
  elseif c ==# 'm' | call InsertMarkdownLink()
  endif
endfunction

function! SmartLink() abort
  let wiki = s:ExtractWikilinkFull()
  let md = s:ExtractMarkdownLinkFull()
  let ref = s:ExtractRefLinkFull()

  if wiki.found
    call s:WikiLinkMenu(wiki)
  elseif md.found || ref.found
    call s:LinkActionMenu(md, ref)
  else
    call SmartLinkFzf()
  endif
endfunction

function! s:WikiLinkMenu(wiki) abort
  let c = s:MenuSelect('Wiki: [e]dit [m]arkdown')
  if c ==# 'e'
    call EditLinkAtCursor()
  elseif c ==# 'm'
    call s:WikiToMarkdown(a:wiki)
  endif
endfunction

function! s:WikiToMarkdown(wiki) abort
  let title = !empty(a:wiki.alias) ? a:wiki.alias : a:wiki.target
  let url = a:wiki.target
  if url !~# '^\(https\?\|file\)://' && url !~# '\.[^./]\+$'
    let url .= '.md'
  endif
  call s:ReplaceLink(a:wiki.start, a:wiki.end, s:BuildMarkdownLink(title, url))
  echo 'Wiki → Markdown'
endfunction

function! s:ExtractRefLinkFull() abort
  let line = getline('.')
  let col = col('.') - 1
  let pattern = '\[\([^\]]\+\)\]\[\([^\]]\+\)\]'
  let start = 0
  while 1
    let ms = match(line, pattern, start)
    if ms == -1 | break | endif
    let me = matchend(line, pattern, start)
    if col >= ms && col < me
      let m = matchlist(line, pattern, start)
      let id = m[2]
      let title = m[1]
      " 정의 찾기
      let save_pos = getpos('.')
      call cursor(1, 1)
      let def_line = search('^\s*\[' . escape(id, '[]') . '\]:\s*', 'nW')
      call setpos('.', save_pos)
      let url = ''
      if def_line
        let url = substitute(getline(def_line), '^\s*\[[^\]]\+\]:\s*', '', '')
      endif
      return {'found': 1, 'title': title, 'id': id, 'url': url, 'start': ms, 'end': me}
    endif
    let start = me
  endwhile
  return {'found': 0}
endfunction

function! s:LinkActionMenu(md, ref) abort
  let c = s:MenuSelect('Link: [e]dit [w]iki [r]ef [i]nline [o]pen')
  if c ==# 'e'
    call EditLinkAtCursor()
  elseif c ==# 'w'
    call s:MarkdownToWiki(a:md.found ? a:md : a:ref)
  elseif c ==# 'r' && a:md.found
    call s:ConvertToRefLink(a:md)
  elseif c ==# 'i' && a:ref.found
    call s:ConvertToInlineLink(a:ref)
  elseif c ==# 'o'
    let url = a:md.found ? a:md.url : a:ref.url
    call system('open ' . shellescape(url))
  endif
endfunction

function! s:MarkdownToWiki(link) abort
  let target = substitute(a:link.url, '\.md$', '', '')
  let alias = (a:link.title == a:link.url || a:link.title == target) ? '' : a:link.title
  call s:ReplaceLink(a:link.start, a:link.end, s:BuildWikiLink(target, alias))
  echo 'Markdown → Wiki'
endfunction

function! s:ConvertToRefLink(md) abort
  let id = sha256(a:md.url)[:7]
  call s:ReplaceLink(a:md.start, a:md.end, '[' . a:md.title . '][' . id . ']')
  if !s:RefDefExists(id)
    call s:AppendRefDef(id, a:md.url)
  endif
  echo 'Converted to reference [' . id . ']'
endfunction

function! s:ConvertToInlineLink(ref) abort
  if empty(a:ref.url)
    echo 'Reference definition not found'
    return
  endif
  call s:ReplaceLink(a:ref.start, a:ref.end, s:BuildMarkdownLink(a:ref.title, a:ref.url))
  echo 'Converted to inline link'
endfunction

function! GetMarkdownPagePath()
  " Wiki link [[target]] or [[target|alias]]
  let wiki = s:ExtractWikilinkFull()
  if wiki.found
    return ParseWikiLink(wiki.target)
  endif

  " Markdown link [text](url)
  let md = s:ExtractMarkdownLinkFull()
  if md.found
    return ParseWikiLink(md.url)
  endif

  " Reference link [text][id]
  let ref = s:ExtractRefLinkFull()
  if ref.found && !empty(ref.url)
    return ParseWikiLink(ref.url)
  endif

  " 순수 URL (markdownUrl) - WORD로 직접 추출
  let word = expand('<cWORD>')
  if word =~# '^\(https\?\|slack\|file\)://'
    return ParseWikiLink(word)
  endif

  return {'type': 'none'}
endfunction

" Workspace → Team ID 매핑 (사용자 설정)
if !exists('g:slack_teams')
  let g:slack_teams = {}
endif

" https://xxx.slack.com/archives/CHANNEL/pTIMESTAMP → slack://channel?team=T&id=C&message=TS
function! s:SlackUrlToDeeplink(url) abort
  " URL 파싱: https://WORKSPACE.slack.com/archives/CHANNEL_ID/pTIMESTAMP
  let pattern = 'https://\([^.]\+\)\.slack\.com/archives/\([^/]\+\)/p\(\d\+\)'
  let m = matchlist(a:url, pattern)
  if empty(m)
    return ''
  endif

  let workspace = m[1]
  let channel_id = m[2]
  let ts_raw = m[3]

  " Team ID 조회
  if !has_key(g:slack_teams, workspace)
    echohl ErrorMsg
    echo "Slack workspace '" . workspace . "' not configured."
    echohl None
    echo "Add to vimrc: let g:slack_teams = {'" . workspace . "': 'TXXXXXXX'}"
    echo "Find Team ID: https://app.slack.com/client/TXXXXXXX/..."
    return ''
  endif
  let team_id = g:slack_teams[workspace]

  " 타임스탬프 변환: p1764113743380719 → 1764113743.380719
  let ts = ts_raw[0:9] . '.' . ts_raw[10:]

  return 'slack://channel?team=' . team_id . '&id=' . channel_id . '&message=' . ts
endfunction

function! OpenWiki() abort
  " WebDAV 버퍼면 WebDAV wikilink 핸들러로 위임
  if get(b:, 'webdav_managed', 0)
    call webdav#wikilink#open()
    return
  endif

  let link_info = GetMarkdownPagePath()

  if link_info.type == 'external'
    " Slack URL은 딥링크로 변환 후 앱으로 열기
    if link_info.url =~# 'slack\.com/archives/'
      let deeplink = s:SlackUrlToDeeplink(link_info.url)
      if !empty(deeplink)
        call system('open ' . shellescape(deeplink))
      endif
    else
      call system('open ' . shellescape(link_info.url))
    endif
  elseif link_info.type == 'webdav'
    tabnew
    call webdav#file#get(link_info.path, link_info.server)
  elseif link_info.type == 'self'
    let base = expand('%:p:r')
    let page = base . '/' . link_info.path
    if page !~ '\.[^./]\+$'
      let page .= '.md'
    endif
    execute 'tabe' fnameescape(page)
  elseif link_info.type == 'local'
    let page = link_info.path
    if page !~ '/$'
      if page !~ '\.[^./]\+$'
        let page .= '.md'
      endif
    endif
    let page = page =~# '^\v(/|\~|\w+:)' ? page : expand('%:p:h') . '/' . page
    execute 'tabe' fnameescape(page)
  elseif link_info.type == 'anchor'
    call s:GotoAnchor(link_info.id)
  else
    normal! <CR>
  endif
endfunction

function! s:GotoAnchor(id) abort
  let git_root = trim(system('git rev-parse --show-toplevel 2>/dev/null'))
  let marker_root = NoteRootByMarker(expand('%:p:h'), 'index.md')
  let base_dir = !empty(git_root) ? git_root : (!empty(marker_root) ? marker_root : expand('%:p:h'))

  let pattern = '\[id:: ' . a:id . '\]'
  let cmd = 'grep -rn ' . shellescape(pattern) . ' ' . shellescape(base_dir) . ' --include="*.md"'
  let result = systemlist(cmd)

  if empty(result)
    echo 'Anchor not found: ' . a:id
    return
  endif

  let parts = split(result[0], ':')
  let file = parts[0]
  let line = parts[1]
  execute 'edit +' . line . ' ' . fnameescape(file)
endfunction

let s:link_fzf_mode = 'file'
let s:link_base_dir = ''
let s:link_current_file = ''

function! s:GetLinkFzfSource(base_dir, mode) abort
  if a:mode ==# 'anchor'
    " multiline: id\n  내용\n  파일:라인\0
    let cmd = 'grep -rn "\[id:: [^]]*\]" ' . shellescape(a:base_dir) . ' --include="*.md" 2>/dev/null'
    let cmd .= " | perl -ne '"
    let cmd .= 'if (/^([^:]+):(\d+):(.*)/) {'
    let cmd .= '  my ($f,$l,$c)=($1,$2,$3);'
    let cmd .= '  $f =~ s|.*/||;'
    let cmd .= '  if ($c =~ /\[id:: ([^\]]+)\]/) {'
    let cmd .= '    print "$1\n  $c\n  $f:$l\0";'
    let cmd .= '  }'
    let cmd .= "}'"
    return cmd
  else
    return 'fd -t f -e md --base-directory ' . shellescape(a:base_dir)
  endif
endfunction

function! LocalLinkFzf() abort
  let s:link_fzf_mode = 'file'
  if get(b:, 'webdav_managed', 0)
    call s:RunWebDAVLinkFzf()
  else
    call s:RunLinkFzf()
  endif
endfunction

" ============================================================
" WebDAV Link FZF - PROPFIND 기반 서버 파일 검색
" ============================================================

function! s:RunWebDAVLinkFzf() abort
  let server_name = get(b:, 'webdav_server', '')
  let vault_root = webdav#wikilink#get_vault_root(server_name)
  let base_path = empty(vault_root) ? fnamemodify(get(b:, 'webdav_original_path', '/'), ':h') . '/' : vault_root . '/'

  " PROPFIND 기반, 현재 폴더에서 검색
  let server_info = webdav#server#get_info(server_name)
  let cache_key = webdav#cache#get_key(server_name, server_info.url)
  let scan_cache = webdav#cache#get_data()

  if !has_key(scan_cache, cache_key) || !has_key(scan_cache[cache_key], base_path)
    echo "Scanning..."
    let files = webdav#fzf#scan_recursive(base_path, server_name)
    if !has_key(scan_cache, cache_key)
      let scan_cache[cache_key] = {}
    endif
    let scan_cache[cache_key][base_path] = files
  endif

  let files = get(get(scan_cache, cache_key, {}), base_path, [])
  let md_files = filter(copy(files), 'v:val =~# "\.md$"')

  if empty(md_files)
    echo "No markdown files found"
    return
  endif

  call fzf#run(fzf#wrap({
    \ 'source': md_files,
    \ 'sink*': function('s:HandleWebDAVLinkSelection', [server_name]),
    \ 'options': [
    \   '--prompt', '[[',
    \   '--print-query',
    \   '--expect', 'ctrl-r',
    \   '--header', 'ctrl-r: refresh',
    \ ],
    \ 'down': '40%'
  \ }))
endfunction

function! s:HandleWebDAVLinkSelection(server_name, result) abort
  if len(a:result) < 1 | return | endif

  let query = a:result[0]
  let key = len(a:result) > 1 ? a:result[1] : ''
  let selection = len(a:result) > 2 ? a:result[2] : ''

  " ctrl-r: 캐시 새로고침
  if key ==# 'ctrl-r'
    let server_info = webdav#server#get_info(a:server_name)
    let cache_key = webdav#cache#get_key(a:server_name, server_info.url)
    let scan_cache = webdav#cache#get_data()
    let cur_vault = webdav#wikilink#get_vault_root(a:server_name)
    let cur_base = empty(cur_vault) ? fnamemodify(get(b:, 'webdav_original_path', '/'), ':h') . '/' : cur_vault . '/'
    if has_key(scan_cache, cache_key) && has_key(scan_cache[cache_key], cur_base)
      unlet scan_cache[cache_key][cur_base]
    endif
    call timer_start(10, { -> s:RunWebDAVLinkFzf() })
    return
  endif

  " 파일 선택: [[filename]] 삽입 (확장자 없이 파일명만)
  let link = !empty(selection) ? fnamemodify(selection, ':t:r') : query
  if empty(link) | return | endif

  execute "normal! a[[" . link . "]]"
  startinsert!
endfunction

function! s:RunLinkFzf() abort
  let git_root = trim(system('git rev-parse --show-toplevel 2>/dev/null'))
  let marker_root = NoteRootByMarker(expand('%:p:h'), 'index.md')
  let s:link_base_dir = !empty(git_root) ? git_root : (!empty(marker_root) ? marker_root : expand('%:p:h'))
  let s:link_current_file = expand('%:p')

  let source = s:GetLinkFzfSource(s:link_base_dir, s:link_fzf_mode)
  let prompt = s:link_fzf_mode ==# 'anchor' ? '[[id:' : '[['
  let toggle_hint = s:link_fzf_mode ==# 'file' ? 'anchor' : 'file'
  let header = 'Tab: ' . toggle_hint . ' | ctrl-n: 날짜노트'
  let preview = s:link_fzf_mode ==# 'file' ? ['--preview', 'head -20 {}'] : []
  let anchor_opts = s:link_fzf_mode ==# 'anchor' ? ['--read0', '--gap', '--highlight-line'] : []

  call fzf#run(fzf#wrap({
    \ 'source': source,
    \ 'sink*': function('s:HandleLinkSelection', [s:link_base_dir, s:link_current_file]),
    \ 'options': [
    \   '--prompt', prompt,
    \   '--print-query',
    \   '--expect', 'tab,ctrl-n',
    \   '--header', header,
    \ ] + preview + anchor_opts,
    \ 'down': '40%'
  \ }))
endfunction

function! s:HandleLinkSelection(base_dir, current_file, result) abort
  if len(a:result) < 1 | return | endif

  let query = a:result[0]
  let key = len(a:result) > 1 ? a:result[1] : ''
  let selection = len(a:result) > 2 ? a:result[2] : ''

  " Tab: 모드 전환
  if key ==# 'tab'
    let s:link_fzf_mode = s:link_fzf_mode ==# 'file' ? 'anchor' : 'file'
    call timer_start(10, { -> s:RunLinkFzf() })
    return
  endif

  " ctrl-n: 날짜 노트
  if key ==# 'ctrl-n'
    let path = trim(query)
    if empty(path) | return | endif
    let link = path . '/' . strftime('%Y-%m-%d')
    execute "normal! a[[" . link . "]]"
    startinsert!
    return
  endif

  " anchor 모드: [[id:xxx]] 삽입 (첫 줄이 id)
  if s:link_fzf_mode ==# 'anchor'
    let raw = !empty(selection) ? selection : query
    let id = split(raw, '\n')[0]
    if !empty(id)
      execute "normal! a[[id:" . id . "]]"
      startinsert!
    endif
    return
  endif

  " file 모드: 기존 로직
  if !empty(selection)
    let current_dir = fnamemodify(a:current_file, ':h')
    let target = a:base_dir . '/' . selection
    let relative = NoteRelativePath(target, current_dir)
    let relative = substitute(relative, '\.md$', '', '')
    let link = relative
  else
    let link = query
  endif

  if empty(link) | return | endif

  execute "normal! a[[" . link . "]]"
  startinsert!
endfunction

" ============================================================
" Smart Link FZF - 통합 링크 입력
" ============================================================

let s:link_mode = 'inline'

function! s:GetClipboardUrl() abort
  let clip = getreg('+')
  if clip =~# '^\(https\?\|file\)://'
    return clip
  endif
  return ''
endfunction

function! s:CollectRefDefinitions() abort
  let refs = []
  let lines = getline(1, '$')
  let pattern = '^\[\([^\]]\+\)\]:\s*\(.\+\)$'
  for line in lines
    let m = matchlist(line, pattern)
    if !empty(m)
      call add(refs, {'id': m[1], 'url': m[2]})
    endif
  endfor
  return refs
endfunction

function! s:FindSectionEnd(from_line) abort
  let save_pos = getpos('.')
  call cursor(a:from_line + 1, 1)
  let next_heading = search('^#', 'nW')
  call setpos('.', save_pos)
  if next_heading > 0
    return next_heading - 1
  else
    return line('$')
  endif
endfunction

function! s:RefDefExists(id) abort
  return search('^\[' . a:id . '\]:', 'nw') > 0
endfunction

function! s:AppendRefDef(id, url) abort
  let section_end = s:FindSectionEnd(line('.'))
  let ref_def = '[' . a:id . ']: ' . a:url

  " 섹션 끝에서 거꾸로 올라가며 마지막 reference 정의 찾기
  let insert_line = section_end
  while insert_line > 0
    let line_content = getline(insert_line)
    if line_content =~# '^\[.\+\]:\s'
      " 기존 reference 블록 뒤에 추가
      call append(insert_line, ref_def)
      return
    elseif line_content =~# '^#' || line_content =~# '\S'
      " 헤딩이나 다른 콘텐츠 만나면 중단
      break
    endif
    let insert_line -= 1
  endwhile

  " reference 블록이 없으면 섹션 끝에 새로 추가
  let next_line = getline(section_end + 1)
  if next_line =~# '^#'
    call append(section_end, ['', ref_def])
  else
    call append(section_end, ref_def)
  endif
endfunction

function! SmartLinkFzf() abort
  let source = []
  let clipboard = s:GetClipboardUrl()
  if !empty(clipboard)
    call add(source, clipboard . "\t(clipboard)")
  endif
  for ref in s:CollectRefDefinitions()
    call add(source, ref.url . "\t[" . ref.id . ']')
  endfor

  let header = '^r:' . (s:link_mode == 'ref' ? 'INLINE' : 'REF') . ' ^w:wiki'

  call fzf#run(fzf#wrap({
    \ 'source': source,
    \ 'sink*': function('s:HandleSmartLinkInput'),
    \ 'options': [
    \   '--prompt', '[' . s:link_mode . '] URL> ',
    \   '--print-query',
    \   '--expect', 'ctrl-r,ctrl-w',
    \   '--header', header,
    \   '--delimiter', '\t',
    \   '--with-nth', '1',
    \ ],
    \ 'down': '40%'
  \ }))
endfunction

function! s:HandleSmartLinkInput(result) abort
  if len(a:result) < 1 | return | endif

  let query = a:result[0]
  let key = len(a:result) > 1 ? a:result[1] : ''
  let selection = len(a:result) > 2 ? a:result[2] : ''

  " 모드 전환
  if key ==# 'ctrl-r'
    let s:link_mode = s:link_mode == 'inline' ? 'ref' : 'inline'
    call SmartLinkFzf()
    return
  elseif key ==# 'ctrl-w'
    let s:link_mode = 'wiki'
    call SmartLinkFzf()
    return
  endif

  " URL 추출 (탭 구분자 앞부분)
  let url = !empty(selection) ? split(selection, '\t')[0] : query
  if empty(url) | return | endif

  " Title 입력
  let title = input('Title: ', '')
  if empty(title) | let title = url | endif

  " 모드별 삽입
  if s:link_mode == 'wiki'
    exe 'normal! a[[' . url . ']]'
  elseif s:link_mode == 'ref'
    let id = sha256(url)[:7]
    exe 'normal! a[' . title . '][' . id . ']'
    if !s:RefDefExists(id)
      call s:AppendRefDef(id, url)
    endif
  else " inline
    exe 'normal! a[' . title . '](' . url . ')'
  endif
endfunction

" ============================================================
" URL Transform - FZF 기반 URL 변환
" ============================================================

function! TransformUrlFzf() abort
  " 커서 위치의 WORD 추출
  let url = expand('<cWORD>')
  " 마크다운 링크 괄호 제거: [text](url) → url
  let url = substitute(url, '^.*(\|).*$', '', 'g')

  if url !~# '^\(https\?\)://'
    echo 'No URL under cursor'
    return
  endif

  " 변환 옵션 생성
  let options = s:GetTransformOptions(url)
  if empty(options)
    echo 'No transform available for this URL'
    return
  endif

  " 원본 URL 저장
  let s:transform_url = url

  " FZF로 선택
  let source = []
  for opt in options
    call add(source, opt.name . "\t" . opt.result)
  endfor

  call fzf#run(fzf#wrap({
    \ 'source': source,
    \ 'sink': function('s:ApplyTransform', [options]),
    \ 'options': [
    \   '--prompt', 'Transform> ',
    \   '--delimiter', '\t',
    \   '--with-nth', '1',
    \   '--preview', 'echo {2}',
    \   '--preview-window', 'down:1:wrap',
    \ ],
    \ 'down': '30%'
  \ }))
endfunction

function! s:GetTransformOptions(url) abort
  let options = []

  " Slack URL - 앱으로 열기만 지원 (slack:// 스킴은 메시지 이동 미지원)
  if a:url =~# 'slack\.com/archives/'
    call add(options, {
      \ 'name': 'Open in Slack',
      \ 'result': 'open -a Slack "' . a:url . '"',
      \ 'action': 'open',
      \ 'cmd': 'open -a Slack ' . shellescape(a:url)
    \ })
  endif

  return options
endfunction

function! s:ApplyTransform(options, selected) abort
  let name = split(a:selected, '\t')[0]
  for opt in a:options
    if opt.name == name
      if opt.action == 'replace'
        " URL을 변환된 값으로 치환
        exe 'normal! ciW' . opt.result
      elseif opt.action == 'open'
        call system(opt.cmd)
      endif
      break
    endif
  endfor
endfunction
