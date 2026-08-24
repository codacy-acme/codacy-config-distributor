# codacy-config-distributor

Distributes a shared `.codacy.yaml` to the root of every repository listed in
[`repos.txt`](./repos.txt), by committing directly to each repo's default branch.

## How it works

- **`.codacy.yaml`** — the template config. Edit this file to change what gets
  deployed to every target repo.
- **`repos.txt`** — one target repo per line, as `group/subgroup/project`
  (the path portion of its GitLab URL). Blank lines and `#` comments are ignored.
- **`deploy-config.sh`** — for each repo in `repos.txt`, shallow-clones it,
  overwrites `.codacy.yaml`, and commits + pushes only if the file changed.
  Continues past per-repo failures and exits non-zero if any repo failed.
- **`.gitlab-ci.yml`** — a single manual `deploy-config` job that runs the
  script. Trigger it from the GitLab pipeline UI whenever you want to push the
  current `.codacy.yaml` out to all listed repos.

## Setup

1. Create a GitLab group access token with `write_repository` scope (or a
   personal access token with equivalent rights) covering all target repos.
2. Add it as a masked, protected CI/CD variable named `CODACY_DEPLOY_TOKEN`
   on this project (Settings → CI/CD → Variables).
3. Add target repos to `repos.txt`.
4. Run the `deploy-config` job manually from a pipeline.

## Notes

- This pipeline only runs on GitLab CI. Target repos are assumed to live on
  GitLab (`CI_SERVER_HOST`), since `deploy-config.sh` clones over
  `https://oauth2:<token>@<gitlab-host>/<repo>.git`.
- If this source repo is also mirrored to GitHub, that mirror is for hosting
  only — GitHub Actions does not run `.gitlab-ci.yml`.
