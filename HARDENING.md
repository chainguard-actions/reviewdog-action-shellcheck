<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-shellcheck/v1.34.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-shellcheck/v1.34.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): Unquoted shell variable expansion of untrusted data in script.sh. The env vars INPUT_SHELLCHECK_FLAGS and INPUT_REVIEWDOG_FLAGS are populated from action inputs (inputs.shellcheck_flags and inputs.reviewdog_flags via the env: block in action.yml) and are expanded unquoted in shell command lines. This allows an attacker-controlled input to inject shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) into the command. Offending lines:
- `shellcheck -f json  ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ...` (line 79)
- `        ${INPUT_REVIEWDOG_FLAGS}` (line 88)
- `shellcheck -f checkstyle ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ...` (line 93)
- `        ${INPUT_REVIEWDOG_FLAGS}` (line 101)
- `      ${INPUT_REVIEWDOG_FLAGS}` (line 112)

Locations:

- `script.sh:79`
- `script.sh:88`
- `script.sh:93`
- `script.sh:101`
- `script.sh:112`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed all 5 instances of unquoted shell variable expansion in script.sh. INPUT_SHELLCHECK_FLAGS and INPUT_REVIEWDOG_FLAGS are now safely tokenized into bash arrays using xargs-based quote-aware splitting (the 'while IFS= read -r -d '' t; do arr+=("$t"); done < <(printf '%s' "$VAR" | xargs printf '%s\0')' idiom). Both arrays are guarded with 'if [ -n "$VAR" ]' to prevent xargs from emitting an empty token on empty input. The arrays are then expanded as "${shellcheck_flags[@]}" and "${reviewdog_flags[@]}" in all shellcheck and reviewdog invocations (lines 79, 88, 93, 101, 112 of the original). The shellcheck_flags array preserves the '--external-sources' default when INPUT_SHELLCHECK_FLAGS is empty. The '# shellcheck disable=SC2086' suppression comments were removed as they are no longer needed.

