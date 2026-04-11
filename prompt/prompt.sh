#!/bin/sh
#
# prompt.sh — minimal Unix prompt
#
# Tested on:
#  - Linux (Slackware)
#  - FreeBSD
#  - OpenBSD
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
#   PROMPT_COMMAND=prompt_command
#   PS1='$(~/.bin/prompt.sh)'
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
#  - uses id -u for portability       (bash users may use $EUID instead)
#  - git is the only external process (~1 fork total; 0 outside git repos)
#
# Version 0.4:
#  - use $PWD instead of pwd subshell
#  - safe cwd fallback: ${PWD:-$(pwd)}
#  - inline git branch check (avoid extra subshell)
#  - use id -u portably (POSIX sh safe)

VERSION="0.4"

# --- option handling ---
case "$1" in
	-h)
		cat <<'EOF'
prompt.sh - minimal shell prompt generator

Prints a shell prompt and exits.

Intended usage (bash):

    prompt_command() {
        export PROMPT_STATUS=$?
    }

    PROMPT_COMMAND=prompt_command
    PS1='$(~/.bin/prompt.sh)'

prompt.sh has no command-line options.
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
		printf '~%s' "${cwd#$HOME}"
		;;
	*)
		printf '%s' "$cwd"
		;;
esac

# inline git branch check — avoids extra subshell vs a function call
if branch=$(git symbolic-ref --short HEAD 2>/dev/null) && [ -n "$branch" ]; then
	printf ' [%s]\n' "$branch"
else
	printf '\n'
fi

# --- prompt symbol (id -u is POSIX; bash users may replace with $EUID) ---
if [ "$(id -u)" -eq 0 ]; then
	symbol='#'
else
	symbol='$'
fi

# --- last command failed ---
if [ "$status" -ne 0 ] 2>/dev/null; then
	printf '%s! ' "$symbol"
else
	printf '%s ' "$symbol"
fi
