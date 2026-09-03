# Genuine Kanna product captures

## Goal

Replace fabricated screenshot-like UI on the Kanna homepage with repository-owned, genuine captures from the owner-provided Reddit gallery, and polish the surrounding page for desktop and mobile.

## Scope and constraints

- Use the macOS capture and three mobile captures from the owner-provided [Reddit gallery](https://www.reddit.com/r/ClaudeCode/comments/1w6eklk/looking_for_beta_testers_for_kanna_build_with/) as product evidence for the desktop, notifications, mobile task management, and remote terminal access. Cropping and optimization may not alter product state; disclose any redaction.
- Remove simulated product UI, fabricated commands and paths, and public-facing “pipeline” terminology. Use the owner-selected term “composed workflows.” A workflow graphic is allowed only when it is clearly labelled as an illustration and does not resemble product UI.
- Keep claims limited to installed agent CLIs, repo-defined staged workflows, worktree-isolated tasks, coordinator agents, mobile notifications/control, and cross-machine transfer. LAN access and notifications are free; cloud-relay remote terminal access is $5/month and free for beta testers.
- Preserve the static deployment, `CNAME`, and client-side GitHub Releases download behavior. Do not publish or deploy.
- Owner directive (2026-09-03): do not present simulated, fabricated, or CSS/HTML-built interfaces as screenshots; generated graphics may only be obvious explanatory illustrations.

## Revision round 1 directive

Round 1 reviewer feedback (2026-09-03) requires a visible `:focus-visible` indicator on every download button and re-encoding the unchanged notification capture as AVIF or WebP. The reviewer explicitly left the other phone-image encodings, hero `srcset`/margin, font import, layout offset, mobile navigation, and feature-index contrast out of this revision.

## Done when

All four genuine captures are stored as optimized local assets and used with useful alt text/captions; the page is polished without horizontal overflow at representative desktop and mobile widths; terminology, claims, HTML, and links are validated; browser visual verification is complete; and all task work is committed. No capture needs cropping or redaction for this implementation.
