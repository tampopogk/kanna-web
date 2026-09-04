#!/usr/bin/env bash
# Create the git repositories and worktrees that seed.sql refers to.
#
# Kanna reconciles its database against the filesystem on startup: a task whose
# worktree is missing is closed and moved to the done stage. Seeding rows alone
# therefore produces an empty task list. These fixtures give every seeded task a
# real branch and a real worktree so the rows survive.
set -euo pipefail

ROOT="${1:?usage: fixtures.sh <root>}"
mkdir -p "$ROOT"

make_repo () {
  local name="$1"; shift
  local dir="$ROOT/$name"
  rm -rf "$dir"
  mkdir -p "$dir"
  git -C "$dir" init -q -b main
  git -C "$dir" config user.email capture@example.invalid
  git -C "$dir" config user.name "Capture Fixture"
  printf '# %s\n' "$name" > "$dir/README.md"
  git -C "$dir" add -A
  git -C "$dir" commit -q -m "Initial commit"
  for branch in "$@"; do
    git -C "$dir" branch "$branch" >/dev/null 2>&1 || true
    git -C "$dir" worktree add -q ".kanna-worktrees/$branch" "$branch" >/dev/null 2>&1 || true
  done
  echo "$name: $(git -C "$dir" worktree list | wc -l | tr -d ' ') worktrees"
}

make_repo orchard-web \
  task-auth-middleware task-empty-states task-keyboard-nav task-image-pipeline
make_repo orchard-api \
  task-rate-limiting task-webhook-retries task-schema-migration task-flaky-upload
make_repo fieldnotes \
  task-getting-started task-changelog
