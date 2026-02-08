# Troubleshooting

Common issues and their solutions when working with Power Platform ALM.

## Authentication Issues

### "The user is not a member of the organization"

**Cause:** The Service Principal (App Registration) is not configured as an Application User in the target environment.

**Solution:**
1. Go to Power Platform Admin Center
2. Select the target environment
3. Go to Settings > Users + permissions > Application users
4. Add the App Registration as an Application User
5. Assign the System Administrator role

### "Invalid client secret"

**Cause:** The client secret has expired or is incorrect.

**Solution (GitHub Actions):**
1. Create a new client secret in your App Registration
2. Update the `POWERPLATFORM_CLIENT_SECRET` GitHub secret
3. Re-run the workflow

**Solution (Azure DevOps):**
1. Create a new client secret in your App Registration
2. Go to **Project Settings > Service connections**
3. Edit the affected service connection and update the secret
4. Re-run the pipeline

### "Tenant ID mismatch"

**Cause:** The tenant ID doesn't match the Power Platform tenant.

**Solution (GitHub Actions):** Update `AZURE_TENANT_ID` in repository variables.

**Solution (Azure DevOps):** Update the tenant ID in the service connection.

## Export Issues

### "Solution not found"

**Cause:** The solution name doesn't match exactly.

**Solution:**
1. Go to your Power Platform environment
2. Navigate to Solutions
3. Copy the exact **Name** (not Display Name)
4. Use this exact value in the workflow

### "Export timeout"

**Cause:** Large solutions may take longer to export.

**Solution:**
1. Try exporting during off-peak hours
2. Consider breaking into smaller solutions
3. Increase timeout values if possible

### "No changes detected after export"

**Cause:** The solution in the environment matches what's in Git.

**Solution:**
1. Verify you made changes in the correct environment
2. Publish all customizations before exporting
3. Check you're exporting the right solution

## Import Issues

### "Missing dependency"

**Cause:** The solution requires another solution that isn't installed.

**Solution:**
1. Check the Solution.xml for required solutions
2. Deploy dependencies first
3. Or include dependencies in your deployment order

```xml
<!-- Example dependency in Solution.xml -->
<MissingDependency>
  <Required solution="RequiredSolutionName" />
</MissingDependency>
```

### "Duplicate component"

**Cause:** A component with the same name exists as unmanaged.

**Solution:**
1. Remove the unmanaged component from the target environment
2. Or use the `force-overwrite` option (with caution)

### "Import failed: timeout"

**Cause:** Large solutions or slow environments.

**Solution:**
1. Import uses async operations - check import status in the environment
2. Increase `max-async-wait-time` in the workflow
3. Consider staged deployments

## Build Issues

### "Pack failed: invalid solution structure"

**Cause:** The solution folder structure is corrupted or missing files.

**Solution:**
1. Verify `Other/Solution.xml` exists
2. Check for encoding issues in XML files
3. Re-export the solution from the environment

### "Version format invalid"

**Cause:** Solution version doesn't match expected format.

**Solution:**
The version should be in format `X.X.X.X` (e.g., `1.0.0.0`)

1. Edit `Other/Solution.xml`
2. Update the `<Version>` element
3. Commit and retry

## CI/CD Pipeline Issues

### GitHub Actions

#### "Workflow failed: permission denied"

**Cause:** GitHub Actions doesn't have required permissions.

**Solution:**
1. Check workflow has `contents: write` and `pull-requests: write`
2. Verify GitHub secrets/variables are correctly configured
3. Check repository settings allow Actions

#### "Branch protection preventing push"

**Cause:** Branch rules prevent direct pushes.

**Solution:**
1. The export workflow creates PRs instead of direct commits
2. Ensure the workflow has permission to create branches
3. Review branch protection settings

#### "Artifact not found"

**Cause:** Build and deploy jobs not properly linked.

**Solution:**
1. Verify the `needs:` dependency is correct
2. Check artifact names match between upload and download
3. Ensure build job completed successfully

### Azure DevOps

#### "Pipeline not triggered on PR"

**Cause:** Branch policies or PR triggers are not configured.

**Solution:**
1. Verify **Build validation** policy is set on the `main` branch
2. Check the pipeline YAML has correct `pr` trigger paths
3. Ensure the pipeline is enabled and not paused

#### "Could not find service connection"

**Cause:** Service connection name mismatch.

**Solution:**
1. Go to **Project Settings > Service connections**
2. Verify the exact name (case-sensitive)
3. Ensure the pipeline is authorized to use it

#### "The pipeline is not valid" or tasks not found

**Cause:** Power Platform Build Tools extension not installed.

**Solution:**
Install from the [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=microsoft-IsvExpTools.PowerPlatform-BuildTools).

#### "PR creation failed (REST API 403)"

**Cause:** Build Service doesn't have permission to create pull requests.

**Solution:**
1. Go to **Project Settings > Repositories > Security**
2. Grant the Build Service identity:
   - **Contribute**
   - **Contribute to pull requests**
   - **Create branch**

#### "No hosted parallelism has been purchased"

**Cause:** Azure DevOps free tier has limited parallel jobs.

**Solution:**
1. Go to **Organization Settings > Pipelines > Parallel jobs**
2. Request free parallelism grant (for public/open-source projects) or purchase
3. Alternatively, set up a self-hosted agent

## Environment Issues

### "Environment URL not found"

**Cause:** Environment variable not configured.

**Solution (GitHub Actions):**
1. Go to **Settings > Environments**
2. Select your environment (test/prod)
3. Add the `POWERPLATFORM_ENVIRONMENT_URL` variable

**Solution (Azure DevOps):**
1. Check `.pipelines/environment-variables.yml` for the author URL
2. Check the `targetEnvironments` parameter in `.pipelines/build-and-deploy.yml`
3. Verify service connection URLs match the actual environment

### "Connection reference not mapped"

**Cause:** The settings file doesn't include connection mapping.

**Solution:**
1. Create the connection in the target environment
2. Get the Connection ID
3. Add to your settings file:

```json
{
  "ConnectionReferences": [
    {
      "LogicalName": "your_connection_reference",
      "ConnectionId": "actual-connection-id"
    }
  ]
}
```

## Post-Deployment Issues

### "Agent deployed but not working"

**Cause:** Some configurations don't transfer between environments.

**Solution:**
After deployment, verify these manually:

1. **Application Insights** - Must be configured per environment
   - Open agent in target environment
   - Go to Settings > Agent details > Advanced
   - Add the Application Insights connection string for that environment

2. **Connections** - Must be re-established per environment
   - Verify connection references are bound
   - Test each connection by triggering an action
   - Re-authenticate if needed

3. **Publish the agent** - Changes may not be live
   - Open agent in Copilot Studio
   - Click Publish

See [Post-Deployment Configuration](environment-configuration.md#post-deployment-configuration) for the full checklist.

### "Application Insights not capturing data"

**Cause:** App Insights isn't configured in the target environment.

**Solution:**
Application Insights configuration doesn't transfer with solution deployments:
1. Create separate App Insights resources per environment
2. Configure the connection string manually in each environment
3. Verify data is flowing in the Azure Portal

### "Connections failing after deployment"

**Cause:** Connections are environment-specific and may need re-authentication.

**Solution:**
1. Go to Power Apps maker portal > Connections
2. Find the connection showing errors
3. Re-authenticate or repair the connection
4. Verify the connection reference in the solution is bound correctly

## Common Error Messages

| Error | Likely Cause | Quick Fix |
|-------|--------------|-----------|
| `401 Unauthorized` | Auth credentials wrong | Verify secrets |
| `403 Forbidden` | Missing permissions | Check App User roles |
| `404 Not Found` | Wrong URL or name | Verify environment URL |
| `409 Conflict` | Duplicate component | Remove unmanaged version |
| `504 Gateway Timeout` | Large solution | Retry or increase timeout |

## Debugging Tips

### Enable Verbose Logging

**GitHub Actions** – Add to your workflow:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
```

**Azure DevOps** – Add to your pipeline:
```yaml
variables:
  - name: System.Debug
    value: true
```

### Check Power Platform Logs

1. Go to Power Platform Admin Center
2. Select environment
3. Go to Settings > Analytics > Solution import/export

### Test CLI Commands Locally

```bash
# Test authentication
pac auth create --url https://your-env.crm.dynamics.com

# Test export
pac solution export --name YourSolution --path ./test-export

# Test pack
pac solution pack --zipfile ./test.zip --folder ./solutions/YourSolution
```

## Getting More Help

1. **Check CI/CD logs** – Detailed step-by-step output in GitHub Actions or Azure DevOps
2. **Review Power Platform admin center** – Import/export history
3. **Search existing issues** – Someone may have solved it
4. **Open a new issue** – Include error messages and steps to reproduce
