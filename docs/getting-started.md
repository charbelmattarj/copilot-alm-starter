# Getting Started

This guide will help you set up ALM (Application Lifecycle Management) for your Copilot Studio agents and Power Platform solutions.

## Prerequisites

Before you begin, ensure you have:

- [ ] A Power Platform environment with Copilot Studio
- [ ] Admin access to create App Registrations (or work with your IT admin)
- [ ] A GitHub account
- [ ] Basic familiarity with Git and GitHub

## Step 1: Create Your Repository

1. Click **"Use this template"** on the GitHub repository page
2. Name your repository (e.g., `my-company-agents`)
3. Choose visibility (private recommended for production solutions)
4. Click **Create repository from template**

## Step 2: Set Up Authentication

See [Authentication Setup](authentication.md) for detailed instructions on configuring Workload Identity Federation.

**Quick summary (federated credentials - recommended):**
1. Create an App Registration
2. Add federated credentials for your GitHub repo
3. Grant Power Platform permissions (Application User)
4. Add variables to GitHub (no secrets needed!)

**Why federated credentials?**
- ✅ No secrets to rotate
- ✅ More secure (short-lived tokens)
- ✅ Easier maintenance

## Step 3: Configure Environments

### GitHub Environments

Create environments in your repository settings (`Settings > Environments`):

| Environment | Purpose | Protection Rules |
|-------------|---------|------------------|
| `test` | Pre-production testing | Optional reviewers |
| `prod` | Production | Required reviewers |

### Repository Variables

Add these at the repository level (`Settings > Secrets and variables > Actions > Variables`):

| Variable | Example |
|----------|---------|
| `AZURE_CLIENT_ID` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_TENANT_ID` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |

### Environment Variables

For each environment, add:

| Variable | Example |
|----------|---------|
| `POWERPLATFORM_ENVIRONMENT_URL` | `https://yourorg-test.crm.dynamics.com` |

## Step 4: Export Your First Solution

1. Go to **Actions** tab in your repository
2. Select **Export Solution** workflow
3. Click **Run workflow**
4. Fill in:
   - **Solution name**: Your solution's unique name (from Copilot Studio)
   - **Environment URL**: Your dev environment URL
5. Click **Run workflow**

The workflow will:
- Export your solution
- Unpack it to the `solutions/` folder
- Create a Pull Request

## Step 5: Review and Merge

1. Review the PR created by the export workflow
2. Check the solution components are correct
3. Merge to `main`

## Step 6: Deploy

Once merged to `main`, the **Build and Deploy** workflow automatically:
1. Builds the solution
2. Deploys to the `test` environment

For production deployment, manually trigger the workflow and select `prod`.

## Next Steps

- [Building Copilot Studio Agents](building-agents.md) - Best practices for agent development
- [Environment Configuration](environment-configuration.md) - Advanced deployment settings
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

## Folder Structure Explained

```
your-repo/
├── .github/workflows/     # CI/CD pipelines
├── docs/                  # Documentation
├── scripts/               # Utility scripts
├── solutions/             # Your unpacked solutions
│   └── MySolution/
│       ├── botcomponents/ # Agent topics, actions, etc.
│       ├── bots/          # Agent definitions
│       ├── Connectors/    # Custom connectors
│       └── Other/         # Solution metadata
└── settings/              # Deployment settings per environment
```

## Common Commands

### Power Platform CLI

```bash
# Install the CLI (choose one method):

# Option 1: .NET Tool (cross-platform - recommended)
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

# After making changes in Copilot Studio, run the export workflow

# Review and commit
git add .
git commit -m "feat: add customer support topic"
git push origin feature/new-topic
```

## Getting Help

- Check the [Local Development Guide](local-development.md) for testing commands locally
- Check the [Troubleshooting Guide](troubleshooting.md)
- Open a GitHub Issue
- Review Power Platform documentation
