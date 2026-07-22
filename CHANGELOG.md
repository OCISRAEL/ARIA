# Changelog

ARIA uses a two-part version: `MAJOR.MINOR` (`X.Y`).

- Increment **MAJOR** (`X`) for main changes.
- Increment **MINOR** (`Y`) for smaller bug fixes and updates.

Every generated report records its application version, ruleset version, report-schema version, release date, and this concise release history.

## Delivery policy

- Keep only the current build at `ARIA - Analysis Risk IAM.app` in the project root.
- Do not retain versioned, `previous`, or `stale` app-bundle copies locally.
- Record release history here; use Git history for file-level changes.
- Publish matching platform releases with tags `windows-vX.Y` and `macos-vX.Y`.

## 1.2 — 2026-07-22

- Added the aligned Apple Silicon macOS portable package for the `1.2` release.
- Standardized public platform release names as `ARIA - macOS vX.Y` and
  `ARIA - Windows vX.Y`.
- Added a public macOS/Windows download chooser and platform-specific launch
  guidance.
- Added synchronized public documentation for ARIA output files and analysis
  capabilities.

## 1.1.1 — 2026-07-20

- Removed the visible Report Lineage section; version metadata remains in all exported artifacts.
- Consolidated macOS deliverables to the single current app bundle.

## 1.1.0 — 2026-07-20

- Added traceable report provenance and release history.
- Refined policy observations, risk scoring, and review-priority reporting.
- Improved statement evidence and report layout.

## 1.0.0 — 2026-07-08

- Initial offline OCI IAM policy review desktop release.
