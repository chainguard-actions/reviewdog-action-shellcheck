<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-shellcheck/v1.34.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-shellcheck/v1.34.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation: Unquoted shell variable expansions of workflow-controllable inputs in script.sh. The env vars INPUT_SHELLCHECK_FLAGS and INPUT_REVIEWDOG_FLAGS are populated from inputs.shellcheck_flags and inputs.reviewdog_flags (set via the env: block in action.yml), then expanded **without double-quotes** in shell commands. An attacker-supplied value containing shell metacharacters (`;`, `|`, `&`, `$(...)`, whitespace, globs) will be word-split and glob-expanded by bash, enabling command injection.

Offending lines:
- `shellcheck -f json  ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} "${files[@]}"` (line 83)
- `        ${INPUT_REVIEWDOG_FLAGS}` (line 93)
- `shellcheck -f checkstyle ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} "${files[@]}"` (line 97)
- `        ${INPUT_REVIEWDOG_FLAGS}` (line 106)
- `      ${INPUT_REVIEWDOG_FLAGS}` (line 117)

Fix: quote all expansions, e.g. `"${INPUT_SHELLCHECK_FLAGS:---external-sources}"` and pass reviewdog flags as an array or quoted string.

Locations:

- `script.sh:83`
- `script.sh:93`
- `script.sh:97`
- `script.sh:106`
- `script.sh:117`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed all 5 offending lines in script.sh where INPUT_SHELLCHECK_FLAGS and INPUT_REVIEWDOG_FLAGS were expanded without double-quotes. Both variables are now tokenized into bash arrays (shellcheck_flags and reviewdog_flags) using the xargs-loop idiom before the pipelines, then expanded as "${shellcheck_flags[@]}" and "${reviewdog_flags[@]}". The tokenization uses 'if [ -n ... ]' guards to avoid the empty-value xargs issue, and is performed before the shellcheck|reviewdog pipelines so stdin is not disturbed. The shellcheck_flags array applies the '--external-sources' default before tokenization. Removed the now-unnecessary '# shellcheck disable=SC2086' comments.

