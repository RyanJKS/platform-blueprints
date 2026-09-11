# Backstage setup

## Requirements

- A Backstage catalog group that maintains this repository. Replace
  `group:default/platform` in the root Component and in template descriptors with
  that group's entity reference.
- A GitHub integration that can read this repository and create repositories in
  the destinations chosen by template users.
- Scaffolder actions `fetch:template`, `publish:github`, and `catalog:register`.
- TechDocs frontend and backend support. The local Docker generator needs access
  to a running Docker daemon.

## Register the root descriptor

Register the repository's root `catalog-info.yaml` URL using Backstage's catalog
import page. Use the GitHub file URL, including its branch:

```text
https://github.com/<account>/<repository>/blob/<branch>/catalog-info.yaml
```

The descriptor contains two entities: a Component representing this library and
a Location that references its software templates. The catalog's location rules
must allow `Component`, `Location`, and `Template` for this source. When using
configuration-based registration, the entry can look like this:

```yaml
catalog:
  locations:
    - type: url
      target: https://github.com/<account>/<repository>/blob/<branch>/catalog-info.yaml
      rules:
        - allow: [Component, Location, Template]
```

Replace the placeholders and merge the entry with existing locations. Location
arrays in a configuration override replace the earlier array, so preserve other
required entries such as catalog users and groups.

For local development, a `type: file` location can point to the root descriptor.
Resolve its path relative to the backend process's working directory, not the
configuration file. GitHub URL registration makes the source accessible without
requiring the blueprint repository to exist on the backend filesystem.

## Verify registration

1. Find **Platform Blueprints** in the catalog.
2. Open its **Docs** tab to build and read this documentation.
3. Find **Base GitHub repository** on the Create page.
4. Check catalog processing errors if an entity is missing. Confirm source access,
   allowed kinds, owner references, and the Location's relative template paths.

After the root source is working, remove any earlier direct registration of the
same template to avoid maintaining duplicate sources. Removing a catalog source
does not delete GitHub repositories.

The TechDocs annotation is `backstage.io/techdocs-ref: dir:.`; it points to the
root directory containing `mkdocs.yml`. The `techdocs-core` plugin belongs in that
configuration. See the [TechDocs getting started guide](https://backstage.io/docs/features/techdocs/getting-started)
for generator and publishing setup.
