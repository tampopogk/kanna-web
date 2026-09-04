#!/usr/bin/env bash
# Seed a capture database. Substitutes the fixture root into seed.sql so the
# repository and worktree paths point at the throwaway fixtures.
set -euo pipefail
DB="${1:?usage: seed.sh <db-path> <fixture-root>}"
ROOT="${2:?usage: seed.sh <db-path> <fixture-root>}"
case "$(basename "$DB")" in
  kanna-v2.db) echo "REFUSED: that is the production database." >&2; exit 1 ;;
esac
sed "s#__FIXTURE_ROOT__#${ROOT}#g" "$(dirname "$0")/seed.sql" | sqlite3 "$DB"
echo "seeded $(sqlite3 "$DB" 'select count(*) from repo') repos, $(sqlite3 "$DB" 'select count(*) from pipeline_item') tasks, $(sqlite3 "$DB" 'select count(*) from worktree') worktrees"
