# Getting Started

This guide will help you set up ALM (Application Lifecycle Management) for your Copilot Studio agents and Power Platform solutions.

This starter kit supports both **GitHub Actions** and **Azure DevOps Pipelines**. Follow the path that matches your CI/CD platform.

## Prerequisites

Before you begin, ensure you have:

- [ ] A Power Platform environment with Copilot Studio
- [ ] Admin access to create App Registrations (or work with your IT admin)
- [ ] **GitHub** account **or** access to an **Azure DevOps** project
- [ ] Basic familiarity with Git

## Step 1: Create Your Repository

### GitHub

1. Click **"Use this template"** on the GitHub repository page
2. Name your repository (e.g., `my-company-agents`)
3. Choose visibility (private recommended for production solutions)
4. Click **Create repository from template**

### Azure DevOps

1. Create a new repository in your Azure DevOps project
2. Clone this starter kit and push it to your new repo:
   ```bash
   git clone https://github.com/microsoft/mcs-alm-starter.git my-company-agents
   cd my-company-agents
   git remote set-url origin https://dev.azure.com/yourorg/yourproject/_git/my-company-agents
   git push -u origin --all
   ```
3. You can safely delete the `.github/` folder if you only use Azure DevOps (and vice versa)

## Step 2: Set Up Authentication

Both platforms require a **Service Principal** (App Registration) with access to your Power Platform environments.

### Common Steps (Both Platforms)

1. Create an App Registration in Microsoft Entra ID
2. Note the **Application (client) ID** and **Directory (tenant) ID**
3. In each Power Platform environment, add the App Registration as an **Application User** with **System Administrator** role

### GitHub – Federated Credentials (Recommended)

4. Add federated credentials to the App Registration for your GitHub repo
5. Add `AZURE_CLIENT_ID` and `AZURE_TENANT_ID` as **repository variables** (not secrets)
6. Add `POWERPLATFORM_ENVIRONMENT_URL` as an **environment variable** in each GitHub environment

See [Authentication Setup](authentication.md) for detailed instructions.

### Azure DevOps – Service Connections

4. Create a **client secret** for the App Registration (or use a certificate)
5. In Azure DevOps, go to **Project Settings > Service connections**
6. Create a **Power Platform** service connection for each environment
7. Update `.pipelines/environment-variables.yml` with your connection names and URLs

See [Azure DevOps Setup](azure-devops-setup.md) for detailed instructions.

## Step 3: Configure Environments

### GitHub Environments

Create environments in your repository settings (`Settings > Environments`):

| Environment | Purpose | Protection Rules |
|-------------|---------|------------------|
| `dev` | Export source | — |
| `test` | Pre-production testing | Optional reviewers |
| `prod` | Production | Required reviewers |

### Azure DevOps Environments

Create environments in **Pipelines > Environments**:

| Environment | Purpose | Approvals |
|-------------|---------|-----------|
| `test` | Pre-production testing | Optional |
| `prod` | Production | Required approvals + checks |

> 💡 For Azure DevOps, also update the `targetEnvironments` parameter in `.pipelines/build-and-deploy.yml`.

## Step 4: Export Your First Solution

### GitHub

1. Go to the **Actions** tab in your repository
2. Select **Export Solution** workflow
3. Click **Run workflow**
4. Fill in:
   - **Solution name**: Your solution's unique name (from Copilot Studio)
   - **Environment URL**: Your dev environment URL
5. Click **Run workflow**

### Azure DevOps

1. Go to **Pipelines** and create a new pipeline from `.pipelines/export-solution.yml`
2. Run the pipeline with:
   - **Solution name**: Your solution's unique name
   - **Environment URL**: (optional – defaults to `authorEnvironmentUrl` in variables)

Both platforms will:
- Export your solution
- Unpack it to the `solutions/` folder
- Create a Pull Request with the changes

## Step 5: Review and Merge

1. Review the PR created by the export pipeline
2. Check the solution components are correct
3. Verify no unintended changes
4. Merge to `main`

## Step 6: Deploy

Once merged to `main`, the **Build and Deploy** pipeline automatically:
1. Builds the solution (packs it into a `.zip`)
2. Deploys to the first target environment (usually `test`)

For production deployment:
- **GitHub**: Manually trigger the workflow and select `prod`
- **Azure DevOps**: The pipeline automatically promotes through environments (with approval gates)

## Next Steps

- [Building Copilot Studio Agents](building-agents.md) – Best practices for agent development
- [Environment Configuration](environment-configuration.md) – Deployment settings, connection references
- [Azure DevOps Setup](azure-devops-setup.md) – Azure DevOps-specific configuration
- [Troubleshooting](troubleshooting.md) – Common issues and solutions

## Folder Structure Explained

```
your-repo/
├── .github/workflows/     # GitHub Actions pipelines
├── .pipelines/            # Azure DevOps pipelines
├── docs/                  # Documentation
├── scripts/               # Reusable PowerShell scripts (both platforms)
├── solutions/             # Your unpacked solutions
│   └── MySolution/
│       ├── botcomponents/ # Agent topics, actions, etc.
│       ├── bots/          # Agent definitions
│       ├── Connectors/    # Custom connectors
│       └── Other/         # Solution metadata (Solution.xml)
└── settings/              # Deployment settings per environment
    ├── MySolution_test.json
    └── MySolution_prod.json
```

## Common Commands

### Power Platform CLI

```bash
# Install the CLI (choose one method):

# Option 1: .NET Tool (cross-platform – recommended)
dotnet tool install --global Microsoft.PowerApps.CLI.Tool

# Option 2: Download installer from Microsoft
# https://aka.ms/PowerAppsCLI

# Verify installation
pac --version

# Export a solution
pac solution export --name YourSolution --path ./export --managed false

# Unpack a solution
pac solution unpack --zipfile ./export/YourSolution.zip --folder ./solutions/YourSolution

# Pack a solution
pac solution pack --folder ./solutions/YourSolution --zipfile ./output/YourSolution.zip
```

### Git Workflow

```bash
# Create a feature branch
git checkout -b feature/new-topic

# After making changes in Copilot Studio, run the export workflow/pipeline

# Review and commit
git add .
git commit -m "feat: add customer support topic"
git push origin feature/new-topic
```

## Getting Help

- Check the [Local Development Guide](local-development.md) for testing commands locally
- Check the [Troubleshooting Guide](troubleshooting.md)
- Open a GitHub Issue or Azure DevOps Work Item
- Review [Power Platform documentation](https://learn.microsoft.com/power-platform/alm/)
