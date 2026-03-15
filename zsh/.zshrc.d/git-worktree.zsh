## Git worktree helper commands for a bare-repo layout.
##
## Assumptions:
## - The main repository directory is a working area whose .git entry points at
##   a bare repository stored under repo-root/.git.
## - Additional worktrees are created as sibling directories directly under the
##   same repo root.
##
## Commands:
## - gwa <branch>      Add a worktree at repo-root/<sanitized-branch>.
## - gwa -b <branch>   Create a new branch and add its worktree.
## - gwl               List Git worktrees.
## - gwr <name>        Remove a worktree by directory name under the repo root.
## - gwr -f <name>     Force-remove a worktree by directory name.
##
## Examples:
## - gwa feature/login
##     Creates a worktree at repo-root/feature-login for branch feature/login.
## - gwa -b spike/api-cleanup
##     Creates branch spike/api-cleanup and a worktree at repo-root/spike-api-cleanup.
## - gwl
##     Shows the current worktree list from Git.
## - gwr feature-login
##     Removes the sibling worktree directory repo-root/feature-login.
## - gwr -f feature-login
##     Force-removes the sibling worktree directory repo-root/feature-login.

_gw_dir_name() {
	emulate -L zsh
	printf '%s' "$1" | sed -E 's#[^[:alnum:]._-]+#-#g; s#^-+##; s#-+$##'
}

_gw_plain_name() {
	emulate -L zsh
	[[ -n "$1" && "$1" == "${1:t}" && "$1" != "." && "$1" != ".." ]]
}

_gw_repo_root() {
	emulate -L zsh
	local common_git_dir
	common_git_dir=$(git rev-parse --git-common-dir 2>/dev/null) || return 1

	if [[ "${common_git_dir:A:t}" == ".git" ]]; then
		printf '%s\n' "${common_git_dir:A:h}"
	else
		printf '%s\n' "${common_git_dir:A}"
	fi
}

_gw_git_dir() {
	emulate -L zsh
	git rev-parse --git-dir 2>/dev/null
}

_gw_top_level() {
	emulate -L zsh
	git rev-parse --show-toplevel 2>/dev/null
}

_gw_current_ref() {
	emulate -L zsh
	git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null
}

_gw_is_linked_worktree() {
	emulate -L zsh
	local git_dir common_git_dir
	git_dir=$(_gw_git_dir) || return 1
	common_git_dir=$(git rev-parse --git-common-dir 2>/dev/null) || return 1
	[[ "${git_dir:A}" != "${common_git_dir:A}" ]]
}

_gw_current_worktree_name() {
	emulate -L zsh
	local top_level
	_gw_is_linked_worktree || return 1
	top_level=$(_gw_top_level) || return 1
	printf '%s\n' "${top_level:A:t}"
}

_gw_prompt_path_label() {
	emulate -L zsh
	local pwd_abs repo_root repo_name top_abs top_level relative_path

	repo_root=$(_gw_repo_root 2>/dev/null)
	repo_name="${repo_root:t}"

	if _gw_is_linked_worktree; then
		top_level=$(_gw_top_level) || return 1
		pwd_abs=${PWD:A}
		top_abs=${top_level:A}
		if [[ "$pwd_abs" == "$top_abs" ]]; then
			printf '%s\n' "$repo_name"
		else
			relative_path="${pwd_abs#${top_abs}/}"
			printf '%s/%s\n' "$repo_name" "$relative_path"
		fi
		return 0
	fi

	if [[ -n "$repo_name" && -z "$(_gw_top_level 2>/dev/null)" ]]; then
		printf '%s\n' "$repo_name"
		return 0
	fi

	printf '%%1~\n'
}

_gw_prompt_git_info() {
	emulate -L zsh
	local ref worktree_name

	ref=$(_gw_current_ref) || return 1

	if worktree_name=$(_gw_current_worktree_name 2>/dev/null); then
		printf '%%F{blue}git:(%%F{yellow}w[%s] %%F{red}r[%s]%%F{blue})%%f\n' "$worktree_name" "$ref"
		return 0
	fi

	printf '%%F{blue}git:(%%F{red}%s%%F{blue})%%f\n' "$ref"
}

if [[ -o interactive ]]; then
	autoload -Uz add-zsh-hook
	setopt prompt_subst

	typeset -g GW_PROMPT_PATH='%1~'
	typeset -g GW_PROMPT_GIT=''

	_gw_update_prompt_segments() {
		emulate -L zsh
		GW_PROMPT_PATH=$(_gw_prompt_path_label 2>/dev/null || printf '%%1~')
		GW_PROMPT_GIT=$(_gw_prompt_git_info 2>/dev/null || printf '')
	}

	add-zsh-hook precmd _gw_update_prompt_segments
	PROMPT='%B%F{green}➜%f  %F{cyan}${GW_PROMPT_PATH}%f${GW_PROMPT_GIT:+ ${GW_PROMPT_GIT}} %b'
fi

gwa() {
	emulate -L zsh
	local branch repo_root target_path worktree_dir

	if [[ "$1" == "-b" ]]; then
		[[ -n "$2" && -z "$3" ]] || {
			print -u2 -r -- "Usage: gwa <existing-branch> | gwa -b <new-branch>"
			return 1
		}
		branch="$2"
	else
		[[ -n "$1" && -z "$2" ]] || {
			print -u2 -r -- "Usage: gwa <existing-branch> | gwa -b <new-branch>"
			return 1
		}
		branch="$1"
	fi

	repo_root=$(_gw_repo_root) || {
		print -u2 -r -- "gwa: not inside a git repository"
		return 1
	}

	worktree_dir=$(_gw_dir_name "$branch")
	[[ -n "$worktree_dir" ]] || {
		print -u2 -r -- "gwa: branch name cannot be converted to a valid directory name"
		return 1
	}

	target_path="$repo_root/$worktree_dir"

	if [[ "$1" == "-b" ]]; then
		git worktree add -b "$branch" "$target_path"
	else
		git worktree add "$target_path" "$branch"
	fi
}

gwl() {
	git worktree list
}

gwr() {
	emulate -L zsh
	local force_flag="" repo_root target_path worktree_name

	case "$#" in
		1)
			worktree_name="$1"
			;;
		2)
			if [[ "$1" == "-f" && -n "$2" ]]; then
				force_flag="--force"
				worktree_name="$2"
			else
				print -u2 -r -- "Usage: gwr [-f] <worktree-name>"
				return 1
			fi
			;;
		*)
			print -u2 -r -- "Usage: gwr [-f] <worktree-name>"
			return 1
			;;
	esac

	_gw_plain_name "$worktree_name" || {
		print -u2 -r -- "gwr: worktree name must be a plain sibling directory name"
		return 1
	}

	repo_root=$(_gw_repo_root) || {
		print -u2 -r -- "gwr: not inside a git repository"
		return 1
	}

	target_path="$repo_root/$worktree_name"

	git worktree remove $force_flag "$target_path"
}
