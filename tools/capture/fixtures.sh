#!/usr/bin/env bash
# Create the git repositories and worktrees that seed.sql refers to.
#
# Kanna reconciles its database against the filesystem on startup: a task whose
# worktree is missing is closed and moved to the done stage. Seeding rows alone
# therefore produces an empty task list. These fixtures give every seeded task a
# real branch and a real worktree so the rows survive.
#
# The repositories carry real (small) source trees and real history, because the
# captures show an agent actually working in one of them. An empty fixture makes
# the agent correctly report that there is nothing to do, which is honest and
# useless. Everything here is throwaway code written for the fixture; it names no
# real company, customer, or third party.
#
# Tests run on Node's built-in runner (`node --test`) so a fixture needs no
# install step to be genuinely runnable.
set -euo pipefail

ROOT="${1:?usage: fixtures.sh <root>}"
mkdir -p "$ROOT"

DIR=""

git_init () {
  DIR="$ROOT/$1"
  rm -rf "$DIR"
  mkdir -p "$DIR"
  git -C "$DIR" init -q -b main
  git -C "$DIR" config user.email dev@orchard.invalid
  git -C "$DIR" config user.name "Orchard Dev"
}

commit () {
  git -C "$DIR" add -A
  GIT_AUTHOR_DATE="$2" GIT_COMMITTER_DATE="$2" git -C "$DIR" commit -q -m "$1"
}

worktrees () {
  for branch in "$@"; do
    git -C "$DIR" branch "$branch" >/dev/null 2>&1 || true
    git -C "$DIR" worktree add -q ".kanna-worktrees/$branch" "$branch" >/dev/null 2>&1 || true
  done
}

# ── orchard-web ─────────────────────────────────────────────────────────────

git_init orchard-web

cat > "$DIR/README.md" <<'EOF'
# orchard-web

The customer-facing web app. Node's built-in test runner, no build step for the
server code.

    node --test
EOF
cat > "$DIR/package.json" <<'EOF'
{
  "name": "orchard-web",
  "version": "0.4.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
EOF
commit "Set up the project" "2026-07-14T09:12:00-06:00"

mkdir -p "$DIR/src/server" "$DIR/test"
cat > "$DIR/src/server/sessions.js" <<'EOF'
/** In-memory session store. Sessions expire on a sliding window. */
const SESSION_TTL_MS = 30 * 60 * 1000;

export function createSessionStore({ now = () => Date.now() } = {}) {
  const sessions = new Map();

  return {
    create(userId) {
      const id = `sess_${Math.random().toString(36).slice(2, 12)}`;
      sessions.set(id, { id, userId, touchedAt: now() });
      return id;
    },
    get(id) {
      const session = sessions.get(id);
      if (!session) return null;
      if (now() - session.touchedAt > SESSION_TTL_MS) {
        sessions.delete(id);
        return null;
      }
      session.touchedAt = now();
      return session;
    },
    destroy(id) {
      sessions.delete(id);
    },
    get size() {
      return sessions.size;
    },
  };
}
EOF
cat > "$DIR/src/server/authMiddleware.js" <<'EOF'
import { createSessionStore } from "./sessions.js";

/**
 * Auth middleware.
 *
 * The token parsing below predates src/server/tokens.js and duplicates its
 * rules — badly. It does not check the issuer, it does not check expiry, and it
 * treats any three dot-separated segments as a valid token.
 */
export function createAuthMiddleware({ sessions = createSessionStore() } = {}) {
  return function authMiddleware(req, res, next) {
    const header = req.headers?.authorization ?? "";
    if (!header.startsWith("Bearer ")) {
      res.status(401).json({ error: "missing bearer token" });
      return;
    }

    const raw = header.slice("Bearer ".length);
    const parts = raw.split(".");
    if (parts.length !== 3) {
      res.status(401).json({ error: "malformed token" });
      return;
    }

    let claims;
    try {
      claims = JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"));
    } catch {
      res.status(401).json({ error: "malformed token" });
      return;
    }

    req.session = sessions.get(claims.sid) ?? null;
    req.userId = claims.sub ?? null;
    next();
  };
}
EOF
cat > "$DIR/test/sessions.test.js" <<'EOF'
import assert from "node:assert/strict";
import { test } from "node:test";
import { createSessionStore } from "../src/server/sessions.js";

test("a fresh session is readable", () => {
  const store = createSessionStore();
  const id = store.create("user_1");
  assert.equal(store.get(id).userId, "user_1");
});

test("a session expires after the ttl", () => {
  let clock = 0;
  const store = createSessionStore({ now: () => clock });
  const id = store.create("user_1");
  clock += 31 * 60 * 1000;
  assert.equal(store.get(id), null);
});

test("reading a session slides its expiry", () => {
  let clock = 0;
  const store = createSessionStore({ now: () => clock });
  const id = store.create("user_1");
  clock += 20 * 60 * 1000;
  store.get(id);
  clock += 20 * 60 * 1000;
  assert.ok(store.get(id));
});
EOF
commit "Add the session store and auth middleware" "2026-07-21T15:41:00-06:00"

cat > "$DIR/src/server/tokens.js" <<'EOF'
/**
 * Token validation.
 *
 * One place that knows what a token is: the signature, the issuer, the expiry,
 * and the claim shape. Callers get a result object rather than an exception so
 * a rejected token and a malformed one can be told apart.
 */
const ISSUER = "orchard";

export function validateToken(raw, { secret, now = () => Date.now() } = {}) {
  if (typeof raw !== "string" || raw.length === 0) {
    return { ok: false, reason: "missing" };
  }

  const parts = raw.split(".");
  if (parts.length !== 3) {
    return { ok: false, reason: "malformed" };
  }

  let claims;
  try {
    claims = JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"));
  } catch {
    return { ok: false, reason: "malformed" };
  }

  if (claims.iss !== ISSUER) {
    return { ok: false, reason: "issuer" };
  }
  if (typeof claims.exp !== "number" || claims.exp * 1000 <= now()) {
    return { ok: false, reason: "expired" };
  }
  if (!verifySignature(parts, secret)) {
    return { ok: false, reason: "signature" };
  }

  return { ok: true, claims };
}

function verifySignature([header, payload, signature], secret) {
  if (!secret) return false;
  return signature === sign(`${header}.${payload}`, secret);
}

export function sign(input, secret) {
  let hash = 0;
  for (const char of `${input}:${secret}`) {
    hash = (hash * 31 + char.codePointAt(0)) | 0;
  }
  return Buffer.from(String(hash)).toString("base64url");
}
EOF
cat > "$DIR/test/tokens.test.js" <<'EOF'
import assert from "node:assert/strict";
import { test } from "node:test";
import { sign, validateToken } from "../src/server/tokens.js";

const SECRET = "fixture-secret";

function token(claims) {
  const header = Buffer.from(JSON.stringify({ alg: "hs" })).toString("base64url");
  const payload = Buffer.from(JSON.stringify(claims)).toString("base64url");
  return `${header}.${payload}.${sign(`${header}.${payload}`, SECRET)}`;
}

test("a well-formed token validates", () => {
  const raw = token({ iss: "orchard", sub: "user_1", exp: 2000 });
  const result = validateToken(raw, { secret: SECRET, now: () => 1_000_000 });
  assert.equal(result.ok, true);
  assert.equal(result.claims.sub, "user_1");
});

test("a token from another issuer is rejected", () => {
  const raw = token({ iss: "elsewhere", sub: "user_1", exp: 2000 });
  assert.deepEqual(validateToken(raw, { secret: SECRET, now: () => 1_000_000 }).reason, "issuer");
});

test("an expired token is rejected", () => {
  const raw = token({ iss: "orchard", sub: "user_1", exp: 1 });
  assert.deepEqual(validateToken(raw, { secret: SECRET, now: () => 1_000_000 }).reason, "expired");
});
EOF
commit "Add the token validation library" "2026-08-03T11:08:00-06:00"

mkdir -p "$DIR/src/routes"
cat > "$DIR/src/routes/index.js" <<'EOF'
import { createAuthMiddleware } from "../server/authMiddleware.js";

export function registerRoutes(app) {
  app.use(createAuthMiddleware());

  app.get("/api/me", (req, res) => {
    if (!req.session) {
      res.status(401).json({ error: "no session" });
      return;
    }
    res.json({ userId: req.userId });
  });

  app.get("/api/health", (_req, res) => res.json({ ok: true }));
}
EOF
commit "Wire the routes through the auth middleware" "2026-08-19T16:27:00-06:00"

cat >> "$DIR/README.md" <<'EOF'

## Layout

- `src/server/tokens.js` — the one place that decides whether a token is valid
- `src/server/sessions.js` — sliding-window session store
- `src/server/authMiddleware.js` — request middleware
- `src/routes/` — route registration
EOF
commit "Document the server layout" "2026-08-28T10:03:00-06:00"

worktrees task-auth-middleware task-empty-states task-keyboard-nav task-image-pipeline
echo "orchard-web: $(git -C "$DIR" rev-list --count HEAD) commits, $(git -C "$DIR" worktree list | wc -l | tr -d ' ') worktrees"

# ── orchard-api ─────────────────────────────────────────────────────────────

git_init orchard-api
cat > "$DIR/README.md" <<'EOF'
# orchard-api

The public API. Run the tests with `node --test`.
EOF
cat > "$DIR/package.json" <<'EOF'
{
  "name": "orchard-api",
  "version": "1.2.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
EOF
commit "Set up the project" "2026-06-24T08:55:00-06:00"

mkdir -p "$DIR/src" "$DIR/test"
cat > "$DIR/src/rateLimit.js" <<'EOF'
/** Fixed-window rate limiter, one bucket per token. */
export function createRateLimiter({ limit = 60, windowMs = 60_000, now = () => Date.now() } = {}) {
  const buckets = new Map();

  return function take(token) {
    const bucket = buckets.get(token);
    const currentWindow = Math.floor(now() / windowMs);
    if (!bucket || bucket.window !== currentWindow) {
      buckets.set(token, { window: currentWindow, used: 1 });
      return { allowed: true, remaining: limit - 1 };
    }
    if (bucket.used >= limit) {
      return { allowed: false, remaining: 0 };
    }
    bucket.used += 1;
    return { allowed: true, remaining: limit - bucket.used };
  };
}
EOF
cat > "$DIR/test/rateLimit.test.js" <<'EOF'
import assert from "node:assert/strict";
import { test } from "node:test";
import { createRateLimiter } from "../src/rateLimit.js";

test("the first request in a window is allowed", () => {
  const take = createRateLimiter({ limit: 2, now: () => 0 });
  assert.equal(take("token").allowed, true);
});

test("requests past the limit are refused", () => {
  const take = createRateLimiter({ limit: 2, now: () => 0 });
  take("token");
  take("token");
  assert.equal(take("token").allowed, false);
});
EOF
commit "Add the fixed-window rate limiter" "2026-07-09T13:20:00-06:00"

cat > "$DIR/src/webhooks.js" <<'EOF'
/** Webhook delivery with exponential backoff. */
export function backoffSchedule(attempt, { base = 1_000, cap = 60_000 } = {}) {
  return Math.min(cap, base * 2 ** attempt);
}

export async function deliver(endpoint, payload, { send, attempts = 5, sleep }) {
  let lastError = null;
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    try {
      return await send(endpoint, payload);
    } catch (error) {
      lastError = error;
      if (attempt < attempts - 1) await sleep(backoffSchedule(attempt));
    }
  }
  throw lastError;
}
EOF
commit "Add webhook delivery with backoff" "2026-08-11T09:46:00-06:00"

worktrees task-rate-limiting task-webhook-retries task-schema-migration task-flaky-upload
echo "orchard-api: $(git -C "$DIR" rev-list --count HEAD) commits, $(git -C "$DIR" worktree list | wc -l | tr -d ' ') worktrees"

# ── fieldnotes ──────────────────────────────────────────────────────────────

git_init fieldnotes
cat > "$DIR/README.md" <<'EOF'
# fieldnotes

Product documentation. Markdown in `docs/`, one page per topic.
EOF
mkdir -p "$DIR/docs"
cat > "$DIR/docs/overview.md" <<'EOF'
# Overview

Fieldnotes is the documentation set for Orchard. Each page stands on its own and
links to the others rather than assuming a reading order.
EOF
commit "Start the documentation set" "2026-08-21T14:02:00-06:00"

cat > "$DIR/docs/deploying.md" <<'EOF'
# Deploying

Deploys are promoted, never rebuilt: the artifact that passed staging is the
artifact that ships.
EOF
commit "Write the deploy page" "2026-08-27T10:31:00-06:00"

worktrees task-getting-started task-changelog
echo "fieldnotes: $(git -C "$DIR" rev-list --count HEAD) commits, $(git -C "$DIR" worktree list | wc -l | tr -d ' ') worktrees"
