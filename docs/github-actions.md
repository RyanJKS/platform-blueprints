# Reusable GitHub Actions

The library provides reusable workflows for Docker checks, image builds and pushes,
Terraform checks and tests, and Terraform plans and applies.

Call them from a job in your repository:

```yaml
jobs:
  terraform:
    permissions:
      contents: read
    uses: RyanJKS/platform-blueprints/.github/workflows/terraform-checks.yml@REPLACE_WITH_PUBLISHED_TAG_OR_SHA
    with:
      working-directory: infrastructure
      run-tests: true
```

Replace the revision with a published tag or commit SHA. Paths and input values
refer to the calling repository. Reusable workflows use `workflow_call` and expose
typed inputs and explicit secrets. Use `jobs.<job>.uses`, not `steps[*].uses`.

Each workflow uses one job with sequential steps and no concurrency configuration.
Docker scans before pushing. Terraform defaults to plan, with apply selected
explicitly and environment protections configured in the caller.

See the [workflow catalog and full input reference](https://github.com/RyanJKS/platform-blueprints/blob/main/github-actions/README.md)
for caller examples, permissions, registry authentication, Azure OIDC setup, and
plan handling.
