# Reusable GitHub Actions workflows

Call these workflows at `jobs.<job>.uses` from another repository. GitHub requires
reusable workflows to live directly in `.github/workflows/`; this directory holds
their usage documentation.

| Workflow | Purpose |
| --- | --- |
| [`docker-build-push.yml`](../.github/workflows/docker-build-push.yml) | Dockerfile checks, a single-platform build, image vulnerability scanning, and optional push. |
| [`terraform-checks.yml`](../.github/workflows/terraform-checks.yml) | Formatting, backend-free initialization, validation, and optional Terraform tests. |
| [`terraform-deploy.yml`](../.github/workflows/terraform-deploy.yml) | Backend initialization, validation, saved plans, and optional apply with Azure OIDC support. |

Replace `REPLACE_WITH_PUBLISHED_TAG_OR_SHA` in the examples with a published Git tag
or full commit SHA. The caller's repository is checked out, so paths refer to the
caller, not Platform Blueprints. Publish these files before referencing them from
another repository. Private repositories also need Actions access configured for
reusable workflows.

Every template has one job with sequential steps. No template defines concurrency
or a matrix. Separate workflow runs can overlap. Terraform keeps backend locking
enabled and waits for `lock-timeout`; callers must use a backend that supports
locking and configure any desired workflow scheduling themselves.

## Docker checks, build, and push

```yaml
name: Container
on:
  pull_request:
  push:
    branches: [main]

jobs:
  container:
    permissions:
      contents: read
      packages: write
    uses: RyanJKS/platform-blueprints/.github/workflows/docker-build-push.yml@REPLACE_WITH_PUBLISHED_TAG_OR_SHA
    with:
      context: .
      dockerfile: Dockerfile
      tags: ghcr.io/your-org/your-app:${{ github.sha }}
      push: ${{ github.event_name == 'push' && github.ref == 'refs/heads/main' }}
      build-args: |
        APP_VERSION=${{ github.sha }}
```

Use a lowercase image path. Tags must be fully qualified for the desired registry,
with one tag per line. GHCR uses the caller's `GITHUB_TOKEN`; publishing requires
`packages: write` and access to the target package. The caller must grant the
permissions requested by the reusable workflow.

For Docker Hub or another registry, pass explicit credentials:

```yaml
# Inside the calling job, alongside uses:
with:
  registry: docker.io
  registry-username: your-dockerhub-user
  tags: docker.io/your-dockerhub-user/your-app:${{ github.sha }}
  push: true
secrets:
  registry-password: ${{ secrets.DOCKERHUB_TOKEN }}
```

Keep pushes on trusted branch or release events. PR builds default to no push.
For private base images, pass `registry-username` and `registry-password` even if
`push` is false to enable registry login. Fork PRs do not receive caller secrets.
Use `build-secrets` for BuildKit secrets, not `build-args`.

BuildKit checks fail on findings. Trivy scans the built image and defaults to
failing on HIGH or CRITICAL vulnerabilities, including those without fixes.
Scans need registry/database network access. A failed build or scan prevents push.
The image is built once, loaded locally, and those exact tags are pushed after the
scan; it is not rebuilt between scan and push. The workflow supports one platform
per call. QEMU supports cross-platform builds on compatible runners. It does not
publish multi-platform manifests or provenance attestations. `image-id` is a local
image ID, not the pushed registry manifest digest.

## Terraform checks on pull requests

```yaml
name: Terraform checks
on:
  pull_request:

jobs:
  checks:
    permissions:
      contents: read
    uses: RyanJKS/platform-blueprints/.github/workflows/terraform-checks.yml@REPLACE_WITH_PUBLISHED_TAG_OR_SHA
    with:
      working-directory: infrastructure
      terraform-version: 1.10.3
      run-tests: true
      test-directory: tests
      lockfile-readonly: true
```

The workflow checks one Terraform root module. Recursive formatting does not run
validation or tests for other independent root modules. Use separate calling jobs
for other roots and `needs` to sequence them if required. Set
`lockfile-readonly: false` for libraries that intentionally do not commit provider
lock files. Terraform tests are opt-in because tests with real providers can
create infrastructure; this workflow supplies no cloud credentials. Use mocked
providers for credential-free PR checks.

## Terraform plan or apply

```yaml
name: Terraform deployment
on:
  workflow_dispatch:
    inputs:
      operation:
        description: Terraform operation
        type: choice
        options: [plan, apply]
        default: plan

jobs:
  checks:
    permissions:
      contents: read
    uses: RyanJKS/platform-blueprints/.github/workflows/terraform-checks.yml@REPLACE_WITH_PUBLISHED_TAG_OR_SHA
    with:
      working-directory: infrastructure
      lockfile-readonly: true

  deploy:
    needs: checks
    permissions:
      contents: read
      id-token: write
    uses: RyanJKS/platform-blueprints/.github/workflows/terraform-deploy.yml@REPLACE_WITH_PUBLISHED_TAG_OR_SHA
    with:
      working-directory: infrastructure
      operation: ${{ inputs.operation }}
      environment: production
      azure-oidc: true
      backend-config-file: environments/production.backend.hcl
      var-file: environments/production.tfvars
    secrets:
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      TERRAFORM_VARS_JSON: ${{ secrets.TERRAFORM_VARS_JSON }}
```

Commit the root module's `.terraform.lock.hcl` before using the default readonly
initialization. Configure the caller's GitHub environment with required reviewers
and allowed deployment branches. The environment gates the entire job before the
plan is created; it does not provide approval of an already generated plan.
An `apply` invocation creates a fresh saved plan and applies that same file in the
same job, only when it contains changes. It does not consume an artifact from an
earlier plan run. `has-changes` is the string `true` or `false`.

Azure OIDC requires a federated credential matching the caller's repository and
GitHub environment, Azure permissions on the deployment scope, and appropriate
Azure Storage data-plane access for an AzureRM backend. The workflow configures
AzureRM's native OIDC environment variables; no client secret or `azure/login`
step is needed. The identity values may also come from secrets on the selected
GitHub environment. This is Azure OIDC support, not automatic OIDC configuration
for every cloud provider. With `azure-oidc: false`, other provider authentication
must already be available to the runner, such as a suitable instance identity.

`TERRAFORM_VARS_JSON` must be a JSON object. It is written to a temporary file with
restricted permissions, passed after `var-file` so it takes precedence, and
removed after the job along with the saved plan. Mark sensitive Terraform inputs
as `sensitive` in the caller. Backend configuration and variable paths are relative
to `working-directory`; secret values should not be committed to those files.

Plan artifact uploads are disabled by default because binary plans can contain
secrets. If enabled, control repository/artifact access and keep retention short.
Set distinct `artifact-name` values for multiple calls in one run. Private AKS,
private registries, and private state endpoints may require a self-hosted runner
with network access; set `runner` to a suitable runner label.

## Input and secret reference

### `docker-build-push.yml`

| Input | Type | Default / requirement | Description |
| --- | --- | --- | --- |
| `runner` | `string` | `ubuntu-latest` | Runner label for the build. |
| `context` | `string` | `.` | Build context relative to the calling repository. |
| `dockerfile` | `string` | `Dockerfile` | Dockerfile path relative to the calling repository. |
| `tags` | `string` | Required | Newline-separated fully qualified image tags. Commas are not supported. |
| `platform` | `string` | `linux/amd64` | Single target platform; scanning and pushing use the same loaded image. |
| `target` | `string` | Empty string | Optional Dockerfile build stage. |
| `build-args` | `string` | Empty string | Newline-separated non-secret build arguments. |
| `push` | `boolean` | `false` | Push only after build checks and the optional vulnerability scan pass. |
| `registry` | `string` | `ghcr.io` | Registry host used for authentication. |
| `registry-username` | `string` | Empty string | Registry username; defaults to the GitHub actor for GHCR. |
| `build-checks` | `boolean` | `true` | Run Docker BuildKit checks before building. |
| `scan-image` | `boolean` | `true` | Scan the built image with Trivy before pushing. |
| `scan-severity` | `string` | `HIGH,CRITICAL` | Comma-separated vulnerability severities that fail the scan. |
| `scan-ignore-unfixed` | `boolean` | `false` | Ignore vulnerabilities that do not have a fix available. |

| Secret | Requirement | Description |
| --- | --- | --- |
| `registry-password` | Optional | Registry password/token. Optional for GHCR, which uses GITHUB_TOKEN. |
| `build-secrets` | Optional | BuildKit secrets in the format accepted by docker/build-push-action. |

### `terraform-checks.yml`

| Input | Type | Default / requirement | Description |
| --- | --- | --- | --- |
| `runner` | `string` | `ubuntu-latest` | Runner label. |
| `working-directory` | `string` | `.` | Terraform root module directory in the calling repository. |
| `terraform-version` | `string` | `1.10.3` | Terraform CLI version; mocked tests need at least 1.7.0. |
| `recursive-format` | `boolean` | `true` | Check formatting recursively under the module directory. |
| `run-tests` | `boolean` | `false` | Run terraform test; enable only for tests suitable for this job without cloud credentials. |
| `test-directory` | `string` | `tests` | Test directory relative to the root module. |
| `lockfile-readonly` | `boolean` | `false` | Require the caller's existing dependency lock file without changing it. |

### `terraform-deploy.yml`

| Input | Type | Default / requirement | Description |
| --- | --- | --- | --- |
| `runner` | `string` | `ubuntu-latest` | Runner label; use a runner with network access to private infrastructure when needed. |
| `working-directory` | `string` | `.` | Terraform root module directory in the calling repository. |
| `terraform-version` | `string` | `1.10.3` | Terraform CLI version. |
| `operation` | `string` | `plan` | plan or apply. Apply creates and applies the same saved plan in this job. |
| `environment` | `string` | Required | GitHub environment in the caller; configure required reviewers there for apply approval. |
| `azure-oidc` | `boolean` | `false` | Authenticate AzureRM using GitHub OIDC and the supplied Azure identity secrets. |
| `backend-config-file` | `string` | Empty string | Optional backend configuration file path relative to working-directory. |
| `var-file` | `string` | Empty string | Optional Terraform variable file path relative to working-directory. |
| `lockfile-readonly` | `boolean` | `true` | Require the committed provider lock file. |
| `lock-timeout` | `string` | `5m` | How long Terraform waits to acquire the remote state lock. |
| `upload-plan` | `boolean` | `false` | Upload the binary plan, which can contain sensitive values, as a workflow artifact. |
| `artifact-name` | `string` | `terraform-plan` | Plan artifact name; use distinct names for multiple calls in the same workflow run. |
| `artifact-retention-days` | `number` | `1` | Number of days to retain an uploaded plan artifact. |

| Secret | Requirement | Description |
| --- | --- | --- |
| `AZURE_CLIENT_ID` | Optional | Client ID of the identity trusted by Azure for OIDC. |
| `AZURE_TENANT_ID` | Optional | Azure tenant ID. |
| `AZURE_SUBSCRIPTION_ID` | Optional | Azure subscription ID. |
| `TERRAFORM_VARS_JSON` | Optional | Optional JSON object of Terraform input values, passed through a temporary variable file. |

## Maintenance

Validate workflow edits with `actionlint .github/workflows/*.yml`. Pin callers to
published revisions, and review action and Terraform version updates before
changing defaults. No workflow in this set runs until a caller invokes it.
