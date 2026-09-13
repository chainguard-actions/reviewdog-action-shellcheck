<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-shellcheck/v1.33.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-shellcheck/v1.33.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): Unquoted shell variable expansion of untrusted data in script.sh. The variables `${INPUT_SHELLCHECK_FLAGS:-'--external-sources'}` and `${INPUT_REVIEWDOG_FLAGS}` are expanded without double-quotes in shell commands. These variables are populated from `inputs.shellcheck_flags` and `inputs.reviewdog_flags` (workflow-controllable) via the `env:` block in action.yml. An attacker can inject shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) through these inputs to achieve command injection. The `# shellcheck disable=SC2086` comments acknowledge the unquoted expansion but do not mitigate the security risk. Offending lines in script.sh:
- `shellcheck -f json  ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} "${files[@]}"` (unquoted)
- `${INPUT_REVIEWDOG_FLAGS}` (unquoted, appears three times as a trailing argument to reviewdog)
- `shellcheck -f checkstyle ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} "${files[@]}"` (unquoted)

Locations:

- `script.sh:80`
- `script.sh:92`
- `script.sh:100`
- `script.sh:110`
- `script.sh:120`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed unquoted shell variable expansion of `INPUT_SHELLCHECK_FLAGS` and `INPUT_REVIEWDOG_FLAGS` in script.sh. Both variables are now tokenized into bash arrays using xargs (quote-aware, injection-safe) before use:

1. `shellcheck_flags` array: Built from `${INPUT_SHELLCHECK_FLAGS:---external-sources}` using `xargs printf '%s\0'` with a NUL-delimited read loop. Used as `"${shellcheck_flags[@]}"` in both shellcheck invocations.

2. `reviewdog_flags` array: Built from `$INPUT_REVIEWDOG_FLAGS` using the same xargs pattern (guarded by `[ -n "$INPUT_REVIEWDOG_FLAGS" ]` to avoid xargs emitting an empty token on empty input). Used as `"${reviewdog_flags[@]}"` in all three reviewdog invocations.

The `# shellcheck disable=SC2086` comments were removed since the unquoted expansions no longer exist. Shell metacharacters in these inputs are now passed as literal argument text rather than being interpreted by the shell.

