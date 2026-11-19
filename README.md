# db-migration

[Flyway](https://flywaydb.org/) database migrations for PostgreSQL, built as a container image and deployed as a Kubernetes Job by ArgoCD (Helm chart `charts/db-migration`, a thin wrapper around the shared `migration-job` chart).

## Repository layout

```
.
├── Dockerfile                      # flyway/flyway image + the SQL scripts
├── migrations/
│   └── sql/                        # V<version>__<description>.sql, R__<description>.sql
├── charts/
│   └── db-migration/               # wrapper chart (dependency: migration-job from oci://ghcr.io/huponx/charts)
│       ├── Chart.yaml
│       └── values.yaml             # ArgoCD hook + sync wave defaults
├── docker-compose.yml              # local PostgreSQL + Redis + the migration image
└── .github/
    ├── config/ci.yaml              # CI contract read by huponx/actions
    └── workflows/{pr,main,staging,production}.yml
```

## How it works

1. **Build** a Docker image with Flyway and the versioned SQL scripts (`ghcr.io/huponx/db-migration:<version>`).
2. **Package** the chart `charts/db-migration` with the same version (`oci://ghcr.io/huponx/charts/db-migration`).
3. A deployment PR in `mm-deploy` bumps `targetRevision` of `applications/<env>/db-migration.yaml`. ArgoCD syncs it and runs the Job as a `Sync` hook (sync wave `-5`, the config map at `-6`), so migrations finish before the application waves.
4. Database credentials come from existing Kubernetes Secrets (`secrets:` in the Application values); they are never stored in git.

## Local run

```bash
docker compose up --build        # PostgreSQL, Redis, then Flyway `migrate`
docker compose down -v           # reset
```

## Adding a new migration

1. Create a file under `migrations/sql/` following the Flyway naming convention:

   ```
   V<version>__<description>.sql      # versioned, applied once, in version order
   R__<description>.sql               # repeatable, re-applied when its checksum changes
   ```

   Versions must be unique and increasing (`V4__add_audit_log.sql`).

2. Open a PR. The `pr` flow checks the file names (`flyway-lint`), builds the image, scans it with Trivy and lints the chart. The SQL itself is not analysed: run it against the local PostgreSQL first.
3. After the merge to `main`, the `dev` deployment PR in `mm-deploy` is created and auto-merged; staging and production follow the release flow below.

## Table naming

Tables use lower snake case and a domain prefix: `identity_*`, `finance_*`, `family_*`, `bill_*`, `wish_*`, or `common_*`. New tables must be plural.

## Configuration

The chart is configured under the `migration` key of the Application values (`valuesObject`), see `charts/db-migration/values.yaml` and the `migration-job` chart for every option. Flyway reads its settings from environment variables:

| Variable | Where | Description |
|---|---|---|
| `FLYWAY_URL` | `migration.config.data` | JDBC URL, for example `jdbc:postgresql://host:5432/db` |
| `FLYWAY_LOCATIONS` | `migration.config.data` | `filesystem:/flyway/migrations` (where the Dockerfile puts the scripts) |
| `FLYWAY_CONNECT_RETRIES` | `migration.config.data` | connection retries before failing |
| `FLYWAY_USER`, `FLYWAY_PASSWORD` | `migration.secrets` | from a Secret (`secretName` + `key`) |

Job settings (`migration.backoffLimit`, `migration.ttlSecondsAfterFinished`, `migration.container.resources`, ...) have defaults in `charts/db-migration/values.yaml`.

## CI/CD

`.github/config/ci.yaml` is the contract (`language: sql`) and `.github/workflows/{pr,main,staging,production}.yml` call the reusable workflows of `huponx/actions` (`service-*.yml`):

| Flow | Trigger | Result |
|---|---|---|
| pr | pull request to `main` or `release*` | `flyway-lint`, build, Trivy scan, `helm lint`; nothing pushed |
| main | push to `main` | image and chart pushed (`1.YYYYMMDD.<run>-main-<sha7>`), deployment PR for `dev` in `mm-deploy` |
| staging | push to `release*` | pre-release `v<YYYY>.<MM>.N-release-<sha7>`, image and chart pushed, deployment PR for `staging` |
| production | release published | no build; verifies the image and chart of the release tag exist, deployment PR for `production` |

`N` only increases after the previous pre-release of the month was published; until then a new push changes only the short sha. Required secret: `BOT_TOKEN` (write access to `mm-deploy`) or a GitHub App (`DEPLOY_APP_ID`).

## Setup (one time)

Commands use the [GitHub CLI](https://cli.github.com) (`gh auth login` first, with admin rights on the repositories). Package visibility and access are set in the GitHub UI (package settings).

1. **Publish `huponx/actions`**: merge it and make sure a release exists and the floating `v1` tag points to it (the workflows use `huponx/actions/...@v1`); it must be a version that accepts `language: sql` and has `flyway-lint`. Other repositories must be allowed to use its workflows:

   ```bash
   gh release list -R huponx/actions --limit 3                     # a release must exist
   gh api repos/huponx/actions/git/ref/tags/v1 --jq .object.sha    # v1 must exist
   # private repo only: share the actions with the other repositories of the owner
   gh api -X PUT repos/huponx/actions/actions/permissions/access -f access_level=user
   ```

2. **Token for `mm-deploy`**: `GITHUB_TOKEN` cannot open PRs in another repository. Pick one:

   ```bash
   # a) PAT (fine-grained, repository huponx/mm-deploy: Contents and Pull requests write)
   gh secret set BOT_TOKEN -R huponx/db-migration                  # paste the token

   # b) GitHub App installed on mm-deploy (Contents and Pull requests write)
   gh variable set DEPLOY_APP_ID -R huponx/db-migration --body "<app id>"
   gh secret set DEPLOY_APP_PRIVATE_KEY -R huponx/db-migration < app-private-key.pem
   ```

   The App takes precedence when `DEPLOY_APP_ID` is set; without it `BOT_TOKEN` is used.

3. **Optional**: Slack notification of deployment PRs (set `slack-channel` in `ci.yaml`):

   ```bash
   gh secret set SLACK_WEBHOOK_URL -R huponx/db-migration
   ```

4. **Workflow permissions** (packages and the staging pre-release need write):

   ```bash
   gh api -X PUT repos/huponx/db-migration/actions/permissions/workflow \
     -f default_workflow_permissions=write -F can_approve_pull_request_reviews=false
   ```

5. **GHCR packages**: after the first `main` run the packages `db-migration` and `charts/db-migration` exist. Link each to the repository (package settings, "Manage Actions access", role Write) and give the ArgoCD clusters pull access (public, or an image pull secret and an OCI repository credential in each ArgoCD). `migration-job` 1.0.0 must be readable from `oci://ghcr.io/huponx/charts`.

   ```bash
   gh api "/user/packages?package_type=container" --jq '.[].name'   # list the packages (use /orgs/<org>/packages for an org)
   ```

6. **Branch ruleset** for `main` (PR required, squash only, required checks of the `pr` flow, no force push or deletion). Merge the workflows to `main` first, while `main` is unprotected: status checks only show up in the ruleset picker after they have run once. Save as `main-ruleset.json` and apply (the file is only an input, do not commit it):

   ```json
   {
     "name": "protect main",
     "target": "branch",
     "enforcement": "active",
     "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
     "rules": [
       { "type": "deletion" },
       { "type": "non_fast_forward" },
       { "type": "pull_request", "parameters": {
           "required_approving_review_count": 0, "dismiss_stale_reviews_on_push": false,
           "require_code_owner_review": false, "require_last_push_approval": false,
           "required_review_thread_resolution": false,
           "allowed_merge_methods": ["squash"] } },
       { "type": "required_status_checks", "parameters": {
           "strict_required_status_checks_policy": true,
           "required_status_checks": [
             { "context": "pr / contract" },
             { "context": "pr / lint-flyway" },
             { "context": "pr / build / build (db-migration)" } ] } }
     ],
     "bypass_actors": []
   }
   ```

   ```bash
   REPO=huponx/db-migration
   gh api repos/$REPO/rulesets --method POST --input main-ruleset.json
   gh api repos/$REPO/rulesets --jq '.[] | {id, name, enforcement}'   # verify
   ```

   Or in the UI: Settings > Rules > Rulesets > New ruleset > Import a ruleset. The check names are `<caller job> / <reusable job>`; confirm them with `gh pr checks <pr>` after the first PR run. To change it later: `gh api repos/$REPO/rulesets/<id> --method PUT --input main-ruleset.json`. Rulesets on a private repo need a paid GitHub plan.

   Second ruleset for `release*`: a merge into it creates a staging pre-release, so it needs a PR with the same checks as `main` (the `pr` flow also runs on PRs into `release*`), and no force push or deletion. Save as `release-ruleset.json` and apply the same way (`gh api repos/$REPO/rulesets --method POST --input release-ruleset.json`):

   ```json
   {
     "name": "protect release branches",
     "target": "branch",
     "enforcement": "active",
     "conditions": { "ref_name": { "include": ["refs/heads/release*"], "exclude": [] } },
     "rules": [
       { "type": "deletion" },
       { "type": "non_fast_forward" },
       { "type": "pull_request", "parameters": {
           "required_approving_review_count": 0, "dismiss_stale_reviews_on_push": false,
           "require_code_owner_review": false, "require_last_push_approval": false,
           "required_review_thread_resolution": false,
           "allowed_merge_methods": ["merge", "squash"] } },
       { "type": "required_status_checks", "parameters": {
           "strict_required_status_checks_policy": false,
           "required_status_checks": [
             { "context": "pr / contract" },
             { "context": "pr / lint-flyway" },
             { "context": "pr / build / build (db-migration)" } ] } }
     ],
     "bypass_actors": []
   }
   ```

   To update the existing ruleset: `gh api repos/$REPO/rulesets --jq '.[] | {id, name}'`, then `gh api repos/$REPO/rulesets/<id> --method PUT --input release-ruleset.json`. The ruleset applies to every `release*` branch, so create the first one (for example `release`) from `main` before applying it, or push it while the ruleset is not yet active.

7. **`mm-deploy`**:

   ```bash
   gh repo edit huponx/mm-deploy --enable-auto-merge --delete-branch-on-merge
   gh label create automerge -R huponx/mm-deploy --color 0E8A16 --description "Merge automatically when checks pass" || true
   ```

   - required checks on `main`: `ci`, `diff`, `cve`, `pr-title`;
   - each ArgoCD (one per environment) has a root app with `path: applications/<env>`;
   - `applications/{dev,staging,production}/db-migration.yaml` exist with sample values: set the real database host, database name and Secret names, and replace the sample `targetRevision` with the published version; later versions come from the deployment PRs.

8. **Environments**: staging and production are `enabled: false` in `.github/config/ci.yaml`; remove that line once their ArgoCD and `applications/<env>` exist. For production add `reviewers` and keep `automerge` off.

9. **Verify**:

   ```bash
   gh secret list -R huponx/db-migration && gh variable list -R huponx/db-migration
   # merge a PR into main, then follow the run
   gh run list -R huponx/db-migration --workflow main.yml --limit 1
   gh run watch -R huponx/db-migration
   gh pr list -R huponx/mm-deploy --label automerge                 # the dev deployment PR
   ```
