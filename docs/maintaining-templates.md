# Maintaining templates

## Add or change a blueprint

Keep each template descriptor beside its source skeleton, following the existing
`backstage/templates/base-app/` layout. Add new descriptors to `spec.targets` in
`backstage/all.yaml`. These paths are relative to `backstage/all.yaml`. See
[catalog setup](backstage-setup.md) for registration and ownership requirements.

Use unique template entity names. Retain a template's name and namespace when
updating the same template; changing its identity can create another catalog
entry. Keep repository destinations and GitHub code owners as form inputs rather
than embedding a maintainer's personal account.

Update the affected documentation with the implementation. Changes to the library
belong in root `docs/`; changes to generated projects belong in the skeleton's
documentation. Keep each site's navigation and links consistent.

## Check changes

- Parse changed YAML and confirm every Location target and MkDocs navigation target
  exists. Skeleton YAML contains scaffolder expressions; validate its rendered
  output as well when testing template changes.
- Confirm action IDs and input schemas against the consuming Backstage instance's
  `/create/actions` page. An installed action may reject unsupported input fields.
- Use Backstage's template editor or dry run to inspect generated files before
  creating a real repository. Validate naming rules, ownership, catalog metadata,
  and generated documentation.
- Build this documentation with the configured TechDocs generator. If MkDocs and
  `mkdocs-techdocs-core` are installed, run from the repository root:

  ```sh
  mkdocs build --strict --site-dir /tmp/platform-blueprints-docs
  ```

Keep generated documentation output out of version control. A successful local
build checks the documentation; it does not prove Backstage publishing or GitHub
permissions.

## Understand update behavior

Backstage refreshes registered template entities from their source. With a GitHub
branch URL, push the changes to that branch; with a local file source, change the
local files. Trigger a catalog refresh when you need to load changes promptly.
Existing task executions retain their template specification; start a new task to
use an updated form or workflow.

Generated repositories are independent copies. Updating a skeleton does not add
files to existing repositories. Distribute later fixes with reviewed pull requests
or a migration script. Reusable GitHub workflows can reduce duplicated CI logic.

For repeatable template versions, register a tag or commit URL instead of a moving
branch. Update the registered source deliberately when adopting a newer revision.

## Retire a template or repository

Remove a retired template from `backstage/all.yaml` and remove any independent
registration. Depending on catalog orphan handling, an old entity may need to be
removed from the catalog after it loses its source.

Deleting a catalog entity does not delete its GitHub repository. Delete an unwanted
repository separately in GitHub, and remove its catalog registration if present.
