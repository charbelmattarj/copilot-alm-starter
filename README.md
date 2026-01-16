# MCS ALM Starter

A lightweight ALM toolkit for Copilot Studio agents – GitHub Actions workflows, best practices, and deployment guidance.

## Overview

This repository provides everything you need to implement Application Lifecycle Management (ALM) for your Power Platform solutions, with a focus on Copilot Studio agents. It includes:

- 🚀 **GitHub Actions workflows** for export, build, and deployment
- 📁 **Recommended folder structure** for organizing solutions
- 📖 **Step-by-step guides** for common scenarios
- 🔧 **Reusable scripts** for automation

## Quick Start

1. **Use this template** - Click "Use this template" to create your own repository
2. **Configure secrets** - Set up your Power Platform credentials (see [Authentication Setup](docs/authentication.md))
3. **Export your solution** - Run the export workflow to pull your agent from the dev environment
4. **Deploy** - Push to `main` to trigger deployment to downstream environments

## Repository Structure

```
├── .github/
│   └── workflows/           # GitHub Actions workflows
│       ├── export-solution.yml
│       ├── build-and-deploy.yml
│       └── validate-pr.yml
├── docs/                    # Documentation and guides
│   ├── getting-started.md
│   ├── authentication.md
│   ├── building-agents.md
│   ├── environment-configuration.md
│   ├── local-development.md
│   └── troubleshooting.md
├── scripts/                 # Reusable PowerShell/CLI scripts
│   ├── extract-solution-metadata.ps1
│   ├── compare-solution-version.ps1
│   └── validate-solution.ps1
├── solutions/               # Your Power Platform solutions (unpacked)
│   └── <YourSolutionName>/
│       ├── botcomponents/
│       ├── bots/
│       └── Other/
└── settings/                # Environment-specific deployment settings
    ├── SolutionName_test.json
    └── SolutionName_prod.json
```

## Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `export-solution.yml` | Manual | Exports solution from dev environment and creates a PR |
| `build-and-deploy.yml` | Push to `main` | Builds and deploys solution to target environments |
| `validate-pr.yml` | Pull Request | Validates solution structure and runs checks |

## Prerequisites

- Power Platform environment(s) with Copilot Studio
- Service Principal with appropriate permissions
- GitHub repository (this template)

## Documentation

- [Getting Started Guide](docs/getting-started.md)
- [Authentication Setup](docs/authentication.md)
- [Building Copilot Studio Agents](docs/building-agents.md)
- [Environment Configuration](docs/environment-configuration.md)
- [Local Development](docs/local-development.md)
- [Troubleshooting](docs/troubleshooting.md)

## Environment Setup

### Authentication (Workload Identity Federation)

We recommend using **federated credentials** (no secrets to manage):

1. Create an App Registration
2. Add federated credentials for GitHub Actions
3. Configure as Application User in Power Platform

See [Authentication Setup](docs/authentication.md) for detailed instructions.

### Required GitHub Variables

| Variable | Description |
|----------|-------------|
| `AZURE_CLIENT_ID` | Application (client) ID from App Registration |
| `AZURE_TENANT_ID` | Your tenant ID |

### Environment Variables

For each GitHub environment (`test`, `prod`), add:

| Variable | Example | Description |
|----------|---------|-------------|
| `POWERPLATFORM_ENVIRONMENT_URL` | `https://yourorg-test.crm.dynamics.com` | Target environment URL |

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) before submitting a PR.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
