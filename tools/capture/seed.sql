-- Seed data for kanna-web marketing captures.
--
-- This is deliberately NOT the kanna repo's e2e seed. That seed names its
-- repositories example-app / example-api / example-docs under /Users/test,
-- and repository names are the most prominent text in the Kanna sidebar, so
-- those captures would put the word "example" in front of every visitor.
--
-- Everything visible here becomes public copy on the homepage. The rules:
--   * plausible project and task names, of the shape real engineering work has
--   * nothing that names or implies a real company, customer, or third party
--   * no private repository names and no real in-flight work
--   * paths under ~/code, not /Users/test
--
-- INSERT-only on purpose: run it against a database the app has already
-- created, so the schema always matches the shipped app rather than a copy
-- of it that can drift. See README.md for the order of operations.

PRAGMA foreign_keys = ON;

DELETE FROM pipeline_item;
DELETE FROM repo;

-- ── Repositories ────────────────────────────────────────────────────────────

INSERT INTO repo (id, path, name, default_branch, hidden, sort_order, created_at, last_opened_at)
VALUES ('cap-orchard-web', '/Users/you/code/orchard-web', 'orchard-web', 'main', 0, 0,
        datetime('now', '-42 days'), datetime('now', '-12 minutes'));

INSERT INTO repo (id, path, name, default_branch, hidden, sort_order, created_at, last_opened_at)
VALUES ('cap-orchard-api', '/Users/you/code/orchard-api', 'orchard-api', 'main', 0, 1,
        datetime('now', '-71 days'), datetime('now', '-2 hours'));

INSERT INTO repo (id, path, name, default_branch, hidden, sort_order, created_at, last_opened_at)
VALUES ('cap-fieldnotes', '/Users/you/code/fieldnotes', 'fieldnotes', 'main', 0, 2,
        datetime('now', '-15 days'), datetime('now', '-1 days'));

-- ── orchard-web ─────────────────────────────────────────────────────────────

INSERT INTO pipeline_item
  (id, repo_id, issue_number, issue_title, prompt, stage, tags, branch,
   agent_type, activity, activity_changed_at, pinned, pin_order, base_ref,
   created_at, updated_at)
VALUES
  ('cap-auth-middleware', 'cap-orchard-web', 214, 'Refactor auth middleware',
   'Move the auth middleware onto the new token validation library and keep the session tests green',
   'in_progress', '["in progress"]', 'task-auth-middleware',
   'claude', 'working', datetime('now', '-4 minutes'), 1, 1, 'origin/main',
   datetime('now', '-2 days'), datetime('now', '-4 minutes'));

INSERT INTO pipeline_item
  (id, repo_id, issue_number, issue_title, prompt, stage, tags, branch,
   agent_type, activity, activity_changed_at, pinned, pin_order, base_ref,
   created_at, updated_at)
VALUES
  ('cap-empty-states', 'cap-orchard-web', 208, 'Empty states for the task list',
   'Design and build empty states for the task list, including first run and filtered-to-nothing',
   'in_progress', '["in progress"]', 'task-empty-states',
   'codex', 'working', datetime('now', '-18 minutes'), 1, 2, 'origin/main',
   datetime('now', '-3 days'), datetime('now', '-18 minutes'));

INSERT INTO pipeline_item
  (id, repo_id, issue_number, issue_title, prompt, stage, tags, branch,
   agent_type, activity, activity_changed_at, unread_at, base_ref,
   created_at, updated_at)
VALUES
  ('cap-keyboard-nav', 'cap-orchard-web', 219, 'Keyboard navigation in the sidebar',
   'Add full keyboard navigation to the sidebar and document the shortcuts',
   'in_progress', '["in progress"]', 'task-keyboard-nav',
   'claude', 'unread', datetime('now', '-51 minutes'), datetime('now', '-51 minutes'), 'origin/main',
   datetime('now', '-1 days'), datetime('now', '-51 minutes'));

INSERT INTO pipeline_item
  (id, repo_id, issue_number, issue_title, prompt, stage, tags, branch,
   agent_type, activity, pr_number, pr_url, base_ref, created_at, updated_at)
VALUES
  ('cap-image-pipeline', 'cap-orchard-web', 197, 'Responsive image pipeline',
   'Generate responsive image variants at build time and swap the loader over',
   'pr', '["pr"]', 'task-image-pipeline',
   'claude', 'idle', 341, 'https://github.com/orchard/orchard-web/pull/341', 'origin/main',
   datetime('now', '-6 days'), datetime('now', '-3 hours'));

-- ── orchard-api ─────────────────────────────────────────────────────────────

INSERT INTO pipeline_item
  (id, repo_id, issue_number, issue_title, prompt, stage, tags, branch,
   agent_type, activity, activity_changed_at, base_ref, created_at, updated_at)
VALUES
  ('cap-rate-limiting', 'cap-orchard-api', 88, 'Rate limiting on the public API',
   'Add per-token rate limiting to the public API with a shared bucket in Redis',
   'in_progress', '["in progress"]', 'task-rate-limiting',
   'codex', 'working', datetime('now', '-2 minutes'), 'origin/main',
   datetime('now', '-1 days'), datetime('now', '-2 minutes'));

INSERT INTO pipeline_item
  (id, repo_id, issue_number, issue_title, prompt, stage, tags, branch,
   agent_type, activity, activity_changed_at, base_ref, created_at, updated_at)
VALUES
  ('cap-webhook-retries', 'cap-orchard-api', 91, 'Webhook delivery retries',
   'Retry failed webhook deliveries with exponential backoff and a dead letter queue',
   'in_progress', '["in progress"]', 'task-webhook-retries',
   'claude', 'idle', datetime('now', '-4 hours'), 'origin/main',
   datetime('now', '-4 days'), datetime('now', '-4 hours'));

INSERT INTO pipeline_item
  (id, repo_id, issue_number, issue_title, prompt, stage, tags, branch,
   agent_type, activity, pr_number, pr_url, base_ref, created_at, updated_at)
VALUES
  ('cap-schema-migration', 'cap-orchard-api', 84, 'Schema migration v3',
   'Write and verify the v3 schema migration, including the backfill and its rollback',
   'pr', '["pr"]', 'task-schema-migration',
   'copilot', 'idle', 512, 'https://github.com/orchard/orchard-api/pull/512', 'origin/main',
   datetime('now', '-8 days'), datetime('now', '-5 hours'));

INSERT INTO pipeline_item
  (id, repo_id, issue_number, issue_title, prompt, stage, tags, branch,
   agent_type, activity, base_ref, created_at, updated_at)
VALUES
  ('cap-flaky-upload', 'cap-orchard-api', 79, 'Fix the flaky upload test',
   'Track down and fix the intermittent failure in the multipart upload test',
   'done', '["done"]', 'task-flaky-upload',
   'claude', 'idle', 'origin/main',
   datetime('now', '-11 days'), datetime('now', '-9 days'));

-- ── fieldnotes ──────────────────────────────────────────────────────────────

INSERT INTO pipeline_item
  (id, repo_id, issue_number, issue_title, prompt, stage, tags, branch,
   agent_type, activity, activity_changed_at, base_ref, created_at, updated_at)
VALUES
  ('cap-getting-started', 'cap-fieldnotes', 31, 'Getting started guide',
   'Write the getting started guide and check every command in it actually runs',
   'in_progress', '["in progress"]', 'task-getting-started',
   'claude', 'working', datetime('now', '-9 minutes'), 'origin/main',
   datetime('now', '-2 days'), datetime('now', '-9 minutes'));

INSERT INTO pipeline_item
  (id, repo_id, issue_number, issue_title, prompt, stage, tags, branch,
   agent_type, activity, base_ref, created_at, updated_at)
VALUES
  ('cap-changelog', 'cap-fieldnotes', 27, 'Generate the changelog from tags',
   'Generate the changelog from git tags and merged pull requests',
   'done', '["done"]', 'task-changelog',
   'opencode', 'idle', 'origin/main',
   datetime('now', '-14 days'), datetime('now', '-12 days'));
