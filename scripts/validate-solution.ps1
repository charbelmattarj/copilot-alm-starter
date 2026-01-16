<#
.SYNOPSIS
    Validates the structure of an unpacked Power Platform solution.
.DESCRIPTION
    Checks that required files exist and validates basic structure.
.PARAMETER SolutionFolder
    Path to the unpacked solution folder.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SolutionFolder
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$errors = @()
$warnings = @()

Write-Host "Validating solution structure: $SolutionFolder"
Write-Host "================================================"

# Check solution folder exists
if (-not (Test-Path $SolutionFolder)) {
    Write-Error "Solution folder not found: $SolutionFolder"
    exit 1
}

# Check for Solution.xml
$solutionXmlPath = Join-Path $SolutionFolder "Other/Solution.xml"
if (-not (Test-Path $solutionXmlPath)) {
    $errors += "Missing required file: Other/Solution.xml"
}
else {
    Write-Host "✅ Found Solution.xml"
    
    # Validate Solution.xml content
    try {
        [xml]$xml = Get-Content $solutionXmlPath
        
        $version = $xml.ImportExportXml.SolutionManifest.Version
        $uniqueName = $xml.ImportExportXml.SolutionManifest.UniqueName
        
        if ([string]::IsNullOrWhiteSpace($uniqueName)) {
            $errors += "Solution.xml missing UniqueName"
        }
        else {
            Write-Host "  Solution Name: $uniqueName"
        }
        
        if ([string]::IsNullOrWhiteSpace($version)) {
            $errors += "Solution.xml missing Version"
        }
        elseif ($version -notmatch '^\d+\.\d+\.\d+\.\d+$') {
            $warnings += "Version format should be X.X.X.X, found: $version"
        }
        else {
            Write-Host "  Version: $version"
        }
        
        # Check for missing dependencies
        $missingDeps = $xml.ImportExportXml.SolutionManifest.MissingDependencies.MissingDependency
        if ($missingDeps) {
            $count = if ($missingDeps -is [System.Array]) { $missingDeps.Count } else { 1 }
            $warnings += "Solution has $count missing dependencies"
        }
    }
    catch {
        $errors += "Failed to parse Solution.xml: $($_.Exception.Message)"
    }
}

# Check for common folders
$commonFolders = @("Other")
$optionalFolders = @("botcomponents", "bots", "Connectors", "environmentvariabledefinitions", "Workflows")

foreach ($folder in $commonFolders) {
    $folderPath = Join-Path $SolutionFolder $folder
    if (Test-Path $folderPath) {
        Write-Host "✅ Found folder: $folder"
    }
    else {
        $errors += "Missing required folder: $folder"
    }
}

foreach ($folder in $optionalFolders) {
    $folderPath = Join-Path $SolutionFolder $folder
    if (Test-Path $folderPath) {
        $itemCount = (Get-ChildItem $folderPath -Directory).Count
        Write-Host "✅ Found folder: $folder ($itemCount items)"
    }
}

# Check for XML encoding issues
$xmlFiles = Get-ChildItem $SolutionFolder -Filter "*.xml" -Recurse
foreach ($file in $xmlFiles) {
    try {
        [void]([xml](Get-Content $file.FullName))
    }
    catch {
        $errors += "Invalid XML in file: $($file.FullName)"
    }
}

# Report results
Write-Host ""
Write-Host "================================================"
Write-Host "Validation Results"
Write-Host "================================================"

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️ Warnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ Errors:" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "  - $err" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Validation FAILED" -ForegroundColor Red
    exit 1
}
else {
    Write-Host ""
    Write-Host "✅ Validation PASSED" -ForegroundColor Green
    exit 0
}
