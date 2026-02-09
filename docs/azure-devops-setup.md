# Azure DevOps Setup Guide

This guide walks you through setting up the Azure DevOps pipelines included in this starter kit. If you're using GitHub Actions, see [Getting Started](getting-started.md) instead.

## Prerequisites

- An Azure DevOps project with **Repos** and **Pipelines** enabled
- **Power Platform Build Tools** extension installed in your Azure DevOps organization
- An App Registration with Power Platform permissions (see [Authentication](authentication.md))
- At least one Power Platform development environment

---

## Step 1: Install Power Platform Build Tools

The pipelines require the **Power Platform Build Tools** extension from the Visual Studio Marketplace.

1. Go to [Power Platform Build Tools](https://marketplace.visualstudio.com/items?itemName=microsoft-IsvExpTools.PowerPlatform-BuildTools)
2. Click **Get it free**
3. Select your Azure DevOps organization
4. Click **Install**

> 💡 You need **Organization Administrator** permissions to install extensions.

---

## Step 2: Create Service Connections

Create a Power Platform service connection for each environment.

### Recommended: Workload Identity Federation

Workload Identity Federation (WIF) is the recommended authentication method. It eliminates client secrets entirely.

For each environment (`dev`, `test`, `prod`):

1. Go to **Project Settings > Service connections**
2. Click **New service connection**
3. Select **Power Platform**
4. Choose **Workload Identity Federation (automatic)** as the authentication method
5. Fill in:
   - **Server URL**: Your environment URL (e.g., `https://yourorg-dev.crm.dynamics.com`)
   - **Tenant ID**: Your Entra ID tenant ID
   - **Application (client) ID**: From your App Registration
   - **Service connection name**: Use a consistent naming convention (see table below)
6. Click **Save**

> 💡 If **automatic** is not available, choose **Workload Identity Federation (manual)** and add the federated credential to your App Registration in Entra ID. See [Authentication](authentication.md) for details.

### Fallback: Client Secret

If WIF is not available (e.g., Entra ID tenant not connected to Azure DevOps):

1. Go to **Project Settings > Service connections**
2. Click **New service connection**
3. Select **Power Platform**
4. Fill in:
   - **Server URL**: Your environment URL (e.g., `https://yourorg-dev.crm.dynamics.com`)
   - **Tenant ID**: Your Entra ID tenant ID
   - **Application (client) ID**: From your App Registration
   - **Client Secret**: Your App Registration client secret
   - **Service connection name**: Use a consistent naming convention

> ⚠️ Client secrets expire (max 24 months). Set a calendar reminder to rotate before expiration.

### Recommended Naming Convention

| Environment | Service Connection Name | Server URL |
|-------------|------------------------|------------|
| Dev | `powerplatform-dev` | `https://yourorg-dev.crm.dynamics.com` |
| Test | `powerplatform-test` | `https://yourorg-test.crm.dynamics.com` |
| Prod | `powerplatform-prod` | `https://yourorg-prod.crm.dynamics.com` |

### Pipeline Permissions

For each service connection, choose one:

- **Grant access to all pipelines** – Simplest, allows any pipeline to use it
- **Per-pipeline authorization** – More secure, authorize each pipeline individually

> ⚠️ For production service connections, consider per-pipeline authorization.

---

## Step 3: Create Pipelines

### 3a. Import the Repository

If your code is not already in Azure Repos:

1. Go to **Repos > Files**
2. Click **Import** to import from an existing Git repository, or push your local clone:

```shell
git remote add azure https://dev.azure.com/yourorg/yourproject/_git/yourrepo
git push azure --all
```

### 3b. Create Each Pipeline

For each pipeline file in `.pipelines/`:

1. Go to **Pipelines > Pipelines**
2. Click **New pipeline**
3. Select **Azure Repos Git**
4. Select your repository
5. Choose **Existing Azure Pipelines YAML file**
6. Select the pipeline file from the dropdown:
   - `.pipelines/export-solution.yml`
   - `.pipelines/build-and-deploy.yml`
   - `.pipelines/validate-pr.yml`
7. Click **Continue**, then **Save** (don't run yet)
8. Rename the pipeline to something descriptive (click the **⋮** menu > **Rename**)

### Recommended Pipeline Names

| YAML File | Suggested Name |
|-----------|---------------|
| `export-solution.yml` | Export Solution |
| `build-and-deploy.yml` | Build and Deploy |
| `validate-pr.yml` | Validate PR |

---

## Step 4: Configure Pipeline Variables

### 4a. Update Environment Variables

Edit `.pipelines/environment-variables.yml` with your values:

```yaml
variables:
  - name: serviceName
    value: "YourServiceName"          # Used for pipeline display names
  - name: authorEnvironmentUrl
    value: "https://yourorg-dev.crm.dynamics.com"
  - name: authorServiceConnection
    value: "powerplatform-dev"        # Must match service connection name
  - name: targetBranch
    value: "main"
  - name: solutionRootFolder
    value: "solutions"
  - name: maxAsyncWaitTime
    value: 60
```

### 4b. Update Build and Deploy Parameters

Edit the defaults in `.pipelines/build-and-deploy.yml`:

```yaml
parameters:
  - name: solutions
    type: object
    default:
      - solutionName: "YourSolution"
        displayName: "Your Solution"
        dependsOnSolutions: []
        useDeploymentSettingsFile: true

  - name: targetEnvironments
    type: object
    default:
      - environmentName: "test"
        displayName: "Test"
        environmentUrl: "https://yourorg-test.crm.dynamics.com"
        serviceConnectionName: "powerplatform-test"
      - environmentName: "prod"
        displayName: "Production"
        environmentUrl: "https://yourorg-prod.crm.dynamics.com"
        serviceConnectionName: "powerplatform-prod"
```

### 4c. Multiple Solutions

If your repo contains multiple solutions with dependencies:

```yaml
- name: solutions
  type: object
  default:
    - solutionName: "CoreSolution"
      dependsOnSolutions: []
    - solutionName: "AgentSolution"
      dependsOnSolutions:
        - "CoreSolution"
```

The pipeline builds and deploys them in the correct order.

---

## Step 5: Create Azure DevOps Environments

Environments provide deployment protection and traceability.

### Create Environments

1. Go to **Pipelines > Environments**
2. Click **New environment**
3. Create:
   - `test` – For QA/testing deployments
   - `prod` – For production deployments

### Configure Approvals (Production)

1. Click on the `prod` environment
2. Click **Approvals and checks** (top-right menu)
3. Add **Approvals**:
   - Select one or more required approvers
   - Optionally set "Allow approvers to approve their own runs" to **No**
4. Add additional checks as needed:
   - **Business hours** – Only deploy during working hours
   - **Exclusive lock** – Prevent concurrent deployments

---

## Step 6: Set Up Branch Policies

Configure branch policies to enforce PR validation.

### Build Validation

1. Go to **Repos > Branches**
2. Click the **⋮** menu on `main` > **Branch policies**
3. Under **Build validation**, click **Add build policy**
4. Configure:
   - **Build pipeline**: Select `Validate PR`
   - **Trigger**: Automatic
   - **Policy requirement**: Required
   - **Build expiration**: 12 hours (or your preference)

### Additional Policies

Consider enabling:

- **Require a minimum number of reviewers** (at least 1)
- **Check for linked work items** (for traceability)
- **Check for comment resolution** (all comments must be resolved)
- **Limit merge types** (squash merge recommended)

---

## Step 7: Verify Everything Works

### Test the Export Pipeline

1. Go to **Pipelines** and find **Export Solution**
2. Click **Run pipeline**
3. Enter your solution name
4. Verify:
   - ✅ Connection to Power Platform succeeds
   - ✅ Solution is exported and unpacked
   - ✅ A pull request is created

### Test the Build and Deploy Pipeline

1. Merge the export PR (or push solution files to `main`)
2. The **Build and Deploy** pipeline should trigger automatically
3. Verify:
   - ✅ Solution is packed from source
   - ✅ Deployment to `test` succeeds
   - ✅ Deployment to `prod` waits for approval (if configured)

### Test PR Validation

1. Create a branch and modify a file in `solutions/`
2. Open a pull request to `main`
3. Verify:
   - ✅ **Validate PR** pipeline triggers automatically
   - ✅ Solution validation passes
   - ✅ PR status check is reported

---

## Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  Export Solution Pipeline                                         │
│  (Manual trigger)                                                │
│                                                                  │
│  Dev Environment ──▶ Export ──▶ Unpack ──▶ Commit ──▶ Create PR  │
└──────────────────────────────────────────────────────────────────┘
                                    │
                              Pull Request
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────┐
│  Validate PR Pipeline                                            │
│  (PR trigger)                                                    │
│                                                                  │
│  Detect Changes ──▶ Validate Structure ──▶ Test Pack             │
└──────────────────────────────────────────────────────────────────┘
                                    │
                               Merge to main
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────┐
│  Build and Deploy Pipeline                                       │
│  (CI trigger on main)                                            │
│                                                                  │
│  Pack Solution ──▶ Publish Artifact ──▶ Deploy Test ──▶ Deploy   │
│                                         (auto)        Prod       │
│                                                       (approval) │
└──────────────────────────────────────────────────────────────────┘
```

---

## Build Service Permissions

The pipelines create pull requests using the Azure DevOps REST API. The **Build Service** identity needs permissions to do this.

### Grant PR Creation Permissions

1. Go to **Project Settings > Repositories**
2. Select your repository
3. Click the **Security** tab
4. Find the **\<Project Name\> Build Service** identity
5. Set the following permissions to **Allow**:
   - **Contribute** – To push branches
   - **Contribute to pull requests** – To create PRs
   - **Create branch** – To create the export branch

> 💡 If you don't see the Build Service identity, run one of the pipelines first — it will appear after the first run.

---

## Troubleshooting

### Pipeline doesn't trigger on PR

- Verify branch policies are configured (Step 6)
- Check the pipeline YAML has the correct `pr` trigger
- Ensure the pipeline is enabled (not paused)

### "Could not find a pool with name 'windows-latest'"

- The pipelines use Microsoft-hosted agents
- Ensure your organization has available parallel jobs
- Check **Organization Settings > Pipelines > Parallel jobs**

### Service connection authorization prompt

- When a pipeline first uses a service connection, it may pause for authorization
- Click **View** on the pipeline run and approve the connection
- To avoid this, pre-authorize from **Service connection > Pipeline permissions**

### Export pipeline PR creation fails

- Check Build Service permissions (see above)
- Verify `System.AccessToken` is available (it is by default in YAML pipelines)
- Check the target branch exists

### Settings file not found during deployment

- Ensure settings files are committed to the repository
- Check the file naming convention: `SolutionName_environmentName.json`
- Verify the path in the pipeline matches the actual folder structure

---

## Next Steps

- [Authentication](authentication.md) – Set up service principal and service connections
- [Environment Configuration](environment-configuration.md) – Configure settings files
- [Building Agents](building-agents.md) – Develop Copilot Studio agents
- [Local Development](local-development.md) – Set up your local environment
- [Troubleshooting](troubleshooting.md) – Common issues and solutions
