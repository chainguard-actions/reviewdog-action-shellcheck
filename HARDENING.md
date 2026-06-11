<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-shellcheck/v1.32.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **reviewdog--action-shellcheck/v1.32.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): Multiple input-derived environment variables are expanded unquoted inside `run:` shell commands in script.sh. The variables `INPUT_SHELLCHECK_FLAGS`, `INPUT_REVIEWDOG_FLAGS`, and `FILES` (assembled from `INPUT_PATH`, `INPUT_PATTERN`, `INPUT_EXCLUDE`) all hold values sourced from `inputs.*` in action.yml and are passed to the shell without double-quoting. This allows an attacker who controls these inputs to inject shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) and achieve arbitrary command execution. The `# shellcheck disable=SC2086` comments confirm the authors are aware of word-splitting but have not addressed the security risk. Offending lines include:
- Line 71: `shellcheck -f json  ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ${FILES} \`
- Line 80: `        ${INPUT_REVIEWDOG_FLAGS}`
- Line 84: `shellcheck -f checkstyle ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ${FILES} \`
- Line 92: `        ${INPUT_REVIEWDOG_FLAGS}`
- Line 99: `shellcheck -f diff ${FILES} \`
- Line 107: `      ${INPUT_REVIEWDOG_FLAGS}`

Locations:

- `script.sh:71`
- `script.sh:80`
- `script.sh:84`
- `script.sh:92`
- `script.sh:99`
- `script.sh:107`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed script injection vulnerabilities in script.sh by replacing all unquoted variable expansions with properly quoted bash array expansions:
1. INPUT_SHELLCHECK_FLAGS: converted to SHELLCHECK_FLAGS_ARRAY using 'read -ra' and expanded as "${SHELLCHECK_FLAGS_ARRAY[@]}"
2. INPUT_REVIEWDOG_FLAGS: converted to REVIEWDOG_FLAGS_ARRAY using 'read -ra' and expanded as "${REVIEWDOG_FLAGS_ARRAY[@]}"
3. FILES: replaced the string-based FILES variable with FILES_ARRAY built directly from mapfile -t on find output (files_with_pattern_array + files_with_shebang_array), expanded as "${FILES_ARRAY[@]}"
Also removed the '# shellcheck disable=SC2086' comments that were suppressing the word-splitting warnings, and updated the early-exit check to use array length comparisons instead of string emptiness checks.

