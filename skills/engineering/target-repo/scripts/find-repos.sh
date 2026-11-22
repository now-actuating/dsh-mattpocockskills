#!/usr/bin/env bash
# List git repositories up to two levels below a folder (default: the current one).
#
# Usage: find-repos.sh [--show-skipped] [folder]
#
# Prints one tab-separated line per repository: name, relative path, origin URL (may be empty).
# Skips hidden folders, a fixed list of build and backup folders, and whatever the
# folder's own .gitignore ignores. Does not descend into a repository once found.
#
# --show-skipped also prints the repositories found inside skipped folders (still within
# two levels), with a fourth column skipped:<reason>, where <reason> is hidden, the skipped
# folder's name, or gitignore. With this option every other line carries an empty fourth column.
#
# Exits non-zero when the folder cannot be entered or an option is unknown.
set -euo pipefail

show_skipped=0
root="."
while [ $# -gt 0 ]; do
  case "$1" in
    --show-skipped) show_skipped=1 ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "find-repos.sh: unknown option: $1" >&2; exit 2 ;;
    *) root="$1" ;;
  esac
  shift
done
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

# Sets $reason and succeeds when the folder is skipped.
skipped() {
  local name
  name="$(basename "$1")"
  case "$name" in .*) reason=hidden; return 0 ;; esac
  case "$skip_names" in *" $name "*) reason="$name"; return 0 ;; esac
  if ignored "$1"; then reason=gitignore; return 0; fi
  return 1
}

# report <path> [reason]
report() {
  local origin
  origin="$(git -C "$1" remote get-url origin 2>/dev/null || true)"
  if [ "$show_skipped" = 1 ]; then
    printf '%s\t%s\t%s\t%s\n' "$(basename "$1")" "./$1" "$origin" "${2:+skipped:$2}"
  else
    printf '%s\t%s\t%s\n' "$(basename "$1")" "./$1" "$origin"
  fi
}

# Report the repositories at or one level below a skipped first-level folder.
report_skipped_tree() {
  local first="$1" why="$2" second
  if [ -e "$first/.git" ]; then report "$first" "$why"; return; fi
  for second in "$first"/*/ "$first"/.*/; do
    [ -d "$second" ] || continue
    second="${second%/}"
    case "$(basename "$second")" in .|..) continue ;; esac
    [ -L "$second" ] && continue
    [ -e "$second/.git" ] && report "$second" "$why"
  done
  return 0
}

shopt -s nullglob
firsts=(*/)
if [ "$show_skipped" = 1 ]; then
  for hidden in .*/; do
    case "$hidden" in ./|../) continue ;; esac
    firsts+=("$hidden")
  done
fi

for first in "${firsts[@]}"; do
  [ -d "$first" ] || continue
  first="${first%/}"
  [ -L "$first" ] && continue
  if skipped "$first"; then
    [ "$show_skipped" = 1 ] && report_skipped_tree "$first" "$reason"
    continue
  fi
  if [ -e "$first/.git" ]; then
    report "$first"
    continue
  fi
  seconds=("$first"/*/)
  if [ "$show_skipped" = 1 ]; then
    for hidden in "$first"/.*/; do
      case "$(basename "$hidden")" in .|..) continue ;; esac
      seconds+=("$hidden")
    done
  fi
  for second in "${seconds[@]}"; do
    [ -d "$second" ] || continue
    second="${second%/}"
    [ -L "$second" ] && continue
    if skipped "$second"; then
      [ "$show_skipped" = 1 ] && [ -e "$second/.git" ] && report "$second" "$reason"
      continue
    fi
    [ -e "$second/.git" ] && report "$second"
  done
done
