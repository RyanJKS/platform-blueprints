# Developer tools and CLI

A practical workstation checklist for working with these blueprints. Follow the
sections in order, installing only the tools for the stack you use. This is a
recommended setup order, not a requirement to install everything.

For a typical Azure and Kubernetes workflow, start with Git, GitHub CLI, `jq`,
`yq`, a container runtime, Azure CLI, `kubectl`, and Helm. Add kind for local
clusters, Terraform for infrastructure, Argo CD for GitOps, and Databricks CLI
when working with Databricks.

Use the official installation links below for your operating system. On Windows,
choose whether your tools will run in Windows or WSL2 and install them consistently
in that environment. Match versions to the project, CI configuration, and target
cluster; record working versions when a blueprint depends on them.

## 1. Workstation foundations

| Tool | Command | When needed / purpose |
| --- | --- | --- |
| Package manager: [Homebrew](https://brew.sh/), [WinGet](https://learn.microsoft.com/windows/package-manager/winget/), or your Linux distribution's package manager | `brew`, `winget`, `apt`, or `dnf` | Recommended first. Install and update tools using the option for your OS. |
| [Git](https://git-scm.com/downloads) | `git` | Essential for cloning, branches, commits, and versioned blueprints. |
| [GitHub CLI](https://cli.github.com/) | `gh` | Recommended for GitHub repositories, pull requests, workflow runs, and releases. Install Git first; authenticate with `gh auth login`. |
| [curl](https://curl.se/) | `curl` | Useful for HTTP requests, API checks, and downloads; often already installed. |
| [jq](https://jqlang.org/download/) | `jq` | Recommended for querying JSON from APIs and CLI output. |
| [yq (Mike Farah)](https://mikefarah.gitbook.io/yq/) | `yq` | Recommended for querying and editing YAML manifests, Helm values, and pipelines. Other tools named `yq` have different syntax. |
| [ripgrep](https://github.com/BurntSushi/ripgrep#installation) | `rg` | Useful for quickly finding configuration and references across repositories. |

## 2. Project runtimes and task helpers

Install the runtime required by the blueprint, rather than every language runtime.

| Tool | Command | When needed / purpose |
| --- | --- | --- |
| [mise](https://mise.jdx.dev/getting-started.html) | `mise` | Optional version manager for keeping project runtime and tool versions consistent. |
| [Python](https://www.python.org/downloads/) and [uv](https://docs.astral.sh/uv/getting-started/installation/) | `python` / `python3`, `uv` | For Python projects, including the base repository starter. uv manages Python environments and dependencies when the project uses it. |
| [Node.js LTS](https://nodejs.org/en/download) and the project's package manager | `node`, `npm`, `yarn`, or `pnpm` | For Backstage and JavaScript/TypeScript projects. Use the versions and package manager specified by the project. |
| [pre-commit](https://pre-commit.com/#install) | `pre-commit` | For repositories with `.pre-commit-config.yaml`; run the configured formatting and validation hooks locally. |
| [just](https://just.systems/man/en/) or [Make](https://www.gnu.org/software/make/) | `just` or `make` | Optional task runner; install whichever the repository's `justfile` or `Makefile` uses. |

## 3. Containers and local Kubernetes

A working container runtime comes before kind and `act`. Docker Engine or Docker
Desktop is a common choice; start it and verify `docker info` succeeds. Podman is
an alternative, but check each tool's integration requirements before substituting it.

| Tool | Command | When needed / purpose |
| --- | --- | --- |
| [Docker](https://docs.docker.com/get-started/get-docker/) | `docker` | For building and running container images and supporting local container-based tooling. |
| [Docker Compose](https://docs.docker.com/compose/install/) | `docker compose` | For multi-container local environments. Included with Docker Desktop; Linux Engine installations may need the Compose plugin. |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `kubectl` | Required to interact with Kubernetes clusters. Keep within the supported version skew of the API server, normally one minor version. |
| [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) | `kind` | Optional local Kubernetes clusters running in containers. Install a supported runtime first and use `kubectl` to interact with the cluster. |
| [Helm](https://helm.sh/docs/intro/install/) | `helm` | For packaging, rendering, and installing Kubernetes charts. Local chart rendering does not require a cluster; deployment does. |
| [Kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/) | `kubectl kustomize` or `kustomize` | For manifest overlays. Start with the version built into kubectl; install the standalone CLI if the project requires it. |
| [kubectx and kubens](https://github.com/ahmetb/kubectx#installation) | `kubectx`, `kubens` | Optional shortcuts for switching cluster contexts and namespaces. |
| [K9s](https://k9scli.io/topics/install/) | `k9s` | Optional terminal interface for inspecting workloads, events, and logs. |
| [Stern](https://github.com/stern/stern#installation) | `stern` | Optional log tailing across multiple pods. |

## 4. Cloud access and infrastructure

| Tool | Command | When needed / purpose |
| --- | --- | --- |
| [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) | `az` | For Azure resources, subscriptions, AKS credentials, and authentication. Often called azcli; the executable is `az`. Start with `az login` and confirm the intended subscription with `az account show`. |
| [Azure kubelogin](https://azure.github.io/kubelogin/install.html) | `kubelogin` | For Microsoft Entra authentication to AKS when the cluster's kubeconfig requires it. Install the Azure implementation, not another similarly named plugin. |
| [Terraform](https://developer.hashicorp.com/terraform/install) | `terraform` | For the `terraform/` blueprints as they are added. Match the configuration's required version and provider lock file. |
| [OpenTofu](https://opentofu.org/docs/intro/install/) | `tofu` | Alternative infrastructure CLI when the project explicitly supports it. Choose the project's tool; do not assume switching an existing Terraform workflow is automatic. |
| [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) | `terragrunt` | For projects using `terragrunt.hcl` to share Terraform/OpenTofu configuration and coordinate infrastructure dependencies across environments. Install the project's supported Terraform or OpenTofu version first, then match Terragrunt to the project's required version. |
| [TFLint](https://github.com/terraform-linters/tflint#installation) | `tflint` | Useful for Terraform linting and provider-specific checks using the project's rules. |
| [Azure DevOps CLI extension](https://learn.microsoft.com/azure/devops/cli/) | `az devops` | For Azure DevOps repos, pipelines, and work items. Install Azure CLI first, then add the extension with `az extension add --name azure-devops`. |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) / [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) | `aws` / `gcloud` | Only for blueprints targeting those clouds. Not needed for an Azure-only setup. |

## 5. GitOps and CI/CD

| Tool | Command | When needed / purpose |
| --- | --- | --- |
| [Argo CD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/) | `argocd` | For an existing Argo CD installation: authenticate, inspect applications, and manage syncs. The CLI does not install the Argo CD server; match its version to your deployment. |
| [act](https://nektosact.com/installation/index.html) | `act` | Optional local execution of supported GitHub Actions workflows. Requires a compatible container runtime for typical Linux jobs. Runner images, services, and authentication can differ from GitHub; still verify in GitHub Actions. |
| [actionlint](https://github.com/rhysd/actionlint/blob/main/docs/install.md) | `actionlint` | Recommended when editing GitHub Actions: checks workflow syntax and expressions without running jobs. |
| [ShellCheck](https://www.shellcheck.net/) | `shellcheck` | Useful for shell scripts in CI and developer tooling; also used by actionlint when available. |

## 6. Data platform tooling

| Tool | Command | When needed / purpose |
| --- | --- | --- |
| [Databricks CLI](https://docs.databricks.com/aws/en/dev-tools/cli/install) | `databricks` | For Databricks workspace resources, jobs, and bundle workflows. Install the current standalone CLI, rather than the legacy `databricks-cli` Python package. Configure authentication for the intended workspace. |

## 7. Validation and secrets tooling

Add these when the project's deployment or validation workflow calls for them.

| Tool | Command | When needed / purpose |
| --- | --- | --- |
| [Trivy](https://trivy.dev/latest/getting-started/installation/) | `trivy` | Scan container images, dependencies, and infrastructure configuration. |
| [Gitleaks](https://github.com/gitleaks/gitleaks#installing) | `gitleaks` | Check repositories for accidentally committed secrets. |
| [SOPS](https://github.com/getsops/sops#installation) and [age](https://github.com/FiloSottile/age#installation) | `sops`, `age` | For encrypted configuration when the project uses SOPS. age is one supported key option; cloud KMS-backed projects may not need it. |
| [kubeconform](https://github.com/yannh/kubeconform#installation) | `kubeconform` | Validate Kubernetes manifests against schemas; custom resources need appropriate schemas. |

## Check the setup before using a blueprint

1. Confirm the required tools are installed with their version commands, such as
   `git --version`, `gh --version`, `az version`, `kubectl version --client`,
   `helm version`, and `databricks version`.
2. Check GitHub authentication with `gh auth status` and Azure account selection
   with `az account show` when those services are involved.
3. For container work, check `docker info`. For cluster work, obtain the intended
   kubeconfig, then inspect `kubectl config current-context` and
   `kubectl config view --minify` before deploying anything.
4. Run the blueprint's documented local checks. Typical examples include
   `helm lint <chart-directory>`, `terraform validate` after initialization,
   and `actionlint` in a repository with GitHub Actions workflows.

Installation alone does not grant access to a cloud subscription, cluster,
Argo CD server, or Databricks workspace. Use the project's documented
authentication method and keep credentials out of committed configuration.
