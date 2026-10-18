#!/bin/sh
# Checks that the first line of a commit message follows Conventional Commits.
# The summary may be in English or Japanese.
#
#   feat: add a widget
#   fix(macos): コピーしたコードが残る
set -eu

subject=$(head -n 1 "$1")

case "$subject" in
Merge* | Revert* | "fixup! "* | "squash! "*) exit 0 ;;
esac

if ! printf '%s\n' "$subject" | grep -Eq '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9-]+\))?!?: .+'; then
    echo "The commit message must start with a type, like \"feat: ...\" or \"fix(macos): ...\"." >&2
    echo "Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert" >&2
    echo "Got: $subject" >&2
    exit 1
fi
