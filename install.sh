#!/usr/bin/env bash
# Install every skill and agent in this repo into ~/.claude.
#
# Usage: ./install.sh [--force]
#   --force   overwrite a destination file even if it already exists and differs
#
# By default, a destination file that already exists and differs from the
# source is left alone (skipped) so local edits are never silently clobbered.
# A destination that is a symlink (dangling or not), or that sits under a
# symlinked directory anywhere below $HOME/.claude, is always skipped and
# never written through, even with --force.
set -euo pipefail

# Resolve the directory this script lives in, regardless of cwd or how it was invoked.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
ROOT="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *) echo "install.sh: unknown argument: $arg" >&2; exit 1 ;;
  esac
done

DEST_ROOT="$HOME/.claude"
skills_written=0
agents_written=0
skipped=0

# is_unsafe_path <path>
# True if <path> itself is a symlink, or if any directory between <path>'s
# parent and $DEST_ROOT (inclusive) is a symlink. Writing to such a path
# could escape $HOME through a symlink pointing elsewhere, so it must never
# be written through, with or without --force.
is_unsafe_path() {
  local p="$1"
  if [ -L "$p" ]; then
    return 0
  fi
  local dir
  dir="$(dirname "$p")"
  while [ "$dir" != "/" ]; do
    if [ -L "$dir" ]; then
      return 0
    fi
    if [ "$dir" = "$DEST_ROOT" ]; then
      break
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

# install_file <src> <dest>
# Returns 0 if a file was written, 1 otherwise (skipped for any reason).
install_file() {
  local src="$1" dest="$2"
  if is_unsafe_path "$dest"; then
    echo "skip  $dest (is a symlink, refusing to write through it)"
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ]; then
    if cmp -s "$src" "$dest"; then
      echo "same  $dest"
      return 1
    fi
    if [ "$FORCE" -ne 1 ]; then
      echo "skip  $dest (exists, use --force to overwrite)"
      return 1
    fi
  fi
  cp "$src" "$dest"
  echo "install  $dest"
  return 0
}

shopt -s nullglob
for skill_file in "$ROOT"/skills/*/SKILL.md; do
  name="$(basename "$(dirname "$skill_file")")"
  dest="$DEST_ROOT/skills/$name/SKILL.md"
  if install_file "$skill_file" "$dest"; then
    skills_written=$((skills_written + 1))
  else
    skipped=$((skipped + 1))
  fi
done

for agent_file in "$ROOT"/agents/*.md; do
  name="$(basename "$agent_file")"
  dest="$DEST_ROOT/agents/$name"
  if install_file "$agent_file" "$dest"; then
    agents_written=$((agents_written + 1))
  else
    skipped=$((skipped + 1))
  fi
done
shopt -u nullglob

echo "Installed $skills_written skills and $agents_written agents into $DEST_ROOT"
if [ "$skipped" -gt 0 ]; then
  echo "Skipped $skipped existing files"
fi
