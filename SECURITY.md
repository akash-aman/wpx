# Security Policy

The wpx team takes the security of every component of this project —
the CLI, the desktop app, and the MCP server surface — seriously.
This document explains how to report a vulnerability and what you
can expect once you do.

## Supported versions

Only the latest minor release receives security fixes. Older minor
versions may be patched at the maintainer's discretion when the fix
is trivial and the user base is non-trivial.

| Version       | Supported          |
|---------------|--------------------|
| `0.1.x`       | ✅                 |
| `0.0.x-test`  | ❌ (pre-release)   |

The currently-installed version is printed by `wpx version` and
shown in the desktop app's sidebar footer.

## Threat model — what counts as a vulnerability

wpx runs on a developer's personal machine and manipulates files in
`~/WPX Sites/`, the system `/etc/hosts` (via authenticated
elevation), and listens on ports 80 / 443. We treat the following
as in-scope:

- **Privilege escalation** — any path that converts an
  unauthenticated user into root without explicit consent
- **Arbitrary file write** outside `~/WPX Sites/`, `~/.wpx/`, the
  user's home, or `/tmp/wpx-*`
- **Arbitrary command execution** triggered by data parsed from
  the CLI (e.g. `.wpx.json`, a pulled SQL dump) without explicit
  user action
- **Authentication bypass** in the wpx-internal MCP server
  (`wpx mcp serve`) that would let one MCP client read another's
  data
- **Insecure default** in the generated WordPress configuration
  (e.g. world-readable secrets, debug endpoints exposed by default)
- **Supply-chain compromise** — installer or release pipeline
  serving an unverified artefact

Out of scope:

- Issues that require local-shell access (we already trust that
  attacker)
- Browser warnings for the unsigned developer build — that's a
  known trade-off documented in [README.md](README.md#install)
- Performance / DoS reports against an attacker-controlled local
  WordPress install (run the CLI's `doctor` and `orphans` instead)
- Findings against third-party tools wpx wraps (mkcert, nginx,
  php-fpm, …) — please report those upstream

## Reporting a vulnerability

**Do NOT open a public GitHub issue for security reports.**

Please email **sir.akashaman@gmail.com** with:

1. A clear description of the issue, including the affected
   component(s): `cli`, `app`, `design`, or `release`
2. Steps to reproduce — ideally a small POC or `wpx` command sequence
3. Your assessment of the impact
4. Any mitigation you've already verified
5. Whether you'd like public attribution after the fix ships

If you'd prefer encrypted reporting, request my PGP key in your
first message and I'll send it back to you out-of-band.

## What to expect

| Step             | SLA (working days, calendar-day clock) |
|------------------|----------------------------------------|
| Acknowledge      | within 2 days                          |
| Triage + severity | within 5 days                         |
| Fix + tag        | depends on severity (see below)        |

Severity guidance:

- **Critical / High** (privilege escalation, RCE, install-time
  compromise) — patched in a `vX.Y.Z+1` patch release within
  7 working days where feasible, with a coordinated disclosure
  window.
- **Medium** — folded into the next minor release.
- **Low / Informational** — addressed opportunistically with
  attribution in the changelog.

After the fix ships you'll receive a draft of the disclosure note;
you're welcome to suggest edits before publication.

## Hardening guidelines for users

While not vulnerabilities per se, these reduce blast radius:

- Run `wpx doctor` after install — it surfaces missing mkcert /
  permissions issues before they bite.
- Keep wpx on the latest minor version (`wpx self-update`).
- Don't run `wpx` as root. Privileged operations (e.g. `/etc/hosts`
  edits) elevate per-action via the system's authentication agent.
- Treat anything you `wpx pull` as untrusted data; the
  `search-replace` step is safe but the SQL dump itself can contain
  arbitrary content.

Thanks for helping keep wpx safe for everyone.
