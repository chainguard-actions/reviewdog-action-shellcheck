<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-shellcheck/v1.34.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-shellcheck/v1.34.1** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. Rule (b) violation: Unquoted shell variable expansions of workflow-controllable inputs in script.sh. The env vars INPUT_SHELLCHECK_FLAGS and INPUT_REVIEWDOG_FLAGS are populated from inputs.shellcheck_flags and inputs.reviewdog_flags (set via the env: block in action.yml), then expanded **without double-quotes** in shell commands. An attacker-supplied value containing shell metacharacters (`;`, `|`, `&`, `$(...)`, whitespace, globs) will be word-split and glob-expanded by bash, enabling command injection.

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

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed action.yml without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/action.yml b/action.yml
index 060bc1c..9da1acb 100644
--- a/action.yml
+++ b/action.yml
@@ -1,5 +1,5 @@
 name: 'Run shellcheck with reviewdog'
-description: '🐶 Run shellcheck with reviewdog on pull requests to improve code review experience.'
+description: "\U0001F436 Run shellcheck with reviewdog on pull requests to improve code review experience."
 author: 'haya14busa (reviewdog)'
 inputs:
   github_token:
@@ -67,7 +67,24 @@ inputs:
 runs:
   using: "composite"
   steps:
     - uses: reviewdog/action-setup@d8a7baabd7f3e8544ee4dbde3ee41d0011c3a93f # v1.5.0
       with:
         reviewdog_version: v0.21.2
     - run: '"$GITHUB_ACTION_PATH/script.sh"'
@@ -88,7 +105,6 @@ runs:
         INPUT_EXCLUDE: ${{ inputs.exclude }}
         INPUT_CHECK_ALL_FILES_WITH_SHEBANGS: ${{ inputs.check_all_files_with_shebangs }}
         INPUT_SHELLCHECK_FLAGS: ${{ inputs.shellcheck_flags }}
-
 branding:
   icon: 'zoom-in'
   color: 'purple'

```

Locations:

- `action.yml`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed script.sh without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/script.sh b/script.sh
index 076329c..f0b76a0 100755
--- a/script.sh
+++ b/script.sh
@@ -82,11 +82,25 @@ if [ ${#files[@]} -eq 0 ]; then
   exit 0
 fi
 
+# Tokenize flag inputs into arrays (quote-aware, safe against metacharacters)
+shellcheck_flags=()
+_sc_default='--external-sources'
+_sc_input="${INPUT_SHELLCHECK_FLAGS:-${_sc_default}}"
+if [ -n "$_sc_input" ]; then
+  while IFS= read -r -d '' t; do shellcheck_flags+=("$t"); done \
+    < <(printf '%s' "$_sc_input" | xargs printf '%s\0')
+fi
+
+reviewdog_flags=()
+if [ -n "${INPUT_REVIEWDOG_FLAGS}" ]; then
+  while IFS= read -r -d '' t; do reviewdog_flags+=("$t"); done \
+    < <(printf '%s' "${INPUT_REVIEWDOG_FLAGS}" | xargs printf '%s\0')
+fi
+
 echo '::group:: Running shellcheck ...'
 if [ "${INPUT_REPORTER}" = 'github-pr-review' ]; then
   # erroformat: https://git.io/JeGMU
-  # shellcheck disable=SC2086
-  shellcheck -f json  ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} "${files[@]}" \
+  shellcheck -f json "${shellcheck_flags[@]}" "${files[@]}" \
     | jq -r '.[] | "\(.file):\(.line):\(.column):\(.level):\(.message) [SC\(.code)](https://github.com/koalaman/shellcheck/wiki/SC\(.code))"' \
     | reviewdog \
         -efm="%f:%l:%c:%t%*[^:]:%m" \
@@ -96,12 +110,11 @@ if [ "${INPUT_REPORTER}" = 'github-pr-review' ]; then
         -fail-level="${INPUT_FAIL_LEVEL}" \
         -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
         -level="${INPUT_LEVEL}" \
-        ${INPUT_REVIEWDOG_FLAGS}
+        "${reviewdog_flags[@]}"
   EXIT_CODE=$?
 else
   # github-pr-check,github-check (GitHub Check API) doesn't support markdown annotation.
-  # shellcheck disable=SC2086
-  shellcheck -f checkstyle ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} "${files[@]}" \
+  shellcheck -f checkstyle "${shellcheck_flags[@]}" "${files[@]}" \
     | reviewdog \
         -f="checkstyle" \
         -name="shellcheck" \
@@ -110,14 +123,13 @@ else
         -fail-level="${INPUT_FAIL_LEVEL}" \
         -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
         -level="${INPUT_LEVEL}" \
-        ${INPUT_REVIEWDOG_FLAGS}
+        "${reviewdog_flags[@]}"
   EXIT_CODE=$?
 fi
 echo '::endgroup::'
 
 echo '::group:: Running shellcheck (suggestion) ...'
 # -reporter must be github-pr-review for the suggestion feature.
-# shellcheck disable=SC2086
 shellcheck -f diff "${files[@]}" \
   | reviewdog \
       -name="shellcheck (suggestion)" \
@@ -127,7 +139,7 @@ shellcheck -f diff "${files[@]}" \
       -filter-mode="${INPUT_FILTER_MODE}" \
       -fail-level="${INPUT_FAIL_LEVEL}" \
       -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
-      ${INPUT_REVIEWDOG_FLAGS}
+      "${reviewdog_flags[@]}"
 EXIT_CODE_SUGGESTION=$?
 echo '::endgroup::'
 

```

Locations:

- `script.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, prior-fix

**Notes:**

I fixed the flagged lines in script.sh. The two flag inputs, INPUT_SHELLCHECK_FLAGS (default --external-sources) and INPUT_REVIEWDOG_FLAGS, are now split once into arrays, using the same whitespace splitting and glob expansion the shell applied to upstream's unquoted variables. The shellcheck and reviewdog commands then receive those arrays. Each array is expanded as ${arr[@]+"${arr[@]}"}, because the script uses `set -u` and on macOS's older bash an empty array would otherwise stop it. Nothing in the input values is executed: command substitution, nested variables, ';' and '|' all reach the tools as plain text. The previous harden split these inputs with xargs instead. I deliberately didn't bring that back, because it treats quotes and apostrophes in the value differently from upstream and drops arguments. I also removed the SC2086 shellcheck-disable comments that no longer apply. Nothing was run or tested.

In action.yml I re-applied the previous harden's two changes, though neither one is security-related: the description's emoji is now written as an escaped double-quoted string (\U0001F436), and the blank line before `branding:` is gone. The pinned action-setup SHA (`uses:` line) was already in place.

