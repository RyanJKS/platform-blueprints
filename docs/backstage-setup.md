# Backstage setup

## Requirements

- An existing Backstage catalog group that maintains this repository. Verify
  `group:default/platform`, or replace it in `backstage/components/platform-blueprints.yaml`
  `backstage/templates/base-app/template.yaml`, and the example entities with that
  group's entity reference.
  This repository does not define the group.
- A GitHub integration that can read this repository and create repositories in
  destinations chosen by template users.
- Scaffolder actions `fetch:template`, `publish:github`, and `catalog:register`.
- TechDocs frontend and backend support. A local Docker generator needs access to
  a running Docker daemon.

## Register the catalog

Register this URL through Backstage's catalog import page:

```text
https://github.com/<account>/<repository>/blob/<branch>/backstage/all.yaml
```

Alternatively, merge this entry into the consuming Backstage app configuration:

```yaml
catalog:
  locations:
    - type: url
      target: https://github.com/<account>/<repository>/blob/<branch>/backstage/all.yaml
      rules:
        - allow: [Component, Location, Template, Domain, System, Resource]
```

Replace the placeholders. Configuration arrays can override earlier arrays;
preserve other required entries, including catalog users and groups. No Backstage
app configuration is stored in this repository.

`backstage/all.yaml` is the `platform-blueprint-templates` Location. Its explicit
relative targets load `components/platform-blueprints.yaml` and
`templates/base-app/template.yaml`, plus the example Domain, System, and Resource
under `domains/`, `systems/`, and `resources/`. Backstage loads the skeleton only when the
Template's `fetch:template` action runs; it is not registered as catalog metadata.

For local development, a `type: file` location can point to `backstage/all.yaml`.
Resolve its path relative to the backend process's working directory, not the
configuration file. GitHub URL registration also provides the source URL needed
for template fetching and TechDocs without a local checkout.

## Existing registrations

The root `catalog-info.yaml` now forwards to `backstage/all.yaml`. Existing root
registrations continue to load the same Component and Template identities. Keep
that registration, or replace it with the new URL; do not register both sources.
If migrating configuration, replace the existing entry instead of adding another.
For manually imported sources, remove the old source and import the new entry
point. Catalog orphan handling may temporarily remove and then recreate entities.
Remove any old direct registration of `backstage/base-app/template.yaml` as part
of the migration. It is replaced by `backstage/templates/base-app/template.yaml`.
Removing a catalog source does not delete generated GitHub repositories.

## Verify registration

1. Confirm `group:default/platform` (or the chosen replacement) exists.
2. Find **Platform Blueprints** in the catalog and open its **Docs** tab.
3. Find **Base GitHub repository** on the Create page.
4. Check processing errors, source access, allowed kinds, and relative targets.
5. Select Domain, System, or Resource in the catalog Kind filter, with ownership
   set to All, to see the labeled examples. These are metadata only; no infrastructure
   is provisioned. Their owner must also exist in the catalog.
6. Use the template editor dry run to inspect generated files without publishing.

The library Component's TechDocs annotation is `dir:../..`, relative to
`backstage/components/platform-blueprints.yaml`. It points to the root directory
containing `mkdocs.yml` and `docs/`. Generated Components keep `dir:.`, relative to
their own repositories. See the [TechDocs getting started guide](https://backstage.io/docs/features/techdocs/getting-started)
for generator and publishing setup.
