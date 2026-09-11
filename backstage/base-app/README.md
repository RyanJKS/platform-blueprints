# Base repository template

A Backstage Software Template for creating a private GitHub repository with a small Python entry point and shared repository conventions.

## Use in Backstage

1. Replace the template ownership placeholder `group:default/platform` with an existing catalog group responsible for maintaining this template.
2. Configure your Backstage GitHub integration with permission to create repositories in the target account.
3. Ensure the scaffolder provides `fetch:template`, `publish:github`, and `catalog:register`. The GitHub publish action requires the GitHub scaffolder backend module.
4. Register this folder's `template.yaml` URL through Backstage's catalog import page or catalog locations configuration.
5. Select **Base GitHub repository** in Create, then provide the GitHub destination and repository name, project display name, description, catalog owner, and GitHub code owner.

Running the template creates a private repository on the `main` branch and registers its `catalog-info.yaml` in Backstage. The GitHub code owner must already have write access; the template does not grant access.

## Included files

- `.github/workflows/ci.yaml`: pre-commit checks and Python compilation on pushes and pull requests.
- `.github/CODEOWNERS`: default ownership for all files.
- `.github/dependabot.yaml`: weekly updates for GitHub Actions and Python development dependencies.
- GitHub issue forms and a pull request template.
- `.pre-commit-config.yaml`: whitespace, YAML, merge-conflict, private-key, Ruff lint, and format checks.
- `.gitignore`, `.gitattributes`, and `.editorconfig`: shared repository conventions.
- `.python-version`, `pyproject.toml`, and `requirements-dev.txt`: Python 3.12 and development tooling.
- `src/main.py`: a runnable hello-world entry point.
- `infrastructure/.gitkeep`: a tracked placeholder for future infrastructure.
- Project README, contribution and security guidance, changelog, and architecture documentation.
- `catalog-info.yaml`: a Backstage component owned by the selected group.

The standard pre-commit filename is `.pre-commit-config.yaml`. Install its local Git hook with `pre-commit install`; CI runs the same checks even when contributors skip local hooks.

## Adapt the blueprint

Edit `skeleton/` to change generated repositories. Backstage expressions use `${{ values.name }}` syntax; workflow files are copied without rendering so GitHub Actions expressions remain intact. YAML string values use the `dump` filter to escape user input.

No deployment, cloud resources, package publishing, or license is configured. Choose a license before distributing code. After creation, configure repository access, branch protection or rulesets, required CI checks, and private vulnerability reporting. Add meaningful tests as application behavior grows.

Tag stable blueprint revisions in this repository and record the source revision when adopting the template. Existing generated repositories do not update automatically.

## GitHub destination and naming

Repositories are created in the GitHub account or organisation selected in the
`repo_url` repository picker, using the configured
Backstage GitHub integration token. The token authorizes access; it does not
select the destination. The `github` tag describes the template only.

Repository names must start with a lowercase letter and contain only lowercase
letters, digits, and single hyphens between words, with a maximum of 63 characters.
Spaces, uppercase letters, repeated hyphens, and trailing hyphens are rejected.
The repository name is also the catalog entity name. The project name is a
separate display title used in the catalog and README.

The selected catalog owner can be an existing user or group. GitHub CODEOWNERS
uses the supplied GitHub user or organisation/team, independently of the catalog
owner. The code owner must have write access; the template does not grant access.
The integration token must be able to create repositories in the selected account.
No personal account, token, or repository destination is embedded in the template.

## TechDocs

Generated components include `backstage.io/techdocs-ref: dir:.`, which points
TechDocs at the repository root containing `mkdocs.yml`. Documentation lives in
`docs/`, with a home page and an architecture page. The MkDocs configuration
uses the `techdocs-core` plugin and the supplied project title and description.

The consuming Backstage instance must enable the TechDocs frontend and backend.
For the basic local builder with `generator.runIn: docker`, the backend needs
access to a running Docker daemon. The TechDocs generator image provides MkDocs
and the TechDocs plugin; generated applications do not need them as runtime
dependencies. Open the generated component's Docs tab to build and view its docs.

See the [TechDocs getting started guide](https://backstage.io/docs/features/techdocs/getting-started)
for setup and production deployment guidance. Existing generated repositories
must adopt these files and the catalog annotation separately.
