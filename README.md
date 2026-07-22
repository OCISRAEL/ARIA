# ARIA - Analysis Risk IAM

**Subject:** ARIA - Analysis Risk IAM

ARIA is an offline macOS and Windows application for reviewing Oracle Cloud
Infrastructure (OCI) IAM policies. It collects no credentials and does not
send data to OCI. Run the included read-only exporter in OCI Cloud Shell, then
upload its JSON output to ARIA for immediate local results.

## Download ARIA v1.2

Choose your platform, download the ZIP, and extract it before opening ARIA.

| Platform | Requirements | Download |
| --- | --- | --- |
| macOS | Apple Silicon (`arm64`), macOS 26 or later | [Download ARIA for macOS](https://github.com/OCISRAEL/ARIA/releases/download/macos-v1.2/ARIA-1.2-macos-arm64.zip) |
| Windows | 64-bit Windows | [Download ARIA for Windows](https://github.com/OCISRAEL/ARIA/releases/download/windows-v1.2/ARIA-Analysis-Risk-IAM-1.2-windows-x64.zip) |

You also need the read-only [OCI exporter script](aria_rule_exporter.sh) to
create the policy JSON that ARIA analyzes.

## Before you start

- **OCI access:** You need permission to inspect compartments and policies in
  the tenancy. The exporter reads data only; it never changes OCI resources.
- **Home region:** Before opening Cloud Shell, switch the OCI Console to your
  tenancy's **home region**.

## Simple procedure

### 1. Download ARIA

Choose the macOS or Windows download above and extract the ZIP. Download
`aria_rule_exporter.sh` from this repository as well.

```text
macOS:   ARIA - Analysis Risk IAM.app
Windows: ARIA - Analysis Risk IAM.exe
aria_rule_exporter.sh
```

### 2. Upload the exporter to OCI Cloud Shell

In OCI Console, confirm that you are in your tenancy's **home region**, then
open **Cloud Shell**.

From the Cloud Shell menu in the top-right corner, select **Upload**. Drag
`aria_rule_exporter.sh` into the upload area and complete the upload.

User and tenancy names are masked in this example:

![Cloud Shell Upload menu with user and tenancy names masked](assets/cloud-shell-upload-sanitized.png)

### 3. Generate the policy export

In the Cloud Shell terminal, run:

```bash
chmod +x aria_rule_exporter.sh
./aria_rule_exporter.sh
```

The script scans the tenancy and accessible active compartments using only
read-only OCI IAM commands. It writes a JSON file in your Cloud Shell home
directory with a name similar to:

```text
aria_policy_rules_<tenancy-name>.json
```

If the script reports inaccessible compartments, the JSON is still created,
but its `errors` section identifies the incomplete coverage.

### 4. Download the JSON file

Open the Cloud Shell menu again and choose **Download**. Enter the JSON
filename shown by the exporter, then select **Download**.

The tenancy-specific part of the filename is intentionally masked in this
example:

![Cloud Shell download dialog with tenancy name masked](assets/cloud-shell-download-sanitized.png)

### 5. Analyze the export in ARIA

Open `ARIA - Analysis Risk IAM.app` on macOS or
`ARIA - Analysis Risk IAM.exe` on Windows. Select **Upload JSON**, choose the
downloaded JSON file, then select **Run Analysis**. ARIA immediately creates an
HTML report and JSON/CSV results in a timestamped local output folder.

<!-- PRODUCT_CONTENT:START -->

## Output

Each run creates a user-writable folder named
`aria-review-YYYYMMDD-HHMMSS`. It contains:

- `report.html` — static, searchable results suitable for local viewing
- `findings.json` — the complete generic analysis export
- `findings.csv` — a flat findings table
- `normalized_statements.json` — normalized and parsed source statements
- `aria_run.log` — run and validation notes
- `summary.md` — concise executive summary when Markdown output is enabled

`findings.json` retains full source values for validation and automation. The
HTML view masks long OCIDs in summary displays while retaining evidence in
expandable details.

## What ARIA analyzes

The analyzer recognizes standard `Allow`, cross-tenancy `Define`, `Endorse`,
and `Admit` statements; groups, dynamic groups, services, `any-user`, custom
permission sets, compartment names/IDs/paths, and common `where` conditions.
It reviews broad subjects, powerful verbs, sensitive resource families,
tenancy and inherited scope, cross-tenancy trust, service/workload identities,
policy hygiene, parser uncertainty, and scan completeness.

Scores range from 0 to 100:

| Score | Severity |
|---:|---|
| 85–100 | Critical |
| 65–84 | High |
| 40–64 | Medium |
| 20–39 | Low |
| 0–19 | Info |

Read a finding’s evidence, confidence, effective scope, and remediation
together. Individual findings use their own severity; the headline posture is
a light policy-weighted score, so a single rule does not define the entire
tenancy. It is not proof of malicious activity. Low hierarchy confidence or
an unparsed statement should prompt manual validation against the intended OCI
design.

<!-- PRODUCT_CONTENT:END -->

## Security and privacy

- The exporter uses Cloud Shell's existing OCI CLI session. It does not need
  API keys, passwords, Python, or local installation.
- The generated JSON can contain tenancy and policy information. Treat it as
  sensitive: do not commit it to Git or upload it to a public repository.
- ARIA works locally. It does not upload the JSON file or connect to OCI.

## Platform security notes

- **macOS:** The build is locally signed but not yet signed with an Apple
  Developer ID or notarized. Gatekeeper may show a warning for
  browser-downloaded copies.
- **Windows:** The initial portable build is unsigned. Windows SmartScreen may
  show a warning for browser-downloaded copies.

## Release history

See [CHANGELOG.md](CHANGELOG.md) for application version history.
