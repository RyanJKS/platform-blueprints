# Platform Blueprints

My personal “one for all” repository for reusable code, templates, blueprints, and best practices across my apps.

This is a growing collection of building blocks, rather than a single application. It gives me one place to keep proven patterns, improve them over time, and reuse them without starting from scratch.

## What belongs here

- Reusable code, utilities, and configuration.
- Application and platform templates that provide a consistent starting point.
- Infrastructure modules, deployment blueprints, and CI/CD workflows.
- Best practices, conventions, and examples learned from building real apps.

## Repository layout

The repository is organised by technology or purpose. These folders provide space for the collection to grow:

- `azuredevops/` — Azure DevOps pipelines and templates.
- `backstage/` — Backstage templates and developer portal blueprints.
- `github-actions/` — GitHub Actions workflows and reusable actions.
- `helm/` — Helm charts and Kubernetes deployment templates.
- `policies/` — Shared policies, guardrails, and standards.
- `terraform/` — Terraform modules and infrastructure blueprints.

See the [Terraform catalog](terraform/README.md) to browse and scaffold units
from a Terragrunt repository.

Add new areas as useful patterns emerge; the collection is not limited to these technologies.

## How I reuse it

1. Find a building block that fits the app or platform.
2. Read its documentation, requirements, and examples.
3. Choose a known version or Git tag for reproducible reuse.
4. Copy, adapt, or reference it, depending on how that building block is packaged.
5. Bring reusable improvements back here so other apps can benefit.

## Versioning and best practices

Use Git tags and documented versions to identify stable points in the collection. When a building block supports a versioned reference, pin it instead of depending on the latest branch state. For copied code, record its source path and tag or commit so later updates are easier to compare.

Each building block should explain its purpose, setup, dependencies, usage, and customisation points. Document compatibility requirements and breaking changes as it evolves. Keep app-specific details configurable, keep secrets out of templates, and include validation where it helps make reuse reliable.

The aim is to build once, refine over time, and reuse confidently across my other apps.

## Backstage catalog and documentation

The root `catalog-info.yaml` registers this repository as a catalog Component and
references its software templates through a Location. Set the catalog owner to
your maintaining group before registering it.

The root `mkdocs.yml` and `docs/` provide this library's TechDocs site:

- [Overview](docs/index.md)
- [Developer tools / CLI](docs/developer-tools.md) — workstation checklist in recommended setup order.
- [Backstage setup](docs/backstage-setup.md)
- [Maintaining templates](docs/maintaining-templates.md)

Documentation under a template's `skeleton/` is copied into generated projects
and is separate from this library's documentation.
