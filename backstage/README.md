# Backstage catalog

This directory is the catalog root. It holds shared catalog metadata and software
templates, not the catalog entities created when a template runs.

```text
backstage/
  README.md
  all.yaml
  domains/
    example-platform.yaml
  systems/
    example-developer-platform.yaml
  resources/
    example-artifact-storage.yaml
  components/
    platform-blueprints.yaml
  templates/
    base-app/
      template.yaml
      skeleton/                 # Includes hidden files and generated project docs
      README.md
```

The catalog includes the library, its template, and three explicitly labeled examples:

- `components/`: applications, services, libraries, and other software. The
  `platform-blueprints` library is the only Component maintained here.
- `templates/`: scaffolding workflows, each with its definition, payload, and
  README. The `base-app` folder retains the Template identity `base-repo`.
- `domains/`: business or platform areas; includes an example platform domain.
- `systems/`: related components and resources serving a purpose; includes an example developer platform.
- `resources/`: infrastructure dependencies; includes an example storage resource.

The three entities tagged `example` demonstrate catalog organization only. They
do not describe deployed infrastructure or provision anything. No API or Group
entities are defined here. Reusable Terraform modules and payload files are not
deployed resources. Add `apis/` or `groups/` only for actual entities maintained here.

## Registration

Register the URL of `backstage/all.yaml`. Its Location entity retains the name
`platform-blueprint-templates` and explicitly targets the library Component,
Template definition, and example Domain, System, and Resource. Targets are relative to `all.yaml`; the template fetches
`./skeleton` relative to its own definition. Payload files are never Location
targets.

The root `catalog-info.yaml` remains a compatibility Location that targets
`backstage/all.yaml`. Existing root registrations can stay unchanged. Use either
the root entry point or `backstage/all.yaml`, not both. Replace earlier direct
template registrations with one entry point. Allow Component, Location, Template, Domain,
System, and Resource entities on that source. See [Backstage setup](../docs/backstage-setup.md)
for configuration and migration details.

The Component's `backstage.io/techdocs-ref: dir:../..` resolves back to the root
`mkdocs.yml` and `docs/`. Generated projects retain `dir:.` and their own root
`catalog-info.yaml`; these paths do not change when the template moves.

## Ownership and relationships

The Component, Template, and examples use `group:default/platform`. This group
is an external catalog prerequisite, not an entity defined here. Verify that it
exists in the consuming Backstage catalog, or replace all owner references with the
existing group that maintains these blueprints. Do not create a placeholder group.

The example Resource belongs to the example System, which belongs to the example
Domain. The library Component remains independent of these examples.
When adding entities, use valid entity references: `spec.owner` for ownership,
`spec.system` on Components and Resources, `spec.domain` on Systems, and supported
`spec.dependsOn` references for actual dependencies. Resolve references through
this Location or an existing catalog source. Avoid duplicate identities.

## Add a template or entity

1. Put a template in `templates/<folder>/` with `template.yaml`, `README.md`, and
   its payload directory (normally `skeleton/`). Keep fetch paths relative to the
   template. Preserve entity name and namespace when moving existing entities.
2. Put another real entity in the folder matching its kind. Create that folder
   when the first entity is needed.
3. Add an explicit relative file target to `all.yaml`. Never target scaffold
   files, generated catalogs, or entire payload directories.
4. Check YAML, target resolution, unique identities, owner and relationship
   references, and template rendering. Follow [validation guidance](../docs/maintaining-templates.md).
5. Push the change to the registered revision and refresh the Location in Backstage.

## Metadata boundaries

This repository owns the blueprint library's metadata and scaffolding workflows.
Application repositories own their generated Component metadata, owners,
lifecycle, system membership, dependencies, APIs, and TechDocs. The skeleton
provides initial metadata; each application maintains it after generation.
Changing a blueprint does not update existing applications.

## View or replace the examples

Refresh the registered Location after pushing these files. In the catalog, select
**Domain**, **System**, or **Resource** in the Kind filter. If the ownership filter
hides them, select **All**. The examples appear in the catalog, not on the Create
page. Their entity pages expose the system and domain relationships.

Copy an example file to add your own entity, give it a unique name, remove the
`example` tag, and update the description, owner, and relationships. Register the
new file explicitly in `all.yaml`. References must name existing catalog entities.
To remove the examples, delete their three targets from `all.yaml` and their
files. Backstage may retain orphaned entities depending on catalog settings.
