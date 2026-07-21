# Changelog

ARIA uses [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

- Increment **MAJOR** for incompatible report contracts or analysis behavior.
- Increment **MINOR** for new analysis capabilities, report sections, or notable scoring/ruleset changes.
- Increment **PATCH** for backward-compatible fixes that do not materially change analysis coverage.

Every generated report records its application version, ruleset version, report-schema version, release date, and this concise release history.

## Delivery policy

- Keep only the current build at `ARIA - Analysis Risk IAM.app` in the project root.
- Do not retain versioned, `previous`, or `stale` app-bundle copies locally.
- Record release history here; use Git history for file-level changes.

## 1.1.1 — 2026-07-20

- Removed the visible Report Lineage section; version metadata remains in all exported artifacts.
- Consolidated macOS deliverables to the single current app bundle.

## 1.1.0 — 2026-07-20

- Added traceable report provenance and release history.
- Refined policy observations, risk scoring, and review-priority reporting.
- Improved statement evidence and report layout.

## 1.0.0 — 2026-07-08

- Initial offline OCI IAM policy review desktop release.
