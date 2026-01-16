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

**Solution:**
1. Create a new client secret in your App Registration
2. Update the `POWERPLATFORM_CLIENT_SECRET` GitHub secret
3. Re-run the workflow

### "Tenant ID mismatch"

**Cause:** The tenant ID in GitHub secrets doesn't match the Power Platform tenant.

**Solution:**
1. Verify your tenant ID in the identity provider portal
2. Update `POWERPLATFORM_TENANT_ID` in GitHub secrets

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

## Workflow Issues

### "Workflow failed: permission denied"

**Cause:** GitHub Actions doesn't have required permissions.

**Solution:**
1. Check workflow has `contents: write` and `pull-requests: write`
2. Verify GitHub secrets are correctly configured
3. Check repository settings allow Actions

### "Branch protection preventing push"

**Cause:** Branch rules prevent direct pushes.

**Solution:**
1. The export workflow creates PRs instead of direct commits
2. Ensure the workflow has permission to create branches
3. Review branch protection settings

### "Artifact not found"

**Cause:** Build and deploy jobs not properly linked.

**Solution:**
1. Verify the `needs:` dependency is correct
2. Check artifact names match between upload and download
3. Ensure build job completed successfully

## Environment Issues

### "Environment URL not found"

**Cause:** Environment variable not configured in GitHub.

**Solution:**
1. Go to Settings > Environments
2. Select your environment (test/prod)
3. Add the `TEST_ENVIRONMENT_URL` or `PROD_ENVIRONMENT_URL` variable

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

Add to your workflow:

```yaml
env:
  ACTIONS_STEP_DEBUG: true
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

1. **Check GitHub Actions logs** - Detailed step-by-step output
2. **Review Power Platform admin center** - Import/export history
3. **Search existing issues** - Someone may have solved it
4. **Open a new issue** - Include error messages and steps to reproduce
