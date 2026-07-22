# Changelog

ARIA uses `MAJOR.MINOR` versions (`X.Y`): increment `X` for main changes and
`Y` for smaller fixes or updates.

## 1.3 — 2026-07-22

- Removed the obsolete input-export timestamp from the HTML report header.
- Preserve OCI policy creator metadata directly on every collected rule.

## 1.2 — 2026-07-22

- Simplified report names to `ARIA_<tenancy>_<date>_<time>.html` and add a
  short numeric suffix only when a name already exists.

## 1.1 — 2026-07-22

- Simplified report pagination to clear **Previous** and **Next** controls with
  a `Page X of Y` label.

## 1.0 — 2026-07-22

- First script-only ARIA release.
- Supports OCI Cloud Shell and local OCI CLI workflows.
- Produces one self-contained HTML IAM review report per run.
