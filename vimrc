" Plugins
call plug#begin('~/.vim/plugged')
Plug 'scrooloose/nerdtree'
Plug 'editorconfig/editorconfig-vim'
Plug 'airblade/vim-gitgutter'
Plug 'rakr/vim-one'
Plug 'qpkorr/vim-bufkill'
Plug 'mileszs/ack.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'joukevandermaas/vim-ember-hbs'
Plug 'pangloss/vim-javascript'
Plug 'Shutnik/jshint2.vim'
Plug 'mattn/emmet-vim'
call plug#end()

set mouse=a " Enable mouse in all modes
set updatetime=250 " Faster update time for gitgutter
set number " Show line numbers always
set hidden " Allow switching away from modified buffers
set confirm " have vim prompt for saving modified buffers
set wildchar=<Tab> wildmenu wildmode=full " nicer wildcard mode
set scrolloff=5 " atleast 5 lines above the edges 
set autoindent
set fillchars=vert:│

" colorization settings
if (has("termguicolors")) " enable true color
    set termguicolors
endif

set background=light
let g:one_allow_italics=1
colorscheme one

" Override the existing One color scheme for status bars, I prefer dark to
" signify that it's active
hi StatusLine guibg=#5c6370 guifg=#cccccc 
hi StatusLineNC guibg=#494b53 guifg=#f0f0f0
" better background color for search and replace
hi IncSearch guifg=#c7cdeb 

" Highlight more characters then the default
set list lcs=eol:$,tab:→∙,space:▫︎
set list!

" Get those damn vim files into their own place
set directory=$HOME/.vim/swapfiles//
set backupdir=$HOME/.vim/backups//
set undodir=$HOME/.vim/undos//

" use relative numbers for easier movement
set relativenumber

" Switch windows with ctrl + hjkl
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

" LEADER SETTINGS
let mapleader = "\<Space>"

nnoremap <Leader>o :CtrlP<CR>
nnoremap <Leader>b :CtrlPBuffer<CR>
nnoremap <Leader>w :w<CR>
" Use jj instead of ESC 
inoremap jj <ESC>

" REGEX/SEARCH SETTINGS
" use perl style regexs everywhere
nnoremap / /\v
vnoremap / /\v

" DISABLE ARROW KEYS
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

" Use persistent undo
set undofile

" JSHINT settingss
let jshint2_read = 1
let jshint2_save = 1

autocmd FileType javascript,perl autocmd BufWritePre <buffer> %s/\s\+$//e

" CTRLP custmizations
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']

" Emmet settings
let g:user_emmet_settings = {'html':{'quote_char': "'",},}
