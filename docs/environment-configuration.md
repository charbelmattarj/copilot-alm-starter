# Environment Configuration

This guide covers how to configure environment-specific settings for your deployments.

## Overview

Different environments (dev, test, prod) often need different configurations:
- Connection references (different credentials)
- Environment variables (different API endpoints)
- Feature flags

## Deployment Settings Files

### File Structure

Create settings files in the `settings/` folder:

```
settings/
├── YourSolution.settings.json      # Template (auto-generated)
├── YourSolution_test.json          # Test environment overrides
└── YourSolution_prod.json          # Production environment overrides
```

### Settings File Format

```json
{
  "EnvironmentVariables": [
    {
      "SchemaName": "yoursolution_APIEndpoint",
      "Value": "https://api.prod.example.com"
    },
    {
      "SchemaName": "yoursolution_FeatureFlag",
      "Value": "true"
    }
  ],
  "ConnectionReferences": [
    {
      "LogicalName": "yoursolution_shared_customapi",
      "ConnectionId": "shared-customapi-xxx-xxx",
      "ConnectorId": "/providers/Microsoft.PowerApps/apis/shared_customapi"
    }
  ]
}
```

## Environment Variables

### Types of Environment Variables

| Type | Use Case | Example |
|------|----------|---------|
| Text | API URLs, feature flags | `https://api.example.com` |
| Number | Thresholds, limits | `100` |
| JSON | Complex configuration | `{"key": "value"}` |
| Secret | API keys (use with caution) | `***` |

### Defining Environment Variables

In your solution, create environment variable definitions:

```xml
<!-- environmentvariabledefinitions/yoursolution_APIEndpoint/environmentvariabledefinition.xml -->
<environmentvariabledefinition>
  <schemaname>yoursolution_APIEndpoint</schemaname>
  <displayname>API Endpoint</displayname>
  <type>String</type>
  <defaultvalue>https://api.dev.example.com</defaultvalue>
</environmentvariabledefinition>
```

### Override Values Per Environment

In your deployment settings:

```json
// settings/YourSolution_prod.json
{
  "EnvironmentVariables": [
    {
      "SchemaName": "yoursolution_APIEndpoint",
      "Value": "https://api.prod.example.com"
    }
  ]
}
```

## Connection References

### What Are Connection References?

Connection references allow you to:
- Define connections at design time
- Specify actual connection at deploy time
- Keep credentials out of your solution

### Setting Up Connection References

1. **In the solution**, create a connection reference
2. **In each environment**, create the actual connection
3. **In settings files**, map the reference to the connection

```json
{
  "ConnectionReferences": [
    {
      "LogicalName": "yoursolution_CRMConnection",
      "ConnectionId": "shared-commondataserviceforapps-xxx-xxx"
    }
  ]
}
```

### Finding Connection IDs

1. Go to Power Apps maker portal
2. Navigate to Connections
3. Select your connection
4. Copy the ID from the URL

## Using Settings in Workflows

### Build and Deploy Workflow

The workflow automatically looks for settings files:

```yaml
- name: Import solution
  uses: microsoft/powerplatform-actions/import-solution@v1
  with:
    environment-url: ${{ vars.PROD_ENVIRONMENT_URL }}
    solution-file: ./solution.zip
    use-deployment-settings-file: true
    deployment-settings-file: ./settings/YourSolution_prod.json
```

### Manual Override

You can also pass settings directly:

```yaml
- name: Import with inline settings
  run: |
    pac solution import \
      --path ./solution.zip \
      --environment ${{ vars.PROD_ENVIRONMENT_URL }} \
      --settings-file ./settings/YourSolution_prod.json
```

## Multi-Environment Strategy

### Recommended Setup

| Environment | Purpose | Settings File |
|-------------|---------|---------------|
| Dev | Development | (use defaults) |
| Test | QA/Testing | `_test.json` |
| UAT | User acceptance | `_uat.json` |
| Prod | Production | `_prod.json` |

### Environment Promotion

```
Dev (default values)
  ↓ Export
Git Repository
  ↓ Deploy with _test.json
Test
  ↓ Deploy with _prod.json (after approval)
Prod
```

## GitHub Environment Configuration

### Setting Up Environments

1. Go to **Settings > Environments**
2. Create environments: `test`, `prod`
3. Add environment-specific variables

### Environment Variables vs Secrets

| Type | Use For | Example |
|------|---------|---------|
| Variables | Non-sensitive config | Environment URLs |
| Secrets | Sensitive data | Client secrets, API keys |

### Protection Rules

For production:
1. **Required reviewers** - Require approval before deployment
2. **Wait timer** - Add delay for manual intervention
3. **Deployment branches** - Only allow from `main`

## Advanced Configuration

### Dynamic Settings

Generate settings at deploy time:

```yaml
- name: Generate settings
  shell: pwsh
  run: |
    $settings = @{
      EnvironmentVariables = @(
        @{
          SchemaName = "yoursolution_DeployedAt"
          Value = (Get-Date -Format "o")
        }
      )
    }
    $settings | ConvertTo-Json -Depth 10 | Out-File ./settings/dynamic.json
```

### Secrets in Settings

For sensitive values, use GitHub secrets:

```yaml
- name: Create settings with secrets
  shell: pwsh
  env:
    API_KEY: ${{ secrets.EXTERNAL_API_KEY }}
  run: |
    $settings = @{
      EnvironmentVariables = @(
        @{
          SchemaName = "yoursolution_APIKey"
          Value = $env:API_KEY
        }
      )
    }
    $settings | ConvertTo-Json | Out-File ./settings/secure.json
```

## Troubleshooting

### "Environment variable not found"

- Verify the SchemaName matches exactly
- Check the variable exists in your solution
- Ensure the settings file is being used

### "Connection reference failed"

- Verify the connection exists in the target environment
- Check the ConnectionId is correct
- Ensure the service principal has access to the connection

### "Settings file not applied"

- Check the file path is correct
- Verify JSON syntax is valid
- Enable verbose logging for debugging

---

## Post-Deployment Configuration

> ⚠️ **Important**: Some configurations cannot be fully automated and require manual setup in higher environments after initial deployment.

### Application Insights

Application Insights must be configured **manually in each environment** after deployment:

1. **Create Application Insights resource** (if not already exists):
   - In Azure Portal, create an Application Insights resource for each environment
   - Note the **Instrumentation Key** or **Connection String**

2. **Configure in Copilot Studio**:
   - Open the agent in the target environment
   - Go to **Settings > Agent details > Advanced**
   - Add your Application Insights connection string
   - Save and publish

3. **Repeat for each environment**:
   | Environment | App Insights Resource |
   |-------------|-----------------------|
   | Test | `appins-youragent-test` |
   | Prod | `appins-youragent-prod` |

> 💡 **Tip**: Use separate Application Insights resources per environment to keep telemetry isolated.

### Connections

Connections must be **re-established in each environment**:

1. **Before first deployment**:
   - Create necessary connections in the target environment
   - These run under a service account or user identity
   - Note the Connection IDs for your settings file

2. **After deployment**:
   - Verify all connection references are bound
   - Test each connector by triggering a flow or action
   - Re-authenticate if connections show errors

3. **Common connections to re-establish**:
   - Dataverse (often automatic with service principal)
   - SharePoint
   - Outlook/Office 365
   - Custom connectors
   - Azure services (Key Vault, Storage, etc.)

### Post-Deployment Checklist

After deploying to a new environment for the first time:

- [ ] **Application Insights** - Configure in agent settings
- [ ] **Connections** - Verify all are bound and working
- [ ] **Environment variables** - Confirm values are correct
- [ ] **Channel configuration** - Re-configure web chat, Teams, etc.
- [ ] **Authentication** - Configure SSO if used
- [ ] **Test the agent** - Run through key scenarios manually
- [ ] **Publish** - Publish the agent in the new environment

### Automating Post-Deployment Tasks

While some tasks are manual, you can automate reminders:

```yaml
# In your workflow, add a summary comment
- name: Post-deployment reminder
  if: success()
  run: |
    echo "## ✅ Deployment Complete" >> $GITHUB_STEP_SUMMARY
    echo "" >> $GITHUB_STEP_SUMMARY
    echo "### Manual steps required:" >> $GITHUB_STEP_SUMMARY
    echo "- [ ] Configure Application Insights" >> $GITHUB_STEP_SUMMARY
    echo "- [ ] Verify connections are working" >> $GITHUB_STEP_SUMMARY
    echo "- [ ] Test agent in target environment" >> $GITHUB_STEP_SUMMARY
    echo "- [ ] Publish agent if not auto-published" >> $GITHUB_STEP_SUMMARY
```
