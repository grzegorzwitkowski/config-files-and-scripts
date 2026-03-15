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


typeset -g GW_PROMPT_LAST_PWD=''
typeset -g GW_PROMPT_REPO_ROOT=''
typeset -g GW_PROMPT_TOP_LEVEL=''
typeset -g GW_PROMPT_WORKTREE_NAME=''
typeset -g GW_PROMPT_IS_LINKED=0

_gw_refresh_prompt_context() {
	emulate -L zsh
	local git_dir common_git_dir repo_root repo_output top_level
	local -a repo_lines

	GW_PROMPT_LAST_PWD=${PWD:A}
	GW_PROMPT_REPO_ROOT=''
	GW_PROMPT_TOP_LEVEL=''
	GW_PROMPT_WORKTREE_NAME=''
	GW_PROMPT_IS_LINKED=0

	repo_output=$(git rev-parse --path-format=absolute --git-dir --git-common-dir 2>/dev/null) || return 1
	repo_lines=("${(@f)repo_output}")
	git_dir="$repo_lines[1]"
	common_git_dir="$repo_lines[2]"

	if [[ -z "$git_dir" || -z "$common_git_dir" ]]; then
		return 1
	fi

	if [[ "${common_git_dir:t}" == ".git" ]]; then
		repo_root="${common_git_dir:h}"
	else
		repo_root="$common_git_dir"
	fi

	GW_PROMPT_REPO_ROOT="$repo_root"

	if [[ "$git_dir" != "$common_git_dir" ]]; then
		GW_PROMPT_IS_LINKED=1
	fi

	top_level=$(git rev-parse --path-format=absolute --show-toplevel 2>/dev/null) || top_level=''
	GW_PROMPT_TOP_LEVEL="$top_level"

	if (( GW_PROMPT_IS_LINKED )) && [[ -n "$top_level" ]]; then
		GW_PROMPT_WORKTREE_NAME="${top_level:t}"
	fi
}

_gw_update_prompt_path() {
	emulate -L zsh
	local pwd_abs relative_path repo_name top_abs

	repo_name="${GW_PROMPT_REPO_ROOT:t}"

	if [[ -z "$repo_name" ]]; then
		GW_PROMPT_PATH='%1~'
		return 0
	fi

	if (( GW_PROMPT_IS_LINKED )) && [[ -n "$GW_PROMPT_TOP_LEVEL" ]]; then
		pwd_abs=${PWD:A}
		top_abs="$GW_PROMPT_TOP_LEVEL"
		if [[ "$pwd_abs" == "$top_abs" ]]; then
			GW_PROMPT_PATH="$repo_name"
		else
			relative_path="${pwd_abs#${top_abs}/}"
			GW_PROMPT_PATH="$repo_name/$relative_path"
		fi
		return 0
	fi

	if [[ -z "$GW_PROMPT_TOP_LEVEL" ]]; then
		GW_PROMPT_PATH="$repo_name"
		return 0
	fi

	GW_PROMPT_PATH='%1~'
}

_gw_update_prompt_git() {
	emulate -L zsh
	local ref

	if [[ -z "$GW_PROMPT_REPO_ROOT" ]]; then
		GW_PROMPT_GIT=''
		return 0
	fi

	ref=$(_gw_current_ref 2>/dev/null) || {
		GW_PROMPT_GIT=''
		return 0
	}

	if [[ -n "$GW_PROMPT_WORKTREE_NAME" ]]; then
		GW_PROMPT_GIT=$(printf '%%F{blue}git:(%%F{yellow}w[%s] %%F{red}r[%s]%%F{blue})%%f' "$GW_PROMPT_WORKTREE_NAME" "$ref")
		return 0
	fi

	GW_PROMPT_GIT=$(printf '%%F{blue}git:(%%F{red}%s%%F{blue})%%f' "$ref")
}

if [[ -o interactive ]]; then
	autoload -Uz add-zsh-hook
	setopt prompt_subst

	typeset -g GW_PROMPT_PATH='%1~'
	typeset -g GW_PROMPT_GIT=''

	_gw_update_prompt_directory_state() {
		emulate -L zsh
		_gw_refresh_prompt_context 2>/dev/null || true
		_gw_update_prompt_path
	}

	_gw_update_prompt_segments() {
		emulate -L zsh
		if [[ "$GW_PROMPT_LAST_PWD" != "${PWD:A}" ]]; then
			_gw_update_prompt_directory_state
		fi
		_gw_update_prompt_git
	}

	add-zsh-hook chpwd _gw_update_prompt_directory_state
	add-zsh-hook precmd _gw_update_prompt_segments
	PROMPT='%B%F{green}➜%f %F{cyan}${GW_PROMPT_PATH}%f${GW_PROMPT_GIT:+ ${GW_PROMPT_GIT}} %b'
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
