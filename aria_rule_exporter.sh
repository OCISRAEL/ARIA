#!/usr/bin/env bash
# Export OCI IAM policy statements and ARIA-relevant metadata to JSON using
# read-only OCI CLI calls.
#
# Intended for OCI Cloud Shell, where both `oci` and `jq` are available.
# No OCI resource is created, changed, or deleted.

set -euo pipefail
umask 077

usage() {
  cat <<'EOF'
Usage: aria_rule_exporter.sh [--profile PROFILE] [--output FILE]

Exports IAM policy statements and policy metadata from the tenancy root and
every active compartment accessible to the selected OCI CLI profile.

Options:
  --profile PROFILE  OCI CLI profile (default: OCI_CLI_PROFILE or DEFAULT)
  --output FILE      JSON file to create (default: aria_policy_rules_<tenancy>.json)
  -h, --help         Show this help
EOF
}

profile="${OCI_CLI_PROFILE:-DEFAULT}"
output=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || { echo "Missing value for --profile" >&2; exit 1; }
      profile="$2"
      shift 2
      ;;
    --output)
      [[ $# -ge 2 ]] || { echo "Missing value for --output" >&2; exit 1; }
      output="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

command -v oci >/dev/null || { echo "Export failed: OCI CLI was not found." >&2; exit 1; }
command -v jq >/dev/null || { echo "Export failed: jq was not found." >&2; exit 1; }

config_file="${OCI_CLI_CONFIG_FILE:-$HOME/.oci/config}"
[[ -r "$config_file" ]] || { echo "Export failed: Cannot read OCI configuration: $config_file" >&2; exit 1; }

# Read just the tenancy setting for the selected OCI CLI profile. OCI config
# profiles are INI sections, so this avoids a Python dependency.
tenancy_id="$(awk -v profile="$profile" '
  /^\[[^]]+\][[:space:]]*$/ {
    section = substr($0, 2, length($0) - 2)
    in_profile = (section == profile)
    next
  }
  in_profile && /^[[:space:]]*tenancy[[:space:]]*=/ {
    sub(/^[^=]*=[[:space:]]*/, "")
    sub(/[[:space:]]*(#|;).*/, "")
    print
    exit
  }
' "$config_file")"
[[ -n "$tenancy_id" ]] || { echo "Export failed: Profile '$profile' has no tenancy setting in $config_file" >&2; exit 1; }

if ! tenancy_json="$(oci iam tenancy get --tenancy-id "$tenancy_id" --profile "$profile" --output json)"; then
  echo "Export failed: Could not read tenancy details. Confirm the Cloud Shell profile can inspect the tenancy." >&2
  exit 1
fi
tenancy_name="$(jq -r '.data.name // empty' <<<"$tenancy_json")"
[[ -n "$tenancy_name" ]] || { echo "Export failed: OCI returned no tenancy name." >&2; exit 1; }

# Preserve ordinary name characters while making a safe, predictable filename.
safe_tenancy_name="$(LC_ALL=C tr -cs '[:alnum:]_. -' '_' <<<"$tenancy_name")"
safe_tenancy_name="${safe_tenancy_name%_}"
[[ -n "$safe_tenancy_name" ]] || { echo "Export failed: Could not derive a safe tenancy filename." >&2; exit 1; }
if [[ -z "$output" ]]; then
  output="aria_policy_rules_${safe_tenancy_name}.json"
fi
[[ ! -e "$output" ]] || { echo "Export failed: Refusing to overwrite existing file: $output" >&2; exit 1; }

workdir="$(mktemp -d)"
trap 'rm -rf -- "$workdir"' EXIT
targets="$workdir/targets.jsonl"
policies="$workdir/policies.jsonl"
rules="$workdir/rules.jsonl"
errors="$workdir/errors.jsonl"
: >"$targets"
: >"$policies"
: >"$rules"
: >"$errors"

jq -cn --arg id "$tenancy_id" '{id: $id, name: "tenancy-root", path: "/"}' >>"$targets"

if ! compartments_json="$(oci iam compartment list \
  --compartment-id "$tenancy_id" \
  --compartment-id-in-subtree true --access-level ANY \
  --all --profile "$profile" --output json)"; then
  echo "Export failed: Could not list compartments. Confirm the Cloud Shell profile has IAM read access." >&2
  exit 1
fi

while IFS= read -r compartment; do
  jq -c '{id, name, path: .["compartment-path"]}' <<<"$compartment" >>"$targets"
done < <(jq -c '.data[] | select(.["lifecycle-state"] == "ACTIVE")' <<<"$compartments_json")

while IFS= read -r target; do
  compartment_id="$(jq -r '.id' <<<"$target")"
  if ! policy_json="$(oci iam policy list --compartment-id "$compartment_id" --all --profile "$profile" --output json 2>&1)"; then
    jq -cn --argjson compartment "$target" --arg error "$policy_json" \
      '{compartment: $compartment, error: $error}' >>"$errors"
    continue
  fi

  while IFS= read -r policy; do
    policy_entry="$(jq -c --argjson compartment "$target" '{
      id, name, description,
      version_date: .["version-date"],
      lifecycle_state: .["lifecycle-state"],
      time_created: .["time-created"],
      creator: (."defined-tags"["Oracle-Tags"].CreatedBy // null),
      tag_created_on: (."defined-tags"["Oracle-Tags"].CreatedOn // null),
      oracle_tags: (."defined-tags"["Oracle-Tags"] // {}),
      compartment: $compartment,
      statements: (.statements // [])
    }' <<<"$policy")"
    printf '%s\n' "$policy_entry" >>"$policies"
    jq -c --argjson policy "$policy_entry" '
      .statements | to_entries[] |
      {
        policy_id: $policy.id,
        policy_name: $policy.name,
        compartment: $policy.compartment,
        statement_number: (.key + 1),
        statement: .value
      }
    ' <<<"$policy_entry" >>"$rules"
  done < <(jq -c '.data[]' <<<"$policy_json")
done <"$targets"

# Write the complete export to a private temporary file, then move it into
# place. This avoids leaving a partial JSON file if the shell is interrupted.
result="$workdir/result.json"
jq -n \
  --arg tenancy_id "$tenancy_id" \
  --arg tenancy_name "$tenancy_name" \
  --arg generated_at_utc "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --slurpfile targets "$targets" \
  --slurpfile policies "$policies" \
  --slurpfile rules "$rules" \
  --slurpfile errors "$errors" \
  '{
    schema_version: 1,
    generated_at_utc: $generated_at_utc,
    tenancy_id: $tenancy_id,
    read_only_operations: ["oci iam tenancy get", "oci iam compartment list", "oci iam policy list"],
    summary: {
      compartments_checked: ($targets | length),
      policies_found: ($policies | length),
      rules_found: ($rules | length),
      compartments_with_errors: ($errors | length)
    },
    tenancy_name: $tenancy_name,
    policies: $policies,
    rules: $rules,
    errors: $errors
  }' >"$result"

mv -n -- "$result" "$output"
[[ -e "$output" ]] || { echo "Export failed: Could not create output file: $output" >&2; exit 1; }

rule_count="$(jq '.summary.rules_found' "$output")"
policy_count="$(jq '.summary.policies_found' "$output")"
error_count="$(jq '.summary.compartments_with_errors' "$output")"
echo "Wrote $rule_count rules from $policy_count policies to $output"
if [[ "$error_count" -gt 0 ]]; then
  echo "Warning: $error_count compartment(s) could not be read; see errors in the JSON." >&2
  exit 2
fi
