<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-shellcheck/v1.32.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-shellcheck/v1.32.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation: In script.sh, multiple env vars sourced from workflow-controllable inputs are expanded unquoted in shell commands, allowing shell metacharacter injection. Specifically:
- `${INPUT_SHELLCHECK_FLAGS:-'--external-sources'}` is unquoted in three `shellcheck` invocations (lines ~75, ~87, ~101)
- `${INPUT_REVIEWDOG_FLAGS}` is unquoted as a trailing argument to `reviewdog` in three places (lines ~84, ~96, ~110)
- `${FILES}` (built from `$INPUT_PATH`, `$INPUT_PATTERN`, `$INPUT_EXCLUDE`) is unquoted in three `shellcheck` invocations
All of these variables are set from `inputs.*` values (e.g. `INPUT_SHELLCHECK_FLAGS: ${{ inputs.shellcheck_flags }}`, `INPUT_REVIEWDOG_FLAGS: ${{ inputs.reviewdog_flags }}`), which are workflow-controllable. An attacker-controlled input containing shell metacharacters (`;`, `|`, `&`, `$(...)`) would be interpreted by the shell.

Locations:

- `script.sh:75`
- `script.sh:84`
- `script.sh:87`
- `script.sh:96`
- `script.sh:101`
- `script.sh:110`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed script-injection in script.sh by tokenizing all three list-type inputs into bash arrays using xargs-based quote-aware tokenization:
1. INPUT_SHELLCHECK_FLAGS (with default '--external-sources') → sc_flags array, expanded as "${sc_flags[@]}" in all 3 shellcheck invocations
2. INPUT_REVIEWDOG_FLAGS → rd_flags array, expanded as "${rd_flags[@]}" in all 3 reviewdog invocations
3. FILES (files_with_pattern + files_with_shebang) → files_arr array, expanded as "${files_arr[@]}" in all 3 shellcheck invocations
All tokenizations use the safe pattern: guarded by 'if [ -n "$VAR" ]', NUL-delimited xargs pipeline, and IFS= read -r -d '' loop compatible with macOS bash 3.2. Removed the '# shellcheck disable=SC2086' comments that were suppressing warnings about the previously unquoted expansions.

