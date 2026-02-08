# Authentication Setup

This guide explains how to set up authentication for automated deployments to Power Platform environments.

Both **GitHub Actions** and **Azure DevOps Pipelines** are supported. Choose the section that matches your platform, or read both if you're evaluating options.

## Overview

| Platform | Recommended Auth Method | Secret Management |
|----------|------------------------|-------------------|
| **GitHub Actions** | Workload Identity Federation (federated credentials) | No secrets to manage |
| **Azure DevOps** | Power Platform Service Connection (SPN) | Client secret stored in service connection |

Both approaches use a **Service Principal** (App Registration) under the hood.

---

## Step 1: Create an App Registration (Both Platforms)

1. Navigate to [Microsoft Entra ID > App registrations](https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade)
2. Click **New registration**
3. Configure:
   - **Name**: `PowerPlatform-ALM` (or your preferred name)
   - **Supported account types**: Single tenant
   - **Redirect URI**: Leave blank
4. Click **Register**
5. Note the **Application (client) ID** and **Directory (tenant) ID**

## Step 2: Grant Power Platform Permissions (Both Platforms)

For each environment you want to deploy to:

1. Go to the [Power Platform Admin Center](https://admin.powerplatform.microsoft.com/)
2. Select the environment
3. Go to **Settings > Users + permissions > Application users**
4. Click **New app user**
5. Select your App Registration
6. Assign the **System Administrator** security role

---

## GitHub Actions: Workload Identity Federation

This is the recommended approach for GitHub Actions. **No client secrets needed.**

- ✅ **No secrets to manage** – No client secrets to rotate
- ✅ **More secure** – Short-lived tokens, no long-lived credentials
- ✅ **Easier maintenance** – No secret expiration issues

### Configure Federated Credentials

1. In your App Registration, go to **Certificates & secrets**
2. Select the **Federated credentials** tab
3. Click **Add credential**
4. Select **GitHub Actions deploying Azure resources**
5. Configure:
   - **Organization**: Your GitHub organization or username
   - **Repository**: Your repo name
   - **Entity type**: Choose based on your needs:
     - `Environment` – For GitHub environment-based deployments (recommended)
     - `Branch` – For deployments from a specific branch (e.g., `main`)
     - `Pull Request` – For PR validation workflows
   - **Name**: Descriptive name (e.g., `github-env-test`)
6. Click **Add**

#### Recommended Federated Credentials

Create multiple federated credentials for different scenarios:

| Name | Entity Type | Value | Use Case |
|------|-------------|-------|----------|
| `github-env-dev` | Environment | `dev` | Export from dev |
| `github-env-test` | Environment | `test` | Deploy to test |
| `github-env-prod` | Environment | `prod` | Deploy to production |
| `github-pr` | Pull Request | — | PR validation |

### Configure GitHub

#### Repository Variables (Not Secrets!)

Go to **Settings > Secrets and variables > Actions > Variables**:

| Variable Name | Value |
|---------------|-------|
| `AZURE_CLIENT_ID` | Application (client) ID |
| `AZURE_TENANT_ID` | Directory (tenant) ID |

#### Environment Variables

For each GitHub environment (`dev`, `test`, `prod`):

| Variable Name | Example Value |
|---------------|---------------|
| `POWERPLATFORM_ENVIRONMENT_URL` | `https://yourorg-test.crm.dynamics.com` |

### How It Works (GitHub)

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  GitHub Actions  │────▶│  Microsoft       │────▶│  Power Platform │
│  (OIDC Token)    │     │  Entra ID        │     │  Environment    │
└─────────────────┘     └──────────────────┘     └─────────────────┘
        │                        │                        │
        │  1. Request token      │                        │
        │  with claims           │                        │
        │ ─────────────────────▶ │                        │
        │                        │  2. Validate claims    │
        │                        │     match federated    │
        │                        │     credential         │
        │  3. Issue access token │                        │
        │ ◀───────────────────── │                        │
        │                        │                        │
        │  4. Authenticate to Power Platform              │
        │ ───────────────────────────────────────────────▶│
```

### Workflow Configuration (GitHub)

```yaml
jobs:
  deploy:
    runs-on: windows-latest
    environment: test  # Must match federated credential entity
    
    permissions:
      id-token: write    # Required for OIDC
      contents: read
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login (Federated)
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          allow-no-subscriptions: true
      
      - name: Install Power Platform CLI
        uses: microsoft/powerplatform-actions/actions-install@v1
      
      - name: Authenticate to Power Platform
        shell: pwsh
        run: |
          pac auth create --environment ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
```

---

## Azure DevOps: Service Connections

For Azure DevOps, use **Power Platform Service Connections**.

### Create a Client Secret

1. In your App Registration, go to **Certificates & secrets**
2. Click **New client secret**
3. Set expiration (max 24 months)
4. **Copy the secret value immediately** – you won't see it again

### Create Service Connections

For each Power Platform environment:

1. In Azure DevOps, go to **Project Settings > Service connections**
2. Click **New service connection**
3. Select **Power Platform**
4. Fill in:
   - **Server URL**: e.g., `https://yourorg-test.crm.dynamics.com`
   - **Tenant ID**: Your directory (tenant) ID
   - **Application (client) ID**: From App Registration
   - **Client Secret**: The secret value you copied
   - **Service connection name**: e.g., `powerplatform-test` (use this name in your pipelines)
5. Check **Grant access to all pipelines** (or manage per-pipeline)
6. Click **Save**

Repeat for each environment (`dev`, `test`, `prod`).

### Configure Pipeline Variables

Update `.pipelines/environment-variables.yml`:

```yaml
variables:
  - name: authorEnvironmentUrl
    value: "https://yourorg-dev.crm.dynamics.com"
  - name: authorServiceConnection
    value: "powerplatform-dev"
```

Update the `targetEnvironments` parameter in `.pipelines/build-and-deploy.yml`:

```yaml
- environmentName: "test"
  environmentUrl: "https://yourorg-test.crm.dynamics.com"
  serviceConnectionName: "powerplatform-test"
- environmentName: "prod"
  environmentUrl: "https://yourorg-prod.crm.dynamics.com"
  serviceConnectionName: "powerplatform-prod"
```

### How It Works (Azure DevOps)

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Azure DevOps   │────▶│  Microsoft       │────▶│  Power Platform │
│  Pipeline       │     │  Entra ID        │     │  Environment    │
└─────────────────┘     └──────────────────┘     └─────────────────┘
        │                        │                        │
        │  1. Service Connection │                        │
        │  provides SPN creds   │                        │
        │ ─────────────────────▶ │                        │
        │                        │  2. Validate client    │
        │                        │     ID + secret        │
        │  3. Issue access token │                        │
        │ ◀───────────────────── │                        │
        │                        │                        │
        │  4. Authenticate to Power Platform              │
        │ ───────────────────────────────────────────────▶│
```

See [Azure DevOps Setup](azure-devops-setup.md) for complete pipeline configuration.

---

## Alternative: Client Secrets with GitHub Actions (Not Recommended)

If you cannot use federated credentials with GitHub Actions (e.g., organizational restrictions), you can use client secrets.

> ⚠️ **Not recommended for GitHub** – Secrets require rotation and are less secure. For Azure DevOps, client secrets in service connections are the standard approach.

### Setup with Client Secrets

1. In your App Registration, go to **Certificates & secrets**
2. Click **New client secret**
3. Set expiration (max 24 months)
4. **Copy the secret value immediately** - you won't see it again

### GitHub Secrets for Client Secret Auth

| Secret Name | Value |
|-------------|-------|
| `POWERPLATFORM_CLIENT_ID` | Application (client) ID |
| `POWERPLATFORM_CLIENT_SECRET` | Client secret value |
| `POWERPLATFORM_TENANT_ID` | Directory (tenant) ID |

### Workflow with Client Secrets

```yaml
- name: Authenticate with Power Platform
  uses: microsoft/powerplatform-actions/who-am-i@v1
  with:
    environment-url: ${{ vars.POWERPLATFORM_ENVIRONMENT_URL }}
    app-id: ${{ secrets.POWERPLATFORM_CLIENT_ID }}
    client-secret: ${{ secrets.POWERPLATFORM_CLIENT_SECRET }}
    tenant-id: ${{ secrets.POWERPLATFORM_TENANT_ID }}
```

---

## Verifying the Setup

### GitHub Actions
1. Run the **Export Solution** workflow with a test solution
2. Check the authentication step succeeds
3. Verify the deployment completes successfully

### Azure DevOps
1. Run the **Export Solution** pipeline manually
2. Check the "Verify connection" step succeeds
3. Verify the solution is exported and a PR is created

## Troubleshooting

### GitHub-Specific Issues

#### "AADSTS70021: No matching federated identity record found"

**Cause:** The federated credential configuration doesn't match the GitHub context.

**Solution:**
- Verify the organization/repository name is correct (case-sensitive)
- Check the entity type matches (branch vs environment vs PR)
- Ensure the branch/environment name is exact
- For environments, the GitHub environment name must match exactly

### "AADSTS700024: Client assertion is not within its valid time range"

**Cause:** Clock skew or token timing issue.

**Solution:**
- Retry the workflow
- If persistent, check runner time synchronization

### "The user is not a member of the organization"

**Cause:** App Registration not configured in Power Platform.

**Solution:**
1. Go to Power Platform Admin Center
2. Add App Registration as Application User in the target environment
3. Assign System Administrator role

### "Token request failed" or "id-token permission missing"

**Cause:** Missing OIDC permission in workflow.

**Solution:** Add to your workflow:
```yaml
permissions:
  id-token: write
  contents: read
```

### "Environment not found"

**Cause:** GitHub environment not created or name mismatch.

**Solution:**
1. Go to **Settings > Environments**
2. Create the environment (e.g., `test`, `prod`)
3. Ensure the name matches exactly in workflow and federated credential

### Azure DevOps-Specific Issues

#### "Could not find service connection"

**Cause:** Service connection name in the pipeline doesn't match the one configured in Project Settings.

**Solution:**
- Go to **Project Settings > Service connections** and verify the exact name
- Ensure the name in your pipeline YAML matches exactly (case-sensitive)
- Check that **Grant access to all pipelines** is enabled, or authorize the specific pipeline

#### "The service connection does not have sufficient permissions"

**Cause:** The pipeline hasn't been authorized to use the service connection.

**Solution:**
1. Run the pipeline — it will pause requesting authorization
2. Click **View** on the authorization prompt and approve
3. Alternatively, go to the service connection settings and add the pipeline under **Pipeline permissions**

#### "AADSTS7000215: Invalid client secret provided"

**Cause:** The client secret in the service connection has expired or was entered incorrectly.

**Solution:**
1. Generate a new client secret in the App Registration
2. Update the service connection in **Project Settings > Service connections**
3. Click **Edit** and paste the new secret value
4. Set a calendar reminder before the next expiration date

#### "The pipeline is not valid" or tasks not found

**Cause:** Power Platform Build Tools extension not installed in the Azure DevOps organization.

**Solution:**
1. Go to [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=microsoft-IsvExpTools.PowerPlatform-BuildTools)
2. Install **Power Platform Build Tools** for your organization
3. Retry the pipeline

#### "Environment does not exist or you don't have permission"

**Cause:** Azure DevOps environment not created or user lacks permissions.

**Solution:**
1. Go to **Pipelines > Environments**
2. Create the environment (e.g., `test`, `prod`)
3. Add the required approvals and checks
4. Ensure the pipeline has permission to deploy to the environment

#### PR creation fails (REST API 403)

**Cause:** The build service identity doesn't have permission to create pull requests.

**Solution:**
1. Go to **Project Settings > Repositories**
2. Select your repository
3. Under **Security**, find the **Build Service** identity
4. Grant **Contribute to pull requests** permission

---

## Security Best Practices

### GitHub: Federated Credentials
- ✅ Use environment-based federation for production deployments
- ✅ Create separate credentials for different scenarios (PR, deploy, etc.)
- ✅ Regularly audit federated credential configurations
- ✅ Use GitHub environment protection rules

### Azure DevOps: Service Connections
- ✅ Use the **Power Platform** service connection type (not generic)
- ✅ Set short client secret expiration and track renewal dates
- ✅ Use per-pipeline permissions instead of "grant access to all pipelines"
- ✅ Regularly audit service connection usage in the project

### Environment Protection

#### GitHub
1. Go to **Settings > Environments > prod**
2. Enable **Required reviewers**
3. Add appropriate team members
4. Optionally add **Wait timer** for manual verification window

#### Azure DevOps
1. Go to **Pipelines > Environments > prod**
2. Click **Approvals and checks**
3. Add **Approvals** and select the required reviewers
4. Optionally add **Business hours** or **Exclusive lock** checks

### Power Platform Security
- Grant minimum required permissions (System Administrator is convenient but broad)
- Use environment-specific Application Users when possible
- Monitor sign-in logs for the App Registration in Entra ID
- Review Application User activity in Power Platform Admin Center

---

## Comparison: Authentication Methods

| Aspect | Federated Credentials (GitHub) | Service Connection (Azure DevOps) | Client Secrets (GitHub) |
|--------|-------------------------------|----------------------------------|------------------------|
| Secret rotation | Not needed | Required (max 24 months) | Required (max 24 months) |
| Token lifetime | Minutes | Until revoked | Until revoked |
| Setup complexity | Moderate | Moderate | Simple |
| Security | Highest | High | Lower |
| Maintenance | Lowest | Medium | Highest |
| **Recommendation** | **✅ Best for GitHub** | **✅ Best for Azure DevOps** | ⚠️ Only if required |
