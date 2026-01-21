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

set cursorcolumn

"set spell spellfile=$HOME/dots/vim/spell/en.utf-8.add
" highlight SpellBad cterm=underline ctermbg=88 gui=underline guibg=#902020 guisp=NvimLightRed

" terminal

if has('nvim')
  set signcolumn=yes
  set scrollback=50000
  set laststatus=3 " global status line
  set cmdheight=0
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

" highlight Folded ctermfg=145 ctermbg=236 gui=italic guifg=#a0a8b0 guibg=#384048
autocmd ColorScheme * highlight Folded cterm=NONE ctermbg=236 ctermfg=145 gui=italic guibg=NONE guifg=#a0a8b0

" highlight FoldColumn cterm=NONE ctermbg=NONE guibg=NONE

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
set dictionary+=$HOME/.firm/dict.txt
iab destory destroy
iab functino function
iab lien line
iab exmaple example

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

Plug 'mileszs/ack.vim', { 'on': ['Ack', 'Ack!'] }
  nnoremap <space>a :Ack!<space>
  let g:ackprg = 'rg --vimgrep --smart-case --color=never'

Plug 'tpope/vim-fugitive', { 'on': ['Git'] }
Plug 'vim-test/vim-test', { 'on': ['TestNearest', 'TestFile', 'TestSuite', 'TestLast'] }

" UI
" TODO: https://github.com/dense-analysis/ale?tab=readme-ov-file#how-can-i-customise-the-statusline
Plug 'itchyny/lightline.vim'
  let g:lightline = {}
  let g:lightline.active = {
        \ 'left': [ [ 'mode', 'paste' ],
        \           [ 'readonly', 'filename', 'modified', 'method' ],
        \           [] ],
        \ 'right': [ [ 'lineinfo' ],
        \            [ 'percent' ],
        \            [ 'fileformat', 'fileencoding', 'filetype' ] ] }
  let g:lightline.inactive = {
        \ 'left':  [ [ 'filename' ] ],
        \ 'right': [ [ 'lineinfo' ],
        \            [ 'percent' ] ] }
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
        \   'filename': 'LightlineFilename',
        \   'treesitter': 'LightlineTreesitter',
        \   'method': 'NearestMethodOrFunction'
        \ }

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
    let root = fnamemodify(get(b:, 'git_dir'), ':h')
    let path = expand('%:p')
    if path[:len(root)-1] ==# root
      return path[len(root)+1:]
    endif
    return expand('%')
  endfunction

  " TODO yaml
  " InspectTree
  " echo nvim_treesitter#statusline({ "type_patterns": ['flow_node'] })

  function! LightlineTreesitter()
    try
      return nvim_treesitter#statusline(100)
    catch
      return ""
    endtry
  endfunction

Plug 'liuchengxu/vista.vim', { 'on': ['Vista', 'Vista!'] }
  " let g:vista_fzf_opts = []
  " let g:vista_fzf_preview = ['right:50%']
  if has('nvim-0.6.0')
    let g:vista_default_executive = 'nvim_lsp'
  endif
  let g:vista_keep_fzf_colors = 1
  nnoremap <space>vv :Vista<cr>
  nnoremap <space>vf :Vista finder<cr>
  " augroup vista
  "   autocmd!
  "   autocmd TabEnter * silent! if &modifiable | Vista | endif
  "   autocmd TabLeave * silent! if &modifiable | Vista! | endif
  " augroup END

Plug 'nanotech/jellybeans.vim'

" Utils
Plug 'kana/vim-metarw' " TODO: webdav

Plug 'tpope/vim-dadbod', { 'on': ['DB'] }
Plug 'kristijanhusak/vim-dadbod-ui', { 'on': ['DBUI', 'DBUIToggle'] }
Plug 'kristijanhusak/vim-dadbod-completion'
  let g:db_ui_table_helpers = {}
  let g:db_ui_table_helpers['postgres'] = {}
  let g:db_ui_table_helpers['postgres']['Show Databases'] = 'SELECT datname FROM pg_database WHERE datistemplate = false;'


Plug 'hrsh7th/vim-vsnip'
  let g:vsnip_snippet_dir = expand('$HOME/dots/vim/snippets')
  let g:vsnip_filetypes = {}
  let g:vsnip_filetypes.typescriptreact = ['typescript']
  imap <C-s> <Plug>(vsnip-expand-or-jump)
  smap <C-s> <Plug>(vsnip-expand-or-jump)

Plug 'powerman/vim-plugin-AnsiEsc'
Plug 'michaeljsmith/vim-indent-object'

Plug 'justinmk/vim-sneak'
  let g:sneak#s_next = 1
  " nmap <m-c-s> <Plug>Sneak_S
  " nmap <c-s> <Plug>Sneak_s

Plug 'jpalardy/vim-slime', { 'on': ['SlimeSend', 'SlimeSend1', '<Plug>SlimeRegionSend', '<Plug>SlimeParagraphSend'] }
  let g:slime_target = 'tmux'
  let g:slime_paste_file = tempname()
  " let g:slime_no_mappings = 1
  func! s:slime_wrapper()
    " TODO C-c wrapper
    " let b:slime_config["socket_name"] = "default"
    " let b:slime_config["target_pane"] = "%1" -> complete fzf
  endfunc

Plug 'junegunn/vim-easy-align'
  xmap <space>ga <Plug>(LiveEasyAlign)
  nmap <space>ga <Plug>(LiveEasyAlign)

"Plug 'rhysd/vim-lsp-ale'
Plug 'dense-analysis/ale'
  let g:ale_linters = {}
  let g:ale_fixers = {}

  let g:ale_enabled = 1
  let g:ale_completion_autoimport = 1
  let g:ale_disable_lsp = 1
  let g:ale_fix_on_save = 1
  let g:ale_lint_on_save = 1
  let g:ale_linters_explicit = 1

  let g:ale_virtualtext = 1
  let g:ale_virtualtext_cursor = 1
  let g:ale_virtualtext_prefix = '>>'

  let g:ale_set_loclist = 0
  let g:ale_set_quickfix = 0
  if has('nvim-0.6.0')
    let g:ale_use_neovim_diagnostics_api = 1
  endif
  " let g:ale_disable_lsp = 'auto'
  " let g:ale_completion_enabled = 1
  " set omnifunc=ale#completion#OmniFunc

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

Plug 'tpope/vim-abolish'
Plug 'AndrewRadev/tagalong.vim' " auto fix matched tag
Plug 'cohama/lexima.vim' " auto close parentheses
  let g:lexima_enable_space_rules = 0

Plug 'wellle/targets.vim' " extend text objects

Plug 'itchyny/vim-qfedit'
Plug 'stefandtw/quickfix-reflector.vim'
  " let g:qf_write_changes = 0
Plug 'thinca/vim-qfreplace'

Plug 'dhruvasagar/vim-table-mode', { 'on': ['TableModeToggle', 'TableModeEnable'] }
  let g:table_mode_always_active = 0
  let g:table_mode_auto_align = 1

Plug 'godlygeek/tabular'

Plug 'mattn/emmet-vim'
  let g:user_emmet_leader_key = '<c-y>'
  let g:user_emmet_install_global = 0
  inoremap <C-y><c-y> <plug>(emmet-expand-abbr)
  autocmd FileType html,css,typescriptreact EmmetInstall

  " TODO
  " let g:user_emmet_settings = {}
  " let g:user_emmet_settings.perl = { 'aliases': { 'req': "require '|'" }, 'snippets': { 'w': "warn \"${cursor}\";" } }

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

Plug 'flazz/vim-colorschemes'
call plug#end()

"----------------
" plug:after
"----------------
colorscheme jellybeans

highlight TreesitterContext guibg=gray ctermbg=8

highlight IndentLevel1 guibg=#ff0000 ctermbg=red
highlight IndentLevel2 guibg=#ffff00 ctermbg=yellow
highlight IndentLevel3 guibg=#ffa500 ctermbg=blue
highlight IndentLevel4 guibg=#00ff00 ctermbg=green
" syntax match IndentLevel1 /^ \{2}/ containedin=ALL
" syntax match IndentLevel2 /^ \{2}\zs \{2}\ze/ containedin=ALL
" syntax match IndentLevel3 /^ \{4}\zs \{2}\ze/ containedin=ALL
" syntax match IndentLevel4 /^ \{6} \{2}/ containedin=ALL contained
" call matchadd('IndentLevel2', "^ ")

autocmd FileType yaml
      \ setlocal nofoldenable foldmethod=expr foldexpr=nvim_treesitter#foldexpr()

if has('nvim-0.7.0')
  lua require 'vimrc'
endif

"----------------
" plug:after ale
"----------------
let g:ale_linters['*'] = ['codespell']

let g:ale_linters['typescript'] = ['biome']
let g:ale_fixers['typescript'] = ['my_biome']

let g:ale_linters['typescriptreact'] = ['biome']
let g:ale_fixers['typescriptreact'] = ['my_biome']

" let g:ale_biome_options = '--no-ignore'
" let g:ale_biome_fixer_apply_unsafe = 1
func! MyAleFixBiome(buffer) abort
    let l:executable = ale#handlers#biome#GetExecutable(a:buffer)
    let l:cmd = printf('%s check --apply %%t', ale#Escape(l:executable))
    return {  'command': l:cmd, 'read_temporary_file': 1 }
endfunc
call ale#fix#registry#Add('my_biome', 'MyAleFixBiome', ['typescript'], 'my custom biome')

let g:ale_linters['sh'] = ['shellcheck']
let g:ale_linters['bash'] = ['shellcheck']

"----------------
" commands
"----------------
func! s:stripAnsiColorCode()
  execute "%!perl -MTerm::ANSIColor=colorstrip -ne 'print colorstrip $_'"
endfunc
command! AnsiStrip :call s:stripAnsiColorCode()

" TODO
inoremap </ </<C-r>=MatchTag()<CR>
function! MatchTag()
  " let l:line = getline('.')
  " let l:before_cursor = strpart(l:line, 0, col('.') - 2) " 현재 줄에서 </ 전까지 텍스트 가져오기
  " let l:match = matchstr(l:before_cursor, '<\zs\w\+\ze[^>]*$') " 열린 태그 찾기
  " return empty(l:match) ? '' : l:match . '>'
  return ""
endfunction

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
