" vim: ff=unix
scriptencoding utf-8

syntax enable

" set
set hlsearch
set ignorecase smartcase incsearch wrapscan
set gdefault

set clipboard=unnamed,unnamedplus ",autoselect

" key mapping
cnoremap <c-a> <home>
cnoremap <c-e> <end>

inoremap <c-a> <home>
imap <silent><script><expr> <c-e> copilot#Accept("\<End>")
inoremap <c-f> <c-o>w
inoremap <c-b> <c-o>b

inoremap <c-h> <left>
inoremap <c-j> <down>
inoremap <c-k> <up>
inoremap <c-l> <right>

noremap ; :
noremap : ;

noremap j gj
noremap k gk
noremap gj j
noremap gk k

nnoremap Y yg_

noremap <c-h> <c-w>h
noremap <c-j> <c-w>j
noremap <c-k> <c-w>k
noremap <c-l> <c-w>l

vnoremap <silent> y y`]
vnoremap <silent> p p`]
nnoremap <silent> p p`]

nnoremap <esc><esc> :noh<cr>
nnoremap <silent> * :let @/='\<<c-r>=expand("<cword>")<cr>\>'<cr>:set hls<cr>

" key mapping more
nnoremap <space>cd :cd %:p:h<cr>
nnoremap <space>cdr :exe 'cd ' . system('git rev-parse --show-toplevel')<CR>
nnoremap <space>lc :lc %:p:h<cr>

" edit
set tabstop=2 shiftwidth=0 softtabstop=-1
set expandtab shiftround
set backspace=2 "indent,eol,start

set nowrap
set list listchars=tab:\|\ ,trail:-,nbsp:+,extends:>,precedes:<

set timeoutlen=300

set isfname+=\[,\],\(,\)
set iskeyword+=\-,$

set completeopt=menu,menuone,longest
set wildignorecase
"set wildoptions+=fuzzy
set grepprg=rg\ --vimgrep
set grepformat=%f:%l:%c:%m


" terminal

if has('nvim')
  set signcolumn=yes
  set scrollback=50000
  set laststatus=3 " global status line
  set cmdheight=1
endif

"----------------
" variables
"----------------
" netrw
let g:netrw_fastbrowse = 2 " prevent reset cursor. but want refresh, need <c-l>
let g:netrw_keepdir = 1 " disable auto cd
"let g:netrw_liststyle = 3 " tree mode

"----------------
" fold
"----------------

set foldminlines=3
set fillchars=fold:\ ,vert:│
" set foldcolumn=2
" set foldtext=MyFoldText()
" func! MyFoldText()
"   " v:foldlevel
"   return getline(v:foldstart) . ' ... ' . (v:foldend - v:foldstart + 1) . ' lines'
" endfunc

"----------------
" file
"----------------
set undofile undoreload=1000
set backup swapfile
let &undodir = expand('$HOME/.cache/vim/undo')
let &backupdir = expand('$HOME/.cache/vim/backup')
let &directory = expand('$HOME/.cache/vim/swap')

let &viewdir = expand('$HOME/.cache/vim/view')
set viewoptions=folds,cursor

" TODO: UpdateRemotePlugin
" TODO: gem install neovim --bindir ~/.local/bin
" let g:ruby_host_prog = '$HOME/.local/bin/neovim-ruby-host'

set runtimepath^=~/dots/vim
set packpath^=~/dots/vim

"----------------
" complete
"----------------
set dictionary+=$HOME/dots/vim/dict.txt
iab destory destroy
iab functino function
iab lien line
iab exmaple example

function! SnippetComplete(findstart, base) abort
  if a:findstart
    let col = col('.') - 1
    let line = getline('.')
    while col > 0 && line[col-1] =~ '\S'
      let col -= 1
    endwhile
    return col
  endif
  let items = [
    \ {'word': 'today',     'menu': strftime('%Y-%m-%d'),     'user_data': strftime('%Y-%m-%d')},
    \ {'word': 'now',       'menu': strftime('%H:%M'),        'user_data': strftime('%H:%M')},
    \ {'word': 'yesterday', 'menu': strftime('%Y-%m-%d', localtime()-86400), 'user_data': strftime('%Y-%m-%d', localtime()-86400)},
    \ {'word': 'tomorrow',  'menu': strftime('%Y-%m-%d', localtime()+86400), 'user_data': strftime('%Y-%m-%d', localtime()+86400)},
    \ {'word': 'week',      'menu': strftime('%Y-%m-%d', localtime() - (strftime('%w') - 1) * 86400), 'user_data': strftime('%Y-%m-%d', localtime() - (strftime('%w') - 1) * 86400)},
    \ {'word': 'month',     'menu': strftime('%Y-%m'),        'user_data': strftime('%Y-%m')},
    \ {'word': 'year',      'menu': strftime('%Y'),           'user_data': strftime('%Y')},
    \ {'word': 'ts',        'menu': strftime('%Y-%m-%dT%H:%M:%S'), 'user_data': strftime('%Y-%m-%dT%H:%M:%S')},
    \ {'word': 'uuid',      'menu': 'UUID',                   'user_data': trim(system('uuidgen'))},
    \ {'word': 'file',      'menu': expand('%:p'),            'user_data': expand('%:p')},
    \ ]
  return filter(items, 'v:val.word =~ "^" . a:base')
endfunction

autocmd CompleteDone * call s:SnippetReplace()
function! s:SnippetReplace() abort
  let item = v:completed_item
  if empty(item) || !has_key(item, 'user_data') || empty(item.user_data)
    return
  endif
  let word = item.word
  let val = item.user_data
  if word ==# val | return | endif
  let start = col('.') - 1 - len(word)
  let line = getline('.')
  let before = start > 0 ? line[:start - 1] : ''
  let after = line[start + len(word):]
  call setline('.', before . val . after)
  call cursor('.', start + len(val) + 1)
endfunction

function! ChainedComplete(findstart, base) abort
  let chain = get(b:, 'complete_chain', get(g:, 'complete_chain', []))
  if a:findstart
    let s:chain_starts = {}
    let min_start = col('.') - 1
    for name in chain
      try
        let start = function(name)(1, '')
        if start >= 0
          let s:chain_starts[name] = start
          let min_start = min([min_start, start])
        endif
      catch
      endtry
    endfor
    return min_start
  endif
  let line = getline('.')
  let results = []
  for name in chain
    if has_key(s:chain_starts, name)
      let base = line[s:chain_starts[name] : col('.')-2]
      try
        let results += function(name)(0, base)
      catch
      endtry
    endif
  endfor
  return results
endfunction

let g:complete_chain = ['SnippetComplete']
set completefunc=ChainedComplete

"----------------
" plug
"----------------
let s:vim_plug_install_path = expand('$HOME/.vim/autoload/plug.vim')
if !filereadable(s:vim_plug_install_path)
  call system("curl -fLo ".s:vim_plug_install_path." --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim")
endif

call plug#begin(expand('$HOME/.local/vim/plugged'))

Plug 'junegunn/fzf' ", { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
  let $FZF_DEFAULT_COMMAND="fd -tf --hidden --no-ignore-vcs" .
        \ " --follow --exclude 'tmp/' --exclude 'dist/' --exclude '.bundle/' --exclude '.venv/'" .
        \ " --exclude '.expo/'"
  if exists('$FZF_APPEND_COMMAND')
    let $FZF_DEFAULT_COMMAND .= ' ' . $FZF_APPEND_COMMAND
  endif
  let g:fzf_preview_window = ['down,50%,<70(down,40%)', 'ctrl-/']
  if exists('$TMUX')
    let g:fzf_layout = { 'tmux': '90%,70%' }
  endif

  command! Dirs call fzf#run(fzf#wrap({
    \ 'source': 'fd -td',
    \ 'sink': 'tabe'
    \ }))

  function! s:qf_handler(lines) abort
    if len(a:lines) < 2
      return
    endif
    let l:cmd = get({'ctrl-t': 'tabedit', 'ctrl-x': 'split', 'ctrl-v': 'vsplit'}, a:lines[0], 'edit')
    let l:parts = split(a:lines[1], ':')
    execute l:cmd . ' +' . l:parts[1] . ' ' . fnameescape(l:parts[0])
  endfunction

  function! FzfQuickfix() abort
    let l:list = getqflist()
    if empty(l:list)
      echo 'Quickfix list is empty'
      return
    endif
    let l:items = []
    for l:item in l:list
      if l:item.bufnr > 0
        call add(l:items, bufname(l:item.bufnr) . ':' . l:item.lnum . ':' . l:item.text)
      endif
    endfor
    call fzf#run(fzf#wrap({
      \ 'source': l:items,
      \ 'options': ['--prompt', 'Quickfix> '],
      \ 'sink*': function('s:qf_handler')
      \ }))
  endfunction
  command! Cw call FzfQuickfix()


  nnoremap <space>p  <esc>:Files<cr>
  nnoremap <space>pp <esc>:Files<cr>
  nnoremap <space>p1 <esc>:Files %:p:h<cr>
  nnoremap <space>p2 <esc>:Files %:p:h:h<cr>
  nnoremap <space>p3 <esc>:Files %:p:h:h:h<cr>
  nnoremap <space>p4 <esc>:Files %:p:h:h:h:h<cr>
  nnoremap <space>p5 <esc>:Files %:p:h:h:h:h:h<cr>
  nnoremap <space>pd <esc>:Dirs<cr>
  " nnoremap <space>pcd <esc>:GitDirs<cr> TODO: change directory
  nnoremap <space>p[ <esc>:History<cr>
  nnoremap <space>pg <esc>:GitFiles<cr>
  nnoremap <space>pb <esc>:Buffers<cr>
  nnoremap <space>pt <esc>:Tags<cr>
  " nnoremap <space>ps <esc>:Snippets<cr> " TODO: symbol
  nnoremap <space>pc <esc>:Commands<cr>
  nnoremap <space>pj <esc>:Jumps<cr>
  nnoremap <space>pll <esc>:Lines<cr>
  nnoremap <space>plb <esc>:BLines<cr>
  nnoremap <space>pm <esc>:Marks<cr>
  nnoremap <space>pr <esc>:Rg<space>

  nmap <leader><tab> <plug>(fzf-maps-n)

  imap <c-x><c-k> <plug>(fzf-complete-word)
  imap <c-x><c-f> <plug>(fzf-complete-path)
  imap <c-x><c-l> <plug>(fzf-complete-line)

  ":call FzfPick([
  " \ ['Build',     '프로젝트 빌드',       ':make build'],
  " \ ['Open Note', '오늘 노트 열기',     'edit ~/notes/today.md'],
  " \ ['DB Sync',   '개발 DB 동기화',     '!./scripts/db_sync.sh'],
  " \ ['Echo',      'Funcref 테스트',     {-> execute('echo "ok"')}],
  " \ ])
  function! FzfPick(items) abort
    let s:_items = a:items
    let l:src = []
    for l:i in range(len(a:items)-1)
      let l:it = a:items[l:i]
      call add(l:src, printf('%d\t%s\t%s', l:i, get(l:it,0,''), get(l:it,1,'')))
    endfor
    call fzf#run(fzf#wrap({
    \ 'source':  l:src,
    \ 'options': '--delimiter=\t --with-nth=2,3 --nth=2,3 --prompt=Actions❯ ',
    \ 'sink':    function('s:FzfOnSelect'),
    \ }))
  endfunction
  function! s:FzfOnSelect(line) abort
    let l:idx = str2nr(matchstr(a:line, '^\d\+'))
    let l:item = get(s:_items, l:idx, [])
    if empty(l:item) | return | endif
    let l:act = l:item[2]
    if type(l:act) == v:t_func
      call call(l:act, [])
    elseif type(l:act) == v:t_string
      execute (l:act =~# '^:' ? l:act[1:] : l:act)
    endif
  endfunction

Plug 'voldikss/vim-floaterm'
  let g:floaterm_width = 0.95
  let g:floaterm_height = 0.8

  " 기본적으로 stdout을 out -> lambda 함수를 통해 사용 가능
  " FloatermCmd('ls', { out -> setline('.', out) })
  " FloatermCmd('fzf', { out -> append(line('.') - 1, out) })
  " FloatermCmd('fzf', { path -> execute('read ' . path) }, 'filepath')
  " FloatermCmd(printf('$HOME/dots/bin/snip %s %s', &ft, expand('%:p')), { path -> execute('read ' . path) }, 'filepath')
  func! FloatermCmd(cmd, action, return_type='stdout') abort
    try
      let l:tempfile = tempname()
      let [shell, shellslash, shellcmdflag, shellxquote] = floaterm#util#use_sh_or_cmd()

      if type(a:cmd) == type([])
        let l:sourcefile = tempname()
        call writefile(a:cmd, l:sourcefile)
        let newcmd = [&shell, &shellcmdflag, 'source ' . l:sourcefile . ' > ' . l:tempfile]
      else
        let newcmd = [&shell, &shellcmdflag, a:cmd . ' > ' . l:tempfile]
      endif

      " @param job [number] ex) 3
      " @param data [number] ex) 0
      " @param event [string] ex) 'exit'
      " @param opener [string] ex) 'split'
      let jobopts = {}
      let jobopts['on_exit'] = funcref({ job, data, event, opener ->
            \   a:action(a:return_type == 'filepath' ? l:tempfile : readfile(l:tempfile))
            \ })
      let config = {}
      let bufnr = floaterm#terminal#open(-1, newcmd, jobopts, config)
    finally
      let [&shell, &shellslash, &shellcmdflag, &shellxquote] = [shell, shellslash, shellcmdflag, shellxquote]
    endtry
  endfunc

  command! -nargs=* -complete=customlist,floaterm#cmdline#complete -bang -range MySnip
        \ call FloatermCmd(
        \   printf('%s %s %s', expand('$HOME/dots/bin/snip'), &ft, expand('%:p')),
        \   { path -> execute('read ' . path) }, 'filepath')
  nnoremap <space>f <esc>:MySnip<cr>

" Plug 'mileszs/ack.vim', { 'on': ['Ack', 'Ack!'] }  " → :Rg (fzf.vim)
"   let g:ackprg = 'rg --vimgrep --smart-case --color=never'
  nnoremap <silent> <space>a <Cmd>Rg<CR>

Plug 'tpope/vim-fugitive'
Plug 'rbong/vim-flog', { 'on': ['Flog', 'Flogsplit', 'Floggit'] }
  nnoremap <space>gl :Flog -all<cr>
  nnoremap <space>gL :Flog -all -path=%<cr>
Plug 'vim-test/vim-test', { 'on': ['TestNearest', 'TestFile', 'TestSuite', 'TestLast'] }

" UI
Plug 'itchyny/lightline.vim'
  let g:lightline = {}
  let g:lightline.active = {
        \ 'left': [ [ 'mymode', 'paste' ],
        \           [ 'readonly', 'filename', 'modified' ],
        \           [ 'gitbranch' ] ],
        \ 'right': [ [ 'lineinfo' ],
        \            [ 'diagnostics' ],
        \            [ 'filetype' ] ] }
  let g:lightline.inactive = {
        \ 'left':  [ [ 'filename' ] ],
        \ 'right': [ [ 'lineinfo' ] ] }
  let g:lightline.tabline = {
        \ 'left':  [ [ 'tabs' ] ],
        \ 'right': [ [ 'close' ] ] }
  let g:lightline.tab = {
        \ 'active': [ 'tabnum', 'filedir', 'modified' ],
        \ 'inactive': [ 'tabnum', 'filedir', 'modified' ] }
  let g:lightline.tab_component_function = {
        \  'filedir': 'LightlineFiledir',
        \ }
  let g:lightline.component_function = {
        \   'mymode': 'LightlineMode',
        \   'filename': 'LightlineFilename',
        \   'gitbranch': 'LightlineGitbranch',
        \   'diagnostics': 'LightlineDiagnostics',
        \ }

  function! LightlineMode() abort
    let l:m = mode()
    let l:map = { 'n': 'N', 'i': 'I', 'v': 'V', 'V': 'VL', "\<C-v>": 'VB',
          \ 'R': 'R', 's': 'S', 'S': 'SL', "\<C-s>": 'SB',
          \ 'c': 'C', 't': 'T' }
    return get(l:map, l:m, l:m)
  endfunction

  function! LightlineFiledir(n) abort
    let buflist = tabpagebuflist(a:n)
    let winnr = tabpagewinnr(a:n)
    let _ = expand('#'.buflist[winnr - 1].':p:h:t')
    if _ !=# ''
      return _.'/'.expand('#'.buflist[winnr - 1].':t')
    endif
    return '[No Name]'
  endfunction

  function! LightlineFilename()
    let full = expand('%:p')
    let root = fnamemodify(get(b:, 'git_dir'), ':h')
    if full[:len(root)-1] ==# root
      let path = full[len(root)+1:]
    else
      let home = expand('~')
      if full[:len(home)-1] ==# home
        let path = '~' . full[len(home):]
      else
        let path = expand('%:.')
      endif
    endif
    if winwidth(0) < 80
      return pathshorten(path)
    endif
    return path
  endfunction

  function! LightlineGitbranch() abort
    if winwidth(0) < 60 | return '' | endif
    if exists('*FugitiveHead')
      let l:b = FugitiveHead()
      return l:b !=# '' ? l:b : ''
    endif
    return ''
  endfunction

  function! LightlineDiagnostics() abort
    if !has('nvim') | return '' | endif
    let l:n = luaeval('#vim.lsp.get_clients({bufnr=0})')
    if l:n == 0 | return '' | endif
    let l:e = luaeval('#vim.diagnostic.get(0, {severity=vim.diagnostic.severity.ERROR})')
    let l:w = luaeval('#vim.diagnostic.get(0, {severity=vim.diagnostic.severity.WARN})')
    return 'E:' . l:e . ' W:' . l:w
  endfunction


Plug 'nanotech/jellybeans.vim'

" Utils
Plug 'tpope/vim-dadbod', { 'on': ['DB'] }
Plug 'kristijanhusak/vim-dadbod-ui', { 'on': ['DBUI', 'DBUIToggle'] }
Plug 'kristijanhusak/vim-dadbod-completion'
  let g:db_ui_table_helpers = {}
  let g:db_ui_table_helpers['postgres'] = {}
  let g:db_ui_table_helpers['postgres']['Show Databases'] = 'SELECT datname FROM pg_database WHERE datistemplate = false;'

Plug 'powerman/vim-plugin-AnsiEsc'
Plug 'michaeljsmith/vim-indent-object'

Plug 'justinmk/vim-sneak'
  let g:sneak#s_next = 1
  " nmap <m-c-s> <Plug>Sneak_S
  " nmap <c-s> <Plug>Sneak_s

Plug 'jpalardy/vim-slime'
  let g:slime_target = 'tmux'
  let g:slime_paste_file = tempname()
  let g:slime_no_mappings = 1
  function! SlimeSendWithPick() abort
    if !exists('b:slime_config')
      call SlimePickPane()
      return
    endif
    call feedkeys("\<Plug>SlimeParagraphSend", 'm')
  endfunction
  xnoremap <C-c><C-c> <Plug>SlimeRegionSend
  nnoremap <C-c><C-c> :call SlimeSendWithPick()<CR>
  function! SlimePickPane() abort
    let current = trim(system('tmux display-message -p "#{pane_id}"'))
    let fmt = '#{pane_id} #{session_name}:#{window_index}.#{pane_index} [#{pane_current_command}]'
    let panes = systemlist('tmux list-panes -a -F "' . fmt . '"')
    call filter(panes, 'v:val !~# "^" . current')
    let top = []
    let last_tmux = trim(system('tmux display-message -t "{last}" -p "#{pane_id}" 2>/dev/null'))
    if last_tmux != '' && last_tmux != current
      let match = filter(copy(panes), 'v:val =~# "^" . last_tmux')
      if len(match)
        let top += map(match, 'v:val . " [last]"')
        call filter(panes, 'v:val !~# "^" . last_tmux')
      endif
    endif
    let slime_prev = get(get(b:, 'slime_config', {}), 'target_pane', '')
    if slime_prev != '' && slime_prev != last_tmux
      let match = filter(copy(panes), 'v:val =~# "^" . slime_prev')
      if len(match)
        let top += map(match, 'v:val . " [prev]"')
        call filter(panes, 'v:val !~# "^" . slime_prev')
      endif
    endif
    call fzf#run(fzf#wrap({
      \ 'source': top + panes,
      \ 'options': ['--prompt', 'Slime> ', '--preview', 'tmux capture-pane -t {1} -p -S -20', '--preview-window', 'right:50%'],
      \ 'sink': function('s:slime_pick_sink'),
      \ }))
  endfunction
  function! s:slime_pick_sink(line) abort
    let pane_id = split(a:line)[0]
    let b:slime_config = {'socket_name': 'default', 'target_pane': pane_id}
    echo 'Slime target: ' . pane_id
  endfunction
  command! SlimePickPane call SlimePickPane()

Plug 'junegunn/vim-easy-align'
  xmap <space>ga <Plug>(LiveEasyAlign)
  nmap <space>ga <Plug>(LiveEasyAlign)

" Plug 'dense-analysis/ale'  " → conform.nvim + LSP (vimrc.lua)

" TODO
" Plug 'tpope/vim-endwise'

" Edit
Plug 'Konfekt/FastFold'
  let g:fastfold_savehook = 1
  " let g:fastfold_include_filetypes = ['markdown'] " default is all

Plug 'tpope/vim-commentary'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
  let g:surround_40 = "(\r)"
  let g:surround_91 = "[\r]"

Plug 'tpope/vim-vinegar'
Plug 'tpope/vim-abolish'
Plug 'AndrewRadev/tagalong.vim' " auto fix matched tag
Plug 'cohama/lexima.vim' " auto close parentheses
  let g:lexima_enable_space_rules = 0

Plug 'wellle/targets.vim' " extend text objects

Plug 'itchyny/vim-qfedit'
Plug 'stefandtw/quickfix-reflector.vim'
  " let g:qf_write_changes = 0
Plug 'thinca/vim-qfreplace'

Plug 'dhruvasagar/vim-table-mode'
  let g:table_mode_always_active = 0
  let g:table_mode_auto_align = 1
  let g:table_mode_corner = '|'
Plug 'junegunn/vim-easy-align'
  xmap ga <Plug>(EasyAlign)
  nmap ga <Plug>(EasyAlign)
" Plug 'godlygeek/tabular' " → vim-easy-align (ga operator)

" Plug 'mattn/emmet-vim'  " → emmet_language_server (vimrc.lua)
"   let g:user_emmet_leader_key = '<c-y>'
"   let g:user_emmet_install_global = 0
"   inoremap <C-y><c-y> <plug>(emmet-expand-abbr)
"   autocmd FileType html,css,typescriptreact EmmetInstall

" Lang
Plug 'tpope/vim-rails', { 'for': 'ruby' }
Plug 'hashivim/vim-terraform', { 'for': 'terraform' }
Plug 'elixir-editors/vim-elixir', { 'for': 'elixir' }
Plug 'NoahTheDuke/vim-just', { 'for': 'just' }
Plug 'diepm/vim-rest-console', { 'for': 'rest' }
  let g:vrc_include_response_header = 1
  let g:vrc_response_default_content_type = 'application/json'
  let g:vrc_show_command = 1
  let g:vrc_curl_opts = { '-s': '' }
  let g:vrc_debug = 0
  let g:vrc_auto_format_response_patterns = {
        \   'json': 'jq',
        \}

" Plug 'augmentcode/augment.vim'
Plug 'github/copilot.vim'
  let g:copilot_filetypes = {
        \ '*': v:true,
        \ }
  " let g:copilot_no_tab_map = v:true
  " imap <silent><script><expr> <tab> copilot#Accept("\<CR>")
call plug#end()

"----------------
" plug:after
"----------------
colorscheme jellybeans

" foldexpr is set globally via vim.treesitter.foldexpr() in vimrc.lua
autocmd FileType yaml setlocal nofoldenable
autocmd FileType json,yaml nnoremap <buffer> ) :call search('^'.matchstr(getline('.'),'^\s*').'\S','W')<CR>
autocmd FileType json,yaml nnoremap <buffer> ( :call search('^'.matchstr(getline('.'),'^\s*').'\S','bW')<CR>

if has('nvim-0.7.0')
  lua require 'vimrc'
endif

" ALE removed → conform.nvim + LSP diagnostics (vimrc.lua)

"----------------
" commands
"----------------
func! s:stripAnsiColorCode()
  execute "%!perl -MTerm::ANSIColor=colorstrip -ne 'print colorstrip $_'"
endfunc
command! AnsiStrip :call s:stripAnsiColorCode()

"----------------
" note
"----------------
" Require: $WEBDAV_UI_DEV, $WEBDAV_UI_DAILY, $WEBDAV_UI_MONTHLY
let g:webdav_note_patterns = {}
let g:webdav_note_patterns.daily = {
  \ 'server': 'daily',
  \ 'path': '/%Y-%m/%Y-%m-%d.md',
  \ 'template': '',
  \ 'unit': 'day'
  \ }

let g:webdav_note_patterns.monthly = {
  \ 'server': 'monthly',
  \ 'path': '/%Y-%m.md',
  \ 'template': '',
  \ 'unit': 'month'
  \ }

let g:webdav_note_patterns.fleeting = {
  \ 'server': 'fleeting',
  \ 'path': '/{title}.md',
  \ 'template': '',
  \ 'unit': 'day',
  \ 'prompt_title': '%y%m%d '
  \ }

nnoremap <space>ou :WebDAVUIFzf<CR>
nnoremap <space>od :WebDAVNote daily<CR>
nnoremap <space>om :WebDAVNote monthly<CR>
nnoremap <space>of :WebDAVNote fleeting<CR>
nnoremap <space>or :WebDAVFzf dev<CR>

"----------------
" methods
"----------------
func! s:removeTrailingWhitespace()
  let [l:old_search, l:stay_view] = [@/, winsaveview()]

  if &filetype != 'diff'
    silent! execute '%s;\s\+$;;e'
  endif

  call winrestview(l:stay_view)
  let @/ = l:old_search
endfunc
command! TraillingWhitespace :call s:removeTrailingWhitespace()

command! EchoSyntax
      \ for id in synstack(line('.'), col('.'))
      \| echomsg synIDattr(id, 'name')
      \| endfor

func! s:ensureParentDirectory()
  let l:dir = expand('<afile>:p:h')
  if !isdirectory(l:dir)
    call mkdir(l:dir, 'p')
  endif
endfunc

func! s:moveCursorToLastPosition()
  if line("'\"") > 0 && line("'\"") <= line('$')
    execute 'norm! g`"zvzz'
  endif
endfunc

augroup filetype_all
  autocmd!

  autocmd BufWritePre * :call s:removeTrailingWhitespace()
  autocmd BufWritePre * :call s:ensureParentDirectory()
  autocmd BufReadPost * :call s:moveCursorToLastPosition()

  autocmd StdinReadPost * :AnsiEsc
  autocmd StdinReadPost * setlocal nowrap buftype=nofile

  autocmd FileType qf nnoremap <buffer> q :cclose<cr>
  autocmd FileType qf nnoremap <buffer> t 0:tabe <cfile><cr>:copen<cr>

  autocmd CursorHold,FocusGained * checktime
augroup END

"----------------
" variant
"----------------
if has('ide') "ideavimrc
  set noexpandtab

  inoremap <c-p> <c-o>:action CodeCompletion<cr>
  inoremap <c-n> <c-o>:action CodeCompletion<cr>

  nnoremap <space>r :action RunClass<cr>
endif

if exists('g:neovide')
  source ~/dots/vim/note.vim
endif

if has('gui_macvim')
  set guifont=Menlo:h17
  set nospell nowrap concealcursor=

  let &undodir = expand('$HOME/.cache/macvim/undo')
  let &backupdir = expand('$HOME/.cache/macvim/backup')
  let &directory = expand('$HOME/.cache/macvim/swap')
  for s:d in [&undodir, &backupdir, &directory]
    if !isdirectory(s:d) | call mkdir(s:d, 'p') | endif
  endfor

  source ~/dots/vim/note.vim
  " autocmd VimEnter * if argc() == 0
  "       \| exe 'cd ~/docs' | edit index.md
  "       \| endif

  " :h macvim-prefs
  "
  "   MMLoginShellArgument =
  "   defaults read org.vim.MacVim
  "   defaults write org.vim.MacVim MMTranslateCtrlClick 0
  "   defaults delete org.vim.MacVim
  "
  " let &shellcmdflag=-l\ -c
  " not working MISE_CACHE_PATH
endif
