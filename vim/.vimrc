set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'scrooloose/nerdtree'
Plugin 'kien/ctrlp.vim'
Plugin 'rust-lang/rust.vim'

call vundle#end()

filetype plugin indent on

set nobackup
set noswapfile
set t_Co=256

if has("gui_running")
  set guifont=Ubuntu\ Mono\ derivative\ Powerline\ 12
  set guioptions-=T "remove toolbar
  set lines=40 columns=150
endif

let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled=1
set laststatus=2
let g:airline_theme='dark'
