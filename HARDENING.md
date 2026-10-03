<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-shellcheck/v1.32.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-shellcheck/v1.32.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation: Multiple unquoted shell variable expansions of workflow-controllable (untrusted) inputs in script.sh. The variables `${INPUT_SHELLCHECK_FLAGS}`, `${INPUT_REVIEWDOG_FLAGS}`, and `${FILES}` (derived from user-controlled inputs `shellcheck_flags`, `reviewdog_flags`, `path`, `pattern`, and `exclude`) are expanded **without double-quotes** in shell commands. An attacker-controlled calling workflow can inject shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) through these inputs to achieve command injection.

Offending lines:
- Line 72: `shellcheck -f json  ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ${FILES} \`
- Line 81: `        ${INPUT_REVIEWDOG_FLAGS}`
- Line 87: `shellcheck -f checkstyle ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ${FILES} \`
- Line 95: `        ${INPUT_REVIEWDOG_FLAGS}`
- Line 103: `shellcheck -f diff ${FILES} \`
- Line 111: `      ${INPUT_REVIEWDOG_FLAGS}`

All of these env vars are set from `inputs.*` in action.yml's `env:` block and must be double-quoted (e.g., `"${INPUT_SHELLCHECK_FLAGS}"`) to prevent word-splitting and glob expansion of attacker-supplied values.

Locations:

- `script.sh:72`
- `script.sh:81`
- `script.sh:87`
- `script.sh:95`
- `script.sh:103`
- `script.sh:111`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed all 6 script-injection findings in script.sh by:
1. Tokenizing INPUT_SHELLCHECK_FLAGS into a bash array (shellcheck_flags) using xargs quote-aware splitting, with fallback to '--external-sources' when empty.
2. Tokenizing INPUT_REVIEWDOG_FLAGS into a bash array (reviewdog_flags) using xargs quote-aware splitting.
3. Replacing the FILES string variable with a files_array bash array built from 'find ... -print0' piped through a null-delimited read loop, properly handling filenames with spaces/special chars.
4. All three arrays are expanded with double-quoted "${array[@]}" syntax in all shellcheck and reviewdog invocations (lines 72, 81, 87, 95, 103, 111 in the original).
5. Removed the '# shellcheck disable=SC2086' suppression comments that were masking the word-splitting issues.

