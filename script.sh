#!/usr/bin/env bash

set -u

echo '::group:: Installing shellcheck ... https://github.com/koalaman/shellcheck'
TEMP_PATH="$(mktemp -d)"
cd "${TEMP_PATH}" || exit
mkdir bin

WINDOWS_TARGET=zip

# Get system architecture
ARCH=$(uname -m)
if [[ "${ARCH}" == "arm64" || "${ARCH}" == "aarch64" ]]; then
  CPU_ARCH="aarch64"
else
  CPU_ARCH="x86_64"
fi

# Set targets based on OS and architecture
if [[ $(uname -s) == "Linux" ]]; then
  LINUX_TARGET="linux.${CPU_ARCH}.tar.xz"
  curl -sL "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.${LINUX_TARGET}" | tar -xJf -
  cp "shellcheck-v$SHELLCHECK_VERSION/shellcheck" ./bin
elif [[ $(uname -s) == "Darwin" ]]; then
  MACOS_TARGET="darwin.${CPU_ARCH}.tar.xz"
  curl -sL "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.${MACOS_TARGET}" | tar -xJf -
  cp "shellcheck-v$SHELLCHECK_VERSION/shellcheck" ./bin
else
  curl -sL "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.${WINDOWS_TARGET}" -o "shellcheck-v${SHELLCHECK_VERSION}.${WINDOWS_TARGET}" && unzip "shellcheck-v${SHELLCHECK_VERSION}.${WINDOWS_TARGET}" && rm "shellcheck-v${SHELLCHECK_VERSION}.${WINDOWS_TARGET}"
  cp "shellcheck.exe" ./bin
fi

PATH="${TEMP_PATH}/bin:$PATH"
shellcheck --version
echo '::endgroup::'

cd "${GITHUB_WORKSPACE}" || exit

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

paths=()
while read -r pattern; do
    [[ -n ${pattern} ]] && paths+=("${pattern}")
done <<< "${INPUT_PATH:-.}"

names=()
if [[ "${INPUT_PATTERN:-*}" != '*' ]]; then
    while read -r pattern; do
        [[ -n ${pattern} ]] && names+=(-o -name "${pattern}")
    done <<< "${INPUT_PATTERN}"
    (( ${#names[@]} )) && { names[0]='('; names+=(')'); }
fi

excludes=()
while read -r pattern; do
    [[ -n ${pattern} ]] && excludes+=(-not -path "${pattern}")
done <<< "${INPUT_EXCLUDE:-}"

# Match all files matching the pattern
mapfile -t files_with_pattern_array < <(find "${paths[@]}" "${excludes[@]}" -type f "${names[@]}")

# Match all files with a shebang (e.g. "#!/usr/bin/env zsh" or even "#!bash") in the first line of a file
# Ignore files which match "$pattern" in order to avoid duplicates
files_with_shebang_array=()
if [ "${INPUT_CHECK_ALL_FILES_WITH_SHEBANGS}" = "true" ]; then
  mapfile -t files_with_shebang_array < <(find "${paths[@]}" "${excludes[@]}" -not "${names[@]}" -type f -print0 | xargs -0 awk 'FNR==1 && /^#!.*sh/ { print FILENAME }')
fi

# Exit early if no files have been found
if [ "${#files_with_pattern_array[@]}" -eq 0 ] && [ "${#files_with_shebang_array[@]}" -eq 0 ]; then
  echo "No matching files found to check."
  exit 0
fi

# Combine file arrays safely
FILES_ARRAY=("${files_with_pattern_array[@]}" "${files_with_shebang_array[@]}")

# Build safe arrays from input variables to prevent shell injection via word splitting
# read -ra splits on whitespace only, preventing metacharacter injection
read -ra SHELLCHECK_FLAGS_ARRAY <<< "${INPUT_SHELLCHECK_FLAGS:---external-sources}"
read -ra REVIEWDOG_FLAGS_ARRAY <<< "${INPUT_REVIEWDOG_FLAGS:-}"

echo '::group:: Running shellcheck ...'
if [ "${INPUT_REPORTER}" = 'github-pr-review' ]; then
  # erroformat: https://git.io/JeGMU
  shellcheck -f json "${SHELLCHECK_FLAGS_ARRAY[@]}" "${FILES_ARRAY[@]}" \
    | jq -r '.[] | "\(.file):\(.line):\(.column):\(.level):\(.message) [SC\(.code)](https://github.com/koalaman/shellcheck/wiki/SC\(.code))"' \
    | reviewdog \
        -efm="%f:%l:%c:%t%*[^:]:%m" \
        -name="shellcheck" \
        -reporter=github-pr-review \
        -filter-mode="${INPUT_FILTER_MODE}" \
        -fail-level="${INPUT_FAIL_LEVEL}" \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
        -level="${INPUT_LEVEL}" \
        "${REVIEWDOG_FLAGS_ARRAY[@]}"
  EXIT_CODE=$?
else
  # github-pr-check,github-check (GitHub Check API) doesn't support markdown annotation.
  shellcheck -f checkstyle "${SHELLCHECK_FLAGS_ARRAY[@]}" "${FILES_ARRAY[@]}" \
    | reviewdog \
        -f="checkstyle" \
        -name="shellcheck" \
        -reporter="${INPUT_REPORTER:-github-pr-check}" \
        -filter-mode="${INPUT_FILTER_MODE}" \
        -fail-level="${INPUT_FAIL_LEVEL}" \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
        -level="${INPUT_LEVEL}" \
        "${REVIEWDOG_FLAGS_ARRAY[@]}"
  EXIT_CODE=$?
fi
echo '::endgroup::'

echo '::group:: Running shellcheck (suggestion) ...'
# -reporter must be github-pr-review for the suggestion feature.
shellcheck -f diff "${FILES_ARRAY[@]}" \
  | reviewdog \
      -name="shellcheck (suggestion)" \
      -f=diff \
      -f.diff.strip=1 \
      -reporter="github-pr-review" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-level="${INPUT_FAIL_LEVEL}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      "${REVIEWDOG_FLAGS_ARRAY[@]}"
EXIT_CODE_SUGGESTION=$?
echo '::endgroup::'

if [ "${EXIT_CODE}" -ne 0 ] || [ "${EXIT_CODE_SUGGESTION}" -ne 0 ]; then
  exit $((EXIT_CODE + EXIT_CODE_SUGGESTION))
fi
