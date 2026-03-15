# >>> ALIASES
alias cdp="cd ~/Programowanie/Projekty/"
# <<< ALIASES

# >>> LOAD EXTRA ZSH CONFIG
if [[ -d "$HOME/.zshrc.d" ]]; then
	for zsh_config in "$HOME"/.zshrc.d/*.zsh(.N); do
		source "$zsh_config"
	done
	unset zsh_config
fi
# <<< LOAD EXTRA ZSH CONFIG
