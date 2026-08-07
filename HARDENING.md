<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-shellcheck/v1.32.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-shellcheck/v1.32.1** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): Unquoted shell variable expansion of untrusted data. The action maps user-controlled inputs (inputs.shellcheck_flags, inputs.reviewdog_flags) into env vars INPUT_SHELLCHECK_FLAGS and INPUT_REVIEWDOG_FLAGS via the env: block in action.yml. These env vars are then expanded **unquoted** in script.sh in multiple places:
- `shellcheck -f json  ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ...` (line ~78)
- `shellcheck -f checkstyle ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ...` (line ~92)
- `        ${INPUT_REVIEWDOG_FLAGS}` (lines ~87, ~100, ~112)
An attacker-controlled value containing shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) in these inputs would be word-split and interpreted by the shell, enabling command injection.

Locations:

- `script.sh:78`
- `script.sh:87`
- `script.sh:92`
- `script.sh:100`
- `script.sh:112`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed unquoted expansion of INPUT_SHELLCHECK_FLAGS and INPUT_REVIEWDOG_FLAGS in script.sh. Both variables are now tokenized into bash arrays (shellcheck_flags and reviewdog_flags) using xargs printf '%s\0' with a NUL-delimited read loop, which provides quote-aware tokenization without allowing shell metacharacters to be interpreted. The arrays are then expanded safely as "${shellcheck_flags[@]}" and "${reviewdog_flags[@]}" in all three shellcheck invocations. The empty-input guard (if [ -n ... ]) prevents xargs from emitting spurious empty tokens. For shellcheck_flags, the default '--external-sources' is applied when the input is empty.

### Iteration 2

**Fixes applied:** missing-permissions

**Notes:**

Added top-level `permissions:` blocks to all four workflow files with minimum required scopes:
- depup.yml: `contents: write`, `pull-requests: write` (needed to create dependency-update PRs)
- release.yml: `contents: write`, `pull-requests: write` (needed to create releases, update tags, and read PR labels for bumpr)
- reviewdog.yml: `contents: read`, `checks: write`, `pull-requests: write` (needed to post PR checks and review comments via reviewdog)
- update_semver.yml: `contents: write` (needed to update major/minor semver tags)

