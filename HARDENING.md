<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-shellcheck/v1.32.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-shellcheck/v1.32.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): script.sh expands `${INPUT_SHELLCHECK_FLAGS:-'--external-sources'}` and `${INPUT_REVIEWDOG_FLAGS}` unquoted in shell commands. These variables are populated from `inputs.shellcheck_flags` and `inputs.reviewdog_flags` (set in action.yml's `env:` block as `${{ inputs.shellcheck_flags }}` and `${{ inputs.reviewdog_flags }}`), making them workflow-controllable. Unquoted expansion allows an attacker to inject shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) into the command line. The `# shellcheck disable=SC2086` comments acknowledge the word-splitting intent but do not mitigate the injection risk. Offending lines: `shellcheck -f json  ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ...` (line 74), `${INPUT_REVIEWDOG_FLAGS}` (lines 84, 96, 107), and `shellcheck -f checkstyle ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ...` (line 88).

Locations:

- `script.sh:74`
- `script.sh:84`
- `script.sh:88`
- `script.sh:96`
- `script.sh:107`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed script.sh by tokenizing INPUT_SHELLCHECK_FLAGS and INPUT_REVIEWDOG_FLAGS into bash arrays using xargs quote-aware tokenization (the 'while IFS= read -r -d '' t; do arr+=("$t"); done < <(printf '%s' "$VAR" | xargs printf '%s\0')' pattern) before the pipeline commands. Both variables are now expanded safely as "${shellcheck_flags[@]}" and "${reviewdog_flags[@]}" in all 5 affected locations (lines 74, 84, 88, 96, 107 of the original). The default '--external-sources' for shellcheck_flags is applied via bash parameter expansion before tokenization. Guard conditions prevent xargs from emitting empty tokens on empty input. The # shellcheck disable=SC2086 comments were removed since the unquoted expansions are gone.

