" to remove a set option prepend 'no' to the option
" use VIM config instead of VI
set nocompatible
syntax on
filetype plugin on
let mapleader = " "
colorscheme wellsokai

" ========== SETS
set number "nu
set numberwidth=4
set relativenumber "rnu
set hlsearch "hls
set ignorecase "ic
set showcmd
set autoindent "ai
" tab config
set tabstop=3
set shiftwidth=0
" don't make tabs turn to spaces
set noexpandtab
set softtabstop=0
set showmatch
set incsearch
set splitbelow splitright
" :find [file]
set path+=**
" show nice menu on command mode
set wildmenu
" show tabs and spaces
set list
set listchars=tab:▸\ ,trail:•
" complete
set omnifunc=syntaxcomplete#Complete
set completeopt=menu,longest
set complete=.,w,b,u,t,i
set foldmethod=syntax
set nofoldenable
set foldlevel=2
" remove esc delay
set timeoutlen=1000 ttimeoutlen=0
set backspace=indent,eol,start
set backspace=2
set tags=tags;

" ========== HIGHLIGHTS
hi Pmenu ctermfg=white ctermbg=darkgrey
hi Pmenusel ctermfg=black ctermbg=white
hi CursorLine ctermfg=white ctermbg=darkred
hi SpecialKey ctermfg=darkgrey

" ========== MAPS
" compile C
noremap <F9> :w<CR>:!gcc % -lm && time ./a.out && rm a.out<CR>
" compile C++
noremap <F10> :w<CR>:!g++ % && time ./a.out && rm a.out<CR>
" jump to the end of the line
inoremap <C-c> <C-o>a
" remove highlight last search
noremap ,<leader> :nohls<CR>
" get changes of the current file
noremap <leader>c :w !diff % -<CR>
" source .vimrc
nnoremap <leader>r :w<CR>:source %<CR>:AirlineRefresh<CR>:nohls<CR>
" disable arrow keys
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>
" move correctly in wrapped lines
nnoremap j gj
nnoremap k gk
" tab navigation
nnoremap tn :tabnew<Space>
nnoremap tk :tabnext<CR>
nnoremap tj :tabprev<CR>
nnoremap tl :tablast<CR>
nnoremap th :tabfirst<CR>
"split screen navigation
nnoremap gh :sp<Space>
nnoremap gv :vs<Space>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
" multiple cursors feature
nnoremap c* *Ncgn
" save and exit
nnoremap <leader>s :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>Q :q!<CR>
" open .vimrc
nnoremap <leader>vv :e ~/.vimrc<CR>
nnoremap <leader>vt :tabnew ~/.vimrc<CR>
" preview markdown
nnoremap <leader>md :InstantMarkdownPreview<CR>
nnoremap <leader>ue :UltiSnipsEdit<CR>
nnoremap <leader>x :!clear<CR><CR>
" nnoremap <leader>. :CtrlPTag<CR>
nnoremap <leader><leader> za
nnoremap <silent> <C-t> :TagbarToggle<CR>
nnoremap <leader>. :bn<CR>
nnoremap <leader>, :bp<CR>
nnoremap <leader>d :windo difft<CR>:windo set wrap<CR>
nnoremap <leader>D :windo diffo<CR>

" ========== PLUGINS
call plug#begin()

Plug 'flazz/vim-colorschemes'
Plug 'jiangmiao/auto-pairs'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-surround'
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'tpope/vim-commentary'
Plug 'vimwiki/vimwiki'
Plug 'suan/vim-instant-markdown'
Plug 'christoomey/vim-system-copy'
Plug 'wincent/scalpel'
Plug 'sirver/ultisnips'
Plug 'honza/vim-snippets'
Plug 'ervandew/supertab'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'majutsushi/tagbar'
Plug 'tpope/vim-repeat'
Plug 'flrnprz/plastic.vim'
" Plug 'ludovicchabant/vim-gutentags'
" Plug 'valloric/youcompleteme'
" Plug 'scrooloose/syntastic'
" Plug 'terryma/vim-multiple-cursors'
" Plug 'mattn/emmet-vim'
" Plug 'christoomey/vim-sort-motion'
" Plug 'christoomey/vim-titlecase'
" Plug 'matze/vim-move'

call plug#end()

" ========== AIRLINE
let g:airline_powerline_fonts = 1
let g:airline_theme='cool'
let g:airline#extensions#whitespace#enabled = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline#extensions#tabline#formatter = 'unique_tail'
" function
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
" unicode symbols
let g:airline_left_sep = '>>'
"let g:airline_left_sep = '▶'
let g:airline_right_sep = '<<'
"let g:airline_right_sep = '◀'
let g:airline_symbols.crypt = '🔒'
let g:airline_symbols.linenr = '☰'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.maxlinenr = '㏑'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.spell = 'Ꞩ'
let g:airline_symbols.notexists = 'Ɇ'
let g:airline_symbols.whitespace = 'Ξ'
" powerline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = '☰'
let g:airline_symbols.maxlinenr = '㏑'

" ========== NERD TREE
nnoremap <C-n> :NERDTreeToggle<CR>
let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ 'Ignored'   : '☒',
    \ "Unknown"   : "?"
    \ }

" ========== GIT GUTTER
set updatetime=100

" ========== VIM INSTANT MARKDOWN
let g:instant_markdown_autostart = 0

" ========== VIM WIKI
let index = {}
let index.path = '~/notes/vimwiki/'
let index.syntax = 'markdown'
let index.ext = '.md'

let local_notes = {}
let local_notes.path = '~/notes/local/'
let local_notes.syntax = 'markdown'
let local_notes.ext = '.md'

let g:vimwiki_list = [index, local_notes]
let g:vimwiki_ext2syntax = {'.wiki': 'default', '.md': 'markdown', '.markdown': 'markdown', '.mdown': 'markdown'}
" don't use wiki syntax on other .md files
" let g:vimwiki_global_ext = 0

" ========== UTILSNIPS
let g:UltiSnipsExpandTrigger='<tab>'
let g:UltiSnipsJumpForwardTrigger='<tab>'
let g:UltiSnipsJumpBackwardTrigger='<S-tab>'
let g:UltiSnipsEditSplit="vertical"
let g:UltiSnipsSnippetsDir='~/.vim/plugged/vim-snippets/UltiSnips/'

" ========== SUPERTAB
" let g:SuperTabDefaultCompletionType = '<C-x><C-n>'
let g:SuperTabDefaultCompletionType = 'context'

" ========== YCM
" let g:ycm_key_list_select_completion = ['<C-j>', '<Down>']
" let g:ycm_key_list_previous_completion = ['<C-k>', '<Up>']
" let g:ycm_key_list_accept_completion = ['<C-y>']

" ========== VIM MOVE
" execute 'set <A-j>=\ej'
" execute 'set <A-k>=\ek'
" let g:move_key_modifier = 'A'

" ========== SYNTASTIC
" set statusline+=%#warningmsg#
" set statusline+=%{SyntasticStatuslineFlag()}
" set statusline+=%*
" let g:syntastic_always_populate_loc_list = 1
" let g:syntastic_auto_loc_list = 1
" let g:syntastic_check_on_open = 1
" let g:syntastic_check_on_wq = 0
