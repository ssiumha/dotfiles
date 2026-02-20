let g:neovide_transparency = 0.97
let g:neovide_scale_factor = 1.4

try
  set guifont=JetBrains\ Maple\ Mono:h14
" set guifont=Menlo:h14

catch
endtry

set linespace=2

set nocursorcolumn
set conceallevel=2
set concealcursor=nci
set splitright
color spacemacs-theme

" lightweight
set indentexpr=
set formatoptions-=at formatoptions+=ro
set synmaxcol=500
silent! NoMatchParen
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 1
let g:ale_lint_on_enter = 0
" lightweight end

nnoremap <D-v> "+p
inoremap <D-v> <c-r>+
tnoremap <D-v> <c-r>+
cnoremap <D-v> <c-r>+

let g:slime_target = "vimterminal"
let g:slime_vimterminal_cmd = "/bin/zsh"
let g:slime_vimterminal_config = {"term_finish": "close"}

let s:session_path = '~/.local/vim/neovide_session.vim'
let s:default_dir = '~/org'
let s:default_file = 'index.md'

function! RestoreOrDefault()
  execute 'cd ' . s:default_dir
  silent! execute 'edit ' . s:default_file
endfunction

autocmd VimLeave * mksession! ~/.local/vim/neovide_session.vim
autocmd VimEnter * ++nested if argc() == 0 && !exists("s:std_in") | call RestoreOrDefault() | endif

let g:timeline_perl =<< trim EOF
if (/^@{1,2}(\d{3}-\d{2}-\d{2})\b/) {
  use Time::Piece; use Time::Seconds;
  my $d = int( (Time::Piece->strptime($1,"%Y-%m-%d") - localtime) / ONE_DAY );
  if (s/\s*\(D-?\d+\)\s*:/ " (D-$d):"/e) { }
  else { s/:/ " (D-$d):"/e; }
}
EOF
function! TimelineUpdateVisual() range abort
  let l:first = a:firstline
  let l:last  = a:lastline
  execute l:first . ',' . l:last . '!perl -pe ' . shellescape(g:timeline_perl)
endfunction
xnoremap <silent> <space>td :<C-u>call TimelineUpdateVisual()<CR>

let g:markdown_fenced_languages = [
  \ 'javascript',
  \ 'typescript',
  \ 'python',
  \ 'ruby',
  \ 'bash=sh',
  \ ]

function! InMarkdownCodeSyntax(lnum) abort
  let ids = synstack(a:lnum, 1)
  if empty(ids) | return 0 | endif
  for id in ids
  if synIDattr(id, 'name') ==# 'markdownCodeBlock'
      return 1
    endif
  endfor
  return 0
endfunction

function! MarkdownFoldExpr() abort
  let l = getline(v:lnum)
  if l =~# '^#\+\s'
    return '>' . strlen(matchstr(l, '^#\+'))
  endif
  if l =~# '^\s*\(```\|~~~\)'
    return '='
  endif
  if InMarkdownCodeSyntax(v:lnum)
    return '='
  endif
  return '='
endfunction

runtime note/util.vim
runtime note/link.vim
runtime note/dataview.vim
runtime note/complete.vim
runtime note/outline.vim
runtime note/move.vim
runtime note/bookmark.vim

augroup MyMarkdown
  autocmd!
  autocmd FileType markdown silent! TableModeEnable
  autocmd FileType markdown setlocal comments=b:-,b:*,b:+,n:>
  autocmd FileType markdown setlocal tabstop=2 shiftwidth=2 softtabstop=-1 expandtab
  autocmd FileType markdown setlocal nowrap linebreak breakindent breakindentopt=shift:2
  autocmd FileType markdown setlocal foldmethod=expr foldexpr=MarkdownFoldExpr() foldenable
  autocmd FileType markdown setlocal foldtext=getline(v:foldstart).'...'
  autocmd FileType markdown nnoremap <buffer> <tab> za
  autocmd FileType markdown setlocal formatoptions+=ro
  autocmd FileType markdown inoremap <buffer><expr> <CR>
        \ getline('.') =~# '^\s*[-*+]\s*$' ? '<Esc>S<CR>' : '<CR>'
  " Copilot accept: <C-]> (Tab은 리스트 indent용)
  autocmd FileType markdown imap <buffer><silent><script><expr> <C-]> copilot#Accept("\<CR>")
  autocmd FileType markdown nnoremap <buffer> <cr> :call OpenWiki()<cr>
  autocmd FileType markdown nnoremap <buffer> <c-c><c-l> :call SmartLink()<cr>
  autocmd FileType markdown inoremap <buffer> <C-c><C-l> <C-o>:call SmartLink()<CR>
  autocmd FileType markdown nnoremap <buffer> <c-c><c-p> :call DataviewProperty()<cr>
  autocmd FileType markdown nnoremap <buffer> <c-c><c-o> :call MarkdownOutline()<cr>
  autocmd FileType markdown nnoremap <buffer> <c-c><c-w> :MoveFileFzf<cr>
  autocmd FileType markdown nnoremap <buffer> <c-c><c-t> :call TransformUrlFzf()<cr>
  autocmd FileType markdown nnoremap <buffer> <M-b> :BookmarkPick<cr>

  autocmd FileType markdown nnoremap <buffer> <C-c>. :PickDateAtCursor<CR>
  autocmd FileType markdown inoremap <buffer> <C-c>. <c-o>:PickDateAtCursor<CR>

  autocmd FileType markdown inoremap <buffer> [[ <C-o>:call LocalLinkFzf()<CR>
  autocmd FileType markdown let b:complete_chain = ['NoteComplete', 'SnippetComplete']
  autocmd FileType markdown inoremap <buffer><expr> <C-n> NoteSmartCN()
  autocmd FileType markdown inoremap <buffer><expr> <C-p> NoteSmartCP()

  autocmd FileType markdown noremap <S-Up>    :call TableOrDate('k', 1)<CR>
  autocmd FileType markdown noremap <S-Down>  :call TableOrDate('j', -1)<CR>
  autocmd FileType markdown noremap <S-Left>  :call TableOrDate('h', -1, 'day')<CR>
  autocmd FileType markdown noremap <S-Right> :call TableOrDate('l', 1, 'day')<CR>

  autocmd InsertEnter *.md setlocal foldmethod=manual
  autocmd InsertLeave *.md setlocal foldmethod=expr

  autocmd VimLeavePre *.md mkview
  autocmd FileType markdown silent! loadview

  " autocmd FileType markdown nnoremap <buffer> <leader>fc zM
  " autocmd FileType markdown nnoremap <buffer> <leader>fa zR

  autocmd FileType markdown ++once {
    hi Folded gui=bold guifg=#ff5f00 guibg=NONE
    hi markdownH1 gui=bold guifg=#e6b422
    hi markdownH2 gui=bold guifg=#d75f5f
    hi markdownH3 gui=bold guifg=#5f87d7
    hi markdownH4 gui=NONE guifg=#5faf5f
    hi markdownH5 gui=NONE guifg=#af5fd7
    hi markdownH6 gui=NONE guifg=#aaaaaa
    hi markdownCodeBlock guibg=#1e1e2e
    hi markdownFencedCodeBlock guibg=#1e1e2e
    hi markdownDone guifg=#777777
    hi markdownDelegated guifg=#777777
    hi markdownStrike gui=strikethrough
    hi MyTodo guifg=#000000 guibg=#FFD700 gui=bold
    hi MyDone guifg=#000000 guibg=#98FB98 gui=bold
    hi link markdownWikiLink markdownLinkText
    hi link markdownRefLinkText markdownLinkText
    hi link markdownRefDef Identifier
    hi Conceal guifg=#bc6ec5 guibg=#292b2e
    hi markdownDataviewField guifg=#888888 gui=italic

    hi markdownList1 guifg=#88aaff
    hi markdownList2 guifg=#9cdcfe
    hi markdownList3 guifg=#b5cea8
    hi markdownList4 guifg=#ce9178
    hi markdownList5 guifg=#dcdcaa
    hi markdownList6 guifg=#c586c0
  }

  autocmd Syntax markdown {
    syntax match MyTodo /\<TODO\>/
    syntax match MyDone /\<DONE\>/
    syntax match markdownWikiLink /\[\[.*\]\]/

    syntax match markdownList1 /^- /
    syntax match markdownList2 /^  - /
    syntax match markdownList3 /^    - /
    syntax match markdownList4 /^      - /
    syntax match markdownList5 /^        - /
    syntax match markdownList6 /^          - /

    # markdownDone/Delegated must come AFTER markdownList for priority
    # markdownDoneCheckbox: [x]를 먼저 매치해서 링크로 인식 방지
    # markdownLinkText만 포함 - nextgroup으로 markdownLink 연결됨
    syntax match markdownDoneCheckbox /\[x\]/ contained
    syntax match markdownDelegatedCheckbox /\[>\]/ contained
    syntax match markdownDone /\v^\s*-\s\[x\]\s.*$/ contains=markdownWikiLink,markdownLinkText,markdownRefLinkText,markdownDoneCheckbox
    syntax match markdownDelegated /\v^\s*-\s\[\>\]\s.*$/ contains=markdownStrike,markdownWikiLink,markdownLinkText,markdownRefLinkText,markdownDelegatedCheckbox

    syntax match markdownDataviewField /\[[^\[\]]*::[^\[\]]*\]/ contains=markdownDataviewDelim
    syntax match markdownDataviewDelim /\[\|\]/ contained conceal
  }

  " Inline link: [text](url) → [text]🔗
  autocmd Syntax markdown syntax clear markdownLinkText
  autocmd Syntax markdown syntax match markdownLinkText /\[[^\]]\+\]\ze(/ nextgroup=markdownLink

  autocmd Syntax markdown syntax clear markdownLink
  autocmd Syntax markdown syntax region markdownLink
        \ matchgroup=markdownLinkDelimiter
        \ start="(" end=")"
        \ contains=markdownUrl
        \ conceal keepend contained cchar=🔗

  " Reference link: [text][id] → [text]📎
  " 기본 markdownId가 중복 매치되므로 clear
  autocmd Syntax markdown syntax clear markdownId
  autocmd Syntax markdown syntax match markdownRefLinkText /\[[^\]]\+\]\ze\[/ nextgroup=markdownRefLink
  autocmd Syntax markdown syntax match markdownRefLink /\[[^\]]\+\]/ contained conceal cchar=📎

  " Reference definition: [id]: url?query → [id]: url?…
  autocmd Syntax markdown syntax match markdownRefDefQuery /[?#][^[:space:]]\+/ contained conceal cchar=…
  autocmd Syntax markdown syntax match markdownRefDef /^\[[^\]]\+\]:\s\+\S\+/ contains=markdownRefDefQuery
augroup END
