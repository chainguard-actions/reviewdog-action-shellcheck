<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-shellcheck/v1.32.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-shellcheck/v1.32.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation: In script.sh, multiple INPUT_* environment variables — which are set from user-controlled `inputs.*` values in action.yml — are expanded **unquoted** inside shell commands. Specifically:

1. `shellcheck -f json  ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ${FILES} \` (line ~75) — both `${INPUT_SHELLCHECK_FLAGS}` and `${FILES}` (derived from `INPUT_PATH`, `INPUT_PATTERN`, `INPUT_EXCLUDE`) are unquoted, allowing word-splitting and shell glob expansion of attacker-controlled values.
2. `shellcheck -f checkstyle ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ${FILES} \` (line ~88) — same issue.
3. `shellcheck -f diff ${FILES} \` (line ~101) — `${FILES}` unquoted.
4. `${INPUT_REVIEWDOG_FLAGS}` is passed unquoted as the final argument to `reviewdog` in all three invocation blocks (lines ~83, ~96, ~109).

An attacker who controls any of `inputs.shellcheck_flags`, `inputs.reviewdog_flags`, `inputs.path`, `inputs.pattern`, or `inputs.exclude` can inject shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) to execute arbitrary commands. The `# shellcheck disable=SC2086` comments confirm the unquoted expansion is intentional but do not mitigate the injection risk.

Locations:

- `script.sh:75`
- `script.sh:83`
- `script.sh:88`
- `script.sh:96`
- `script.sh:101`
- `script.sh:109`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed all unquoted variable expansions in script.sh by tokenizing list-style inputs into bash arrays using the xargs idiom:
1. INPUT_SHELLCHECK_FLAGS → shellcheck_flags array (with default '--external-sources' fallback)
2. FILES (space-separated file list from find) → files array
3. INPUT_REVIEWDOG_FLAGS → reviewdog_flags array
All three shellcheck invocations (json, checkstyle, diff formats) and all three reviewdog invocations now use properly quoted array expansions ("${arr[@]}"). The # shellcheck disable=SC2086 comments were removed as they are no longer needed.

