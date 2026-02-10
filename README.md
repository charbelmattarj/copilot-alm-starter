# Copilot ALM Starter

A lightweight ALM toolkit for Copilot Studio agents – CI/CD pipelines, best practices, and deployment guidance for **both GitHub Actions and Azure DevOps Pipelines**.

## Overview

This repository provides everything you need to implement Application Lifecycle Management (ALM) for your Power Platform solutions, with a focus on Copilot Studio agents. It includes:

- 🚀 **CI/CD pipelines** for export, build, and deployment (GitHub Actions **and** Azure DevOps)
- 📁 **Recommended folder structure** for organizing solutions
- 📖 **Step-by-step guides** for common scenarios
- 🔧 **Reusable scripts** for automation (work across both platforms)

## Quick Start

1. **Use this template** – Click "Use this template" (GitHub) or import to your Azure DevOps project
2. **Pick your CI/CD platform** – Use the workflows in `.github/workflows/` **or** `.pipelines/`
3. **Configure authentication** – Set up credentials for your Power Platform environments (see [Authentication Setup](docs/authentication.md))
4. **Export your solution** – Run the export pipeline to pull your agent from the dev environment
5. **Deploy** – Push to `main` to trigger deployment to downstream environments

> 💡 **New to ALM for Power Platform?** Start with the [Getting Started Guide](docs/getting-started.md).

## Repository Structure

| Folder | Description |
|--------|-------------|
| `.github/workflows/` | GitHub Actions workflows (export, build & deploy, PR validation) |
| `.pipelines/` | Azure DevOps pipeline definitions and shared variables |
| `docs/` | Documentation and step-by-step guides |
| `scripts/` | Reusable PowerShell scripts (work across both CI/CD platforms) |
| `solutions/` | Your Power Platform solutions (unpacked source) |
| `settings/` | Environment-specific deployment settings (per solution, per environment) |

## Pipelines

### GitHub Actions

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `export-solution.yml` | Manual | Exports solution from dev environment and creates a PR |
| `build-and-deploy.yml` | Push to `main` | Builds and deploys solution to target environments |
| `validate-pr.yml` | Pull Request | Validates solution structure and runs checks |

### Azure DevOps Pipelines

| Pipeline | Trigger | Description |
|----------|---------|-------------|
| `export-solution.yml` | Manual | Exports solution from dev environment and creates a PR |
| `build-and-deploy.yml` | Push to `main` | Builds and deploys solution to target environments |
| `validate-pr.yml` | Pull Request | Validates solution structure and runs checks |

> See [Azure DevOps Setup](docs/azure-devops-setup.md) for detailed configuration instructions.

## Prerequisites

- Power Platform environment(s) with Copilot Studio
- Service Principal / App Registration with appropriate permissions
- **GitHub** repository (this template) **or Azure DevOps** project with Repos + Pipelines

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/getting-started.md) | End-to-end setup for first-time users |
| [Authentication Setup](docs/authentication.md) | Federated credentials (GitHub) and Workload Identity Federation (Azure DevOps) |
| [Azure DevOps Setup](docs/azure-devops-setup.md) | Azure DevOps-specific pipeline and environment configuration |
| [Building Copilot Studio Agents](docs/building-agents.md) | Best practices for agent development |
| [Environment Configuration](docs/environment-configuration.md) | Deployment settings, connection references, environment variables |
| [Local Development](docs/local-development.md) | Running commands locally and testing |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and solutions |

## Environment Setup

### Option A: GitHub Actions (Workload Identity Federation)

We recommend using **federated credentials** (no secrets to manage):

1. Create an App Registration
2. Add federated credentials for GitHub Actions
3. Configure as Application User in Power Platform
4. Add variables to GitHub

See [Authentication Setup](docs/authentication.md) for detailed instructions.

#### Required GitHub Variables

| Variable | Description |
|----------|-------------|
| `AZURE_CLIENT_ID` | Application (client) ID from App Registration |
| `AZURE_TENANT_ID` | Your tenant ID |

#### Environment Variables (per GitHub environment)

| Variable | Example | Description |
|----------|---------|-------------|
| `POWERPLATFORM_ENVIRONMENT_URL` | `https://yourorg-test.crm.dynamics.com` | Target environment URL |

### Option B: Azure DevOps (Workload Identity Federation)

Use **Workload Identity Federation (WIF) service connections** in Azure DevOps (recommended) – no secrets to manage:

1. Create an App Registration
2. Create WIF Service Connections in your Azure DevOps project
3. Configure as Application User in Power Platform
4. Update `.pipelines/environment-variables.yml`

See [Azure DevOps Setup](docs/azure-devops-setup.md) for detailed instructions.

#### Pipeline Variables (`.pipelines/environment-variables.yml`)

| Variable | Description |
|----------|-------------|
| `authorEnvironmentUrl` | Development environment URL |
| `authorServiceConnection` | Service connection name for dev |

#### Target Environments (`.pipelines/build-and-deploy.yml`)

Configure directly in the `targetEnvironments` parameter:

| Property | Description |
|----------|-------------|
| `environmentUrl` | Target environment URL |
| `serviceConnectionName` | Service connection for that environment |

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) before submitting a PR.

## License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.
