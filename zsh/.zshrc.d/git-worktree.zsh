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
	printf '%s\n' "${common_git_dir:A:h}"
}

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
