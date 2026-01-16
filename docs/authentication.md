# Authentication Setup

This guide explains how to set up authentication for automated deployments to Power Platform environments.

## Overview

We recommend using **Workload Identity Federation** (federated credentials) for GitHub Actions authentication. This approach:

- ✅ **No secrets to manage** - No client secrets to rotate
- ✅ **More secure** - Short-lived tokens, no long-lived credentials
- ✅ **Easier maintenance** - No secret expiration issues

## Recommended: Workload Identity Federation

### Step 1: Create an App Registration

1. Navigate to your identity provider's app registration portal
2. Click **New registration**
3. Configure:
   - **Name**: `PowerPlatform-ALM-GitHub` (or your preferred name)
   - **Supported account types**: Single tenant
   - **Redirect URI**: Leave blank
4. Click **Register**
5. Note the **Application (client) ID** and **Directory (tenant) ID**

### Step 2: Configure Federated Credentials

1. In your App Registration, go to **Certificates & secrets**
2. Select the **Federated credentials** tab
3. Click **Add credential**
4. Select **GitHub Actions deploying Azure resources**
5. Configure:
   - **Organization**: Your GitHub organization or username
   - **Repository**: `mcs-alm-starter` (your repo name)
   - **Entity type**: Choose based on your needs:
     - `Branch` - For deployments from a specific branch (e.g., `main`)
     - `Environment` - For GitHub environment-based deployments (recommended)
     - `Pull Request` - For PR validation workflows
     - `Tag` - For release-based deployments
   - **Name**: Descriptive name (e.g., `github-main-branch`)
6. Click **Add**

#### Recommended Federated Credentials Setup

Create multiple federated credentials for different scenarios:

| Name | Entity Type | Value | Use Case |
|------|-------------|-------|----------|
| `github-env-test` | Environment | `test` | Deploy to test |
| `github-env-prod` | Environment | `prod` | Deploy to production |
| `github-pr` | Pull Request | - | PR validation |
| `github-main` | Branch | `main` | Export workflow on main |

### Step 3: Grant Power Platform Permissions

For each environment you want to deploy to:

1. Go to the Power Platform Admin Center
2. Select the environment
3. Go to **Settings > Users + permissions > Application users**
4. Click **New app user**
5. Select your App Registration
6. Assign the **System Administrator** security role

### Step 4: Configure GitHub

#### Repository Variables (Not Secrets!)

Since these are not sensitive, store them as **variables**:

| Variable Name | Value | Notes |
|---------------|-------|-------|
| `AZURE_CLIENT_ID` | Application (client) ID | From App Registration |
| `AZURE_TENANT_ID` | Directory (tenant) ID | From App Registration |

Go to **Settings > Secrets and variables > Actions > Variables** to add these.

#### Environment Variables

For each GitHub environment (`test`, `prod`), add:

| Variable Name | Example Value |
|---------------|---------------|
| `POWERPLATFORM_ENVIRONMENT_URL` | `https://yourorg-test.crm.dynamics.com` |

### Step 5: Update Workflow Permissions

Ensure your workflows have OIDC token permissions:

```yaml
permissions:
  id-token: write   # Required for federated credentials
  contents: read
```

## How It Works

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  GitHub Actions │────▶│  Identity        │────▶│  Power Platform │
│  (OIDC Token)   │     │  Provider        │     │  Environment    │
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

---

## Workflow Configuration

### Using Federated Credentials

The workflows in this repository are configured to support federated credentials:

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

## Alternative: Client Secrets (Not Recommended)

If you cannot use federated credentials (e.g., organizational restrictions), you can use client secrets.

> ⚠️ **Not recommended** - Secrets require rotation and are less secure.

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

1. Run the **Export Solution** workflow with a test solution
2. Check the authentication step succeeds
3. Verify the deployment completes successfully

## Troubleshooting

### "AADSTS70021: No matching federated identity record found"

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

---

## Security Best Practices

### Federated Credentials
- ✅ Use environment-based federation for production deployments
- ✅ Create separate credentials for different scenarios (PR, deploy, etc.)
- ✅ Regularly audit federated credential configurations
- ✅ Use GitHub environment protection rules

### Environment Protection
For production deployments:
1. Go to **Settings > Environments > prod**
2. Enable **Required reviewers**
3. Add appropriate team members
4. Optionally add **Wait timer** for manual verification window

### Power Platform Security
- Grant minimum required permissions
- Use environment-specific Application Users when possible
- Monitor sign-in logs for the App Registration
- Review Application User activity in Power Platform

---

## Comparison: Federated vs Client Secrets

| Aspect | Federated Credentials | Client Secrets |
|--------|----------------------|----------------|
| Secret rotation | Not needed | Required (max 24 months) |
| Token lifetime | Minutes | Until revoked |
| Setup complexity | Slightly more | Simpler |
| Security | Higher | Lower |
| Maintenance | Lower | Higher |
| **Recommendation** | **✅ Use this** | ⚠️ Only if required |
