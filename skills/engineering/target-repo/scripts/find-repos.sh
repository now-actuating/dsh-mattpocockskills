#!/usr/bin/env bash
# List git repositories up to two levels below a folder (default: the current one).
# Prints one tab-separated line per repository: name, relative path, origin URL (may be empty).
# Skips hidden folders, a fixed list of build and backup folders, and whatever the
# folder's own .gitignore ignores. Does not descend into a repository once found.
set -euo pipefail

root="${1:-.}"
cd "$root"

skip_names=" node_modules vendor dist build backups artifacts tmp "

ignored() {
  # Apply ./.gitignore without needing a repository: use a throwaway bare git dir.
  [ -f .gitignore ] || return 1
  if [ -z "${scratch_git:-}" ]; then
    scratch_git="$(mktemp -d)"
    trap 'rm -rf "${scratch_git:?}"' EXIT
    git init -q --bare "$scratch_git"
  fi
  git --git-dir="$scratch_git" --work-tree=. -c core.excludesFile=/dev/null \
    check-ignore -q -- "$1/" 2>/dev/null
}

skipped() {
  local name
  name="$(basename "$1")"
  case "$name" in .*) return 0 ;; esac
  case "$skip_names" in *" $name "*) return 0 ;; esac
  ignored "$1"
}

report() {
  local origin
  origin="$(git -C "$1" remote get-url origin 2>/dev/null || true)"
  printf '%s\t%s\t%s\n' "$(basename "$1")" "./$1" "$origin"
}

for first in */; do
  [ -d "$first" ] || continue
  first="${first%/}"
  [ -L "$first" ] && continue
  skipped "$first" && continue
  if [ -e "$first/.git" ]; then
    report "$first"
    continue
  fi
  for second in "$first"/*/; do
    [ -d "$second" ] || continue
    second="${second%/}"
    [ -L "$second" ] && continue
    skipped "$second" && continue
    [ -e "$second/.git" ] && report "$second"
  done
done
