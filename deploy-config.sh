#!/usr/bin/env bash
set -euo pipefail

# Pushes .codacy.yaml to the root of every repo listed in repos.txt,
# committing directly to each repo's default branch.
#
# Required env vars:
#   CODACY_DEPLOY_TOKEN - group access token with write_repository scope
#   CI_SERVER_HOST       - provided by GitLab CI

SOURCE_FILE="$(pwd)/.codacy.yaml"
REPOS_FILE="$(pwd)/repos.txt"
WORKDIR="$(mktemp -d)"

if [[ -z "${CODACY_DEPLOY_TOKEN:-}" ]]; then
  echo "ERROR: CODACY_DEPLOY_TOKEN is not set" >&2
  exit 1
fi

git config --global user.email "codacy-config-bot@${CI_SERVER_HOST}"
git config --global user.name "Codacy Config Bot"

status=0

while IFS= read -r repo_path || [[ -n "$repo_path" ]]; do
  # Strip comments and surrounding whitespace, skip blanks
  repo_path="${repo_path%%#*}"
  repo_path="$(echo -n "$repo_path" | xargs)"
  [[ -z "$repo_path" ]] && continue

  echo "=== ${repo_path} ==="
  repo_dir="${WORKDIR}/$(echo "$repo_path" | tr '/' '_')"
  clone_url="https://oauth2:${CODACY_DEPLOY_TOKEN}@${CI_SERVER_HOST}/${repo_path}.git"

  if ! git clone --depth 1 "$clone_url" "$repo_dir" 2>/tmp/clone_err.log; then
    echo "  FAILED to clone: $(cat /tmp/clone_err.log)" >&2
    status=1
    continue
  fi

  cp "$SOURCE_FILE" "${repo_dir}/.codacy.yaml"

  pushd "$repo_dir" >/dev/null
  if [[ -z "$(git status --porcelain -- .codacy.yaml)" ]]; then
    echo "  no changes, skipping"
    popd >/dev/null
    continue
  fi

  git add .codacy.yaml
  git commit -m "Update .codacy.yaml from codacy-config-file" >/dev/null
  if git push origin HEAD 2>/tmp/push_err.log; then
    echo "  pushed"
  else
    echo "  FAILED to push: $(cat /tmp/push_err.log)" >&2
    status=1
  fi
  popd >/dev/null
done < "$REPOS_FILE"

rm -rf "$WORKDIR"
exit $status
