# Platform Blueprints

Platform Blueprints holds reusable software templates and engineering conventions.
It is a library of starting points, not a running application.

## Available blueprint

**Base GitHub repository** creates a private GitHub repository with a Python
starter, repository checks, ownership files, and Backstage catalog metadata.
The form collects the GitHub destination and repository name, project display
name, description, catalog owner, and GitHub code owner.

Generated repositories include their own TechDocs configuration, documentation
pages, and a documentation-maintainer skill with repository instructions.

## Where to start

- [Register the repository in Backstage](backstage-setup.md) to browse this library
  in the catalog, read its TechDocs, and use its templates from Create.
- [Maintain templates](maintaining-templates.md) to add blueprints and understand
  how changes affect newly generated and existing repositories.

## Two documentation sites

The root `mkdocs.yml` and `docs/` describe this blueprint library. Files under
`backstage/base-app/skeleton/` are copied into newly generated repositories;
their documentation describes those projects. Keep these purposes separate.
