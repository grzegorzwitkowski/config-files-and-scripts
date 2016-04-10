set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

Plugin 'bling/vim-airline'
Plugin 'altercation/vim-colors-solarized'
Plugin 'scrooloose/nerdtree'

call vundle#end()

filetype plugin indent on

set nobackup

if has("gui_running")
  set guifont=Ubuntu\ Mono\ derivative\ Powerline\ 12
  set background=dark
  colorscheme solarized
  set guioptions-=T "remove toolbar
  set lines=40 columns=150
endif

let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled=1
set laststatus=2
let g:airline_theme='molokai'
