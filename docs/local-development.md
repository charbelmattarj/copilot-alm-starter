# Local Development & Testing

This guide helps you test and develop locally before pushing changes.

## Prerequisites

Install the Power Platform CLI:

```bash
# Option 1: .NET Tool (cross-platform - recommended)
dotnet tool install --global Microsoft.PowerApps.CLI.Tool

# Option 2: Download installer from Microsoft
# https://aka.ms/PowerAppsCLI

# Verify installation
pac --version
```

## Authenticate Locally

```bash
# Interactive login (browser-based)
pac auth create --environment https://yourorg-dev.crm.dynamics.com

# Or with device code flow
pac auth create --environment https://yourorg-dev.crm.dynamics.com --deviceCode

# List auth profiles
pac auth list

# Switch profiles
pac auth select --index 1
```

## Common Local Operations

### Export a Solution

```bash
# Export as unmanaged
pac solution export \
  --name YourSolutionName \
  --path ./exports/YourSolution.zip \
  --managed false

# Unpack to folder
pac solution unpack \
  --zipfile ./exports/YourSolution.zip \
  --folder ./solutions/YourSolutionName \
  --packagetype Unmanaged \
  --allowDelete true
```

### Pack a Solution

```bash
# Pack as managed
pac solution pack \
  --folder ./solutions/YourSolutionName \
  --zipfile ./output/YourSolution_managed.zip \
  --packagetype Managed

# Pack as unmanaged
pac solution pack \
  --folder ./solutions/YourSolutionName \
  --zipfile ./output/YourSolution_unmanaged.zip \
  --packagetype Unmanaged
```

### Import a Solution

```bash
# Import managed solution
pac solution import \
  --path ./output/YourSolution_managed.zip \
  --force-overwrite \
  --publish-changes

# Import with settings file
pac solution import \
  --path ./output/YourSolution_managed.zip \
  --settings-file ./settings/YourSolution_test.json
```

### Validate Solution Structure

```bash
# Run the validation script
pwsh ./scripts/validate-solution.ps1 -SolutionFolder ./solutions/YourSolutionName
```

## Testing Workflows Locally

### Using act (GitHub Actions local runner)

```bash
# Install act
brew install act  # macOS
# or see https://github.com/nektos/act

# Run a workflow locally
act workflow_dispatch \
  -W .github/workflows/validate-pr.yml \
  --input solution_name=YourSolution
```

### Manual Testing Checklist

Before pushing changes:

- [ ] Solution packs without errors
- [ ] Validation script passes
- [ ] Solution imports to a test environment
- [ ] Agent/components work as expected

## Useful Commands

```bash
# Check connection
pac org who

# List solutions in environment
pac solution list

# Check solution dependencies
pac solution check --path ./solution.zip

# Create deployment settings template
pac solution create-settings \
  --solution-zip ./solution.zip \
  --settings-file ./settings/YourSolution.settings.json
```

## Troubleshooting

### "No auth profiles found"

```bash
pac auth create --environment https://yourorg.crm.dynamics.com
```

### "Pack failed: invalid XML"

Check for encoding issues:
```bash
# Find files with potential issues
find ./solutions -name "*.xml" -exec file {} \; | grep -v "UTF-8\|ASCII"
```

### "Import failed: missing dependency"

```bash
# Check dependencies
pac solution check --path ./solution.zip

# List what's in the solution
pac solution unpack --zipfile ./solution.zip --folder ./temp --packagetype Unmanaged
cat ./temp/Other/Solution.xml | grep -A 20 "MissingDependencies"
```

## IDE Extensions

Recommended VS Code extensions:

- **Power Platform Tools** - Official extension for Power Platform development
- **PowerShell** - For running scripts
- **YAML** - For editing workflows
