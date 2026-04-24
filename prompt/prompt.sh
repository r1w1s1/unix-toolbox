#!/bin/sh
#
# prompt.sh — minimal Unix prompt
#
# Tested on:
#  - Linux (any distro with bash or zsh)
#
# Features:
#  - prints current directory (with ~ replacement)
#  - prints git branch if inside a repo
#  - prints "!" if last command failed
#  - prints "$" or "#" depending on uid
#
# Usage (bash):
#
#   prompt_command() {
#       export PROMPT_STATUS=$?
#   }
#
#   # Safe append — preserves hooks from z, starship, direnv, etc.
#   PROMPT_COMMAND="prompt_command${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
#   PS1='$(~/bin/prompt.sh)'
#
# Requirements:
#  - POSIX sh (dash, bash, ksh)
#  - git(1) in PATH for branch display
#
# Known limitations:
#  - git has no timeout; prompt will hang if git(1) blocks
#    (e.g. on slow NFS mounts or unresponsive network filesystems)
#
# Performance:
#  - uses $PWD instead of pwd         (avoid 1 fork)
#  - caches uid in $PROMPT_UID        (avoid 1 fork per prompt)
#  - git is the only external process (~1 fork total; 0 outside git repos)
#
# Version 0.5:
#  - cache uid in $PROMPT_UID to avoid forking id(1) every prompt
#  - quote $HOME in parameter expansion (safe if HOME has glob chars)
#  - drop redundant 2>/dev/null on status test

VERSION="0.5"

# --- option handling ---
case "$1" in
	-h)
		cat <<'EOF'
prompt.sh - minimal shell prompt generator

Prints one prompt line to stdout and exits. Call it from PS1.

SETUP (bash)

  Add to ~/.bashrc:

      prompt_command() {
          export PROMPT_STATUS=$?
      }
      # Safe append — preserves hooks from z, starship, direnv, etc.
      PROMPT_COMMAND="prompt_command${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
      PS1='$(prompt.sh) '

  Note: use the ${PROMPT_COMMAND:+;$PROMPT_COMMAND} form, not a bare
  PROMPT_COMMAND=prompt_command assignment. The bare form overwrites
  hooks installed by other tools (directory jumpers, prompt helpers,
  shell integrations) and silently breaks them.

SETUP (zsh)

  Add to ~/.zshrc:

      setopt PROMPT_SUBST
      precmd() { export PROMPT_STATUS=$? }
      PS1='$(prompt.sh) '

OPTIONS

  -h    show this help
  -v    show version

REQUIREMENTS

  POSIX sh, git(1) in PATH for branch display.
EOF
		exit 0
		;;
	-v)
		echo "prompt $VERSION"
		exit 0
		;;
	"")
		;;
	*)
		printf 'prompt: unknown option: %s\n' "$1" >&2
		exit 1
		;;
esac

# --- last command status ---
status=0
if [ -n "$PROMPT_STATUS" ]; then
	case "$PROMPT_STATUS" in
		*[!0-9-]*)
			# not a valid integer, ignore
			;;
		*)
			status="$PROMPT_STATUS"
			;;
	esac
fi

# --- current directory ($PWD avoids a fork, pwd is the fallback) ---
cwd=${PWD:-$(pwd)}
if [ -z "$cwd" ]; then
	printf 'prompt: cwd unavailable\n$ ' >&2
	exit 1
fi
# --- first line: path [+ git branch] ---
case "$cwd" in
	"$HOME"|"$HOME"/*)
		printf '~%s' "${cwd#"$HOME"}"
		;;
	*)
		printf '%s' "$cwd"
		;;
esac

# inline git branch check — avoids extra subshell vs a function call
if branch=$(git symbolic-ref --short HEAD 2>/dev/null) && [ -n "$branch" ]; then
	printf ' [%s]\n' "$branch"
else
	echo
fi

# --- prompt symbol (uid is cached; doesn't change mid-session) ---
if [ -z "$PROMPT_UID" ]; then
	PROMPT_UID=$(id -u)
	export PROMPT_UID
fi
if [ "$PROMPT_UID" -eq 0 ]; then
	symbol='#'
else
	symbol='$'
fi

# --- last command failed ---
if [ "$status" -ne 0 ]; then
	printf '%s! ' "$symbol"
else
	printf '%s ' "$symbol"
fi
