" to remove a set option prepend 'no' to the option
" use VIM config instead of VI
set nocompatible

""""""""""""""""""""""
"			SETS
""""""""""""""""""""""
set number "nu"
set numberwidth=4
set relativenumber "rnu"
set hlsearch "hls"
set ignorecase "ic"
set showcmd
set autoindent "ai"
set tabstop=3
set showmatch
set incsearch
set splitbelow splitright
" :find [file]
set path+=**
" show nice menu on command mode
set wildmenu
" show tabs and spaces
set list
" Nerd Tree
nnoremap <C-n> :NERDTreeToggle<CR>
set listchars=tab:▸\ ,trail:·
colorscheme wellsokai

""""""""""""""""""""""
"			MAPS
""""""""""""""""""""""

" compile
noremap <F9> :!gcc %:t && ./a.out && rm a.out<CR>
" jump to the end of the line
inoremap <C-e> <C-o>a
" remove highlight last search
noremap ,<space> :nohls<CR>
" get changes of the current file
noremap <C-c> :w !diff % -<CR>
" source .vimrc
nnoremap <space>s :w<CR>:source %<CR>:AirlineRefresh<CR>
" enter creater a new line
nnoremap <CR> o<Esc>
" disable arrow keys
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>
" move correctly in wrapped lines
nnoremap j gj
nnoremap k gk
" tab navigation
nnoremap tn :tabnew 
nnoremap tk :tabnext<CR>
nnoremap tj :tabprev<CR>
nnoremap tl :tablast<CR>
nnoremap th :tabfirst<CR>
"split screen navigation
nnoremap hsp :sp 
nnoremap vsp :vs 
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
" multiple cursors feature
nnoremap c* *Ncgn

"""""""""""""""""""""
"			PLUGINS
""""""""""""""""""""""

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

call plug#end()

""""""""""""""""""""""
"			AIRLINE
""""""""""""""""""""""

let g:airline_powerline_fonts = 1
let g:airline_theme='cool'
let g:airline#extensions#whitespace#enabled = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline#extensions#tabline#formatter = 'unique_tail'

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

""""""""""""""""""""""
"			NERD TREE GIT
""""""""""""""""""""""

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
