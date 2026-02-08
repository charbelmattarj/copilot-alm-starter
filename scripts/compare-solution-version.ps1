<#
.SYNOPSIS
    Compares solution version between current export and target branch.
.DESCRIPTION
    Checks if the solution version has been incremented compared to the target branch.
    Also detects missing dependencies in the solution.
.PARAMETER SolutionFolder
    Path to the unpacked solution folder.
.PARAMETER SolutionName
    Name of the solution.
.PARAMETER TargetBranch
    Branch to compare against (default: main).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SolutionFolder = $env:SOLUTION_FOLDER,
    
    [Parameter(Mandatory = $false)]
    [string]$SolutionName = $env:SOLUTION_NAME,
    
    [Parameter(Mandatory = $false)]
    [string]$TargetBranch = $env:TARGET_BRANCH ?? "main",
    
    [Parameter(Mandatory = $false)]
    [string]$CurrentVersion = $env:SOLUTION_VERSION
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Comparing solution version..."
Write-Host "  Solution: $SolutionName"
Write-Host "  Current Version: $CurrentVersion"
Write-Host "  Target Branch: $TargetBranch"

# Function to compare version strings
function Compare-Versions {
    param(
        [string]$Version1,
        [string]$Version2
    )
    
    try {
        $v1 = [System.Version]::Parse($Version1)
        $v2 = [System.Version]::Parse($Version2)
        return $v1.CompareTo($v2)
    }
    catch {
        Write-Warning "Failed to parse versions, falling back to string comparison"
        return [string]::Compare($Version1, $Version2, [System.StringComparison]::OrdinalIgnoreCase)
    }
}

# Check for missing dependencies in the solution
$localSolutionXmlPath = Join-Path $SolutionFolder "Other/Solution.xml"
$missingDependencies = @()

if (Test-Path $localSolutionXmlPath) {
    try {
        [xml]$localXml = Get-Content $localSolutionXmlPath
        $missingDeps = $localXml.ImportExportXml.SolutionManifest.MissingDependencies.MissingDependency
        
        if ($missingDeps) {
            Write-Warning "Missing dependencies detected!"
            
            # Ensure array
            if ($missingDeps -isnot [System.Array]) { 
                $missingDeps = @($missingDeps) 
            }
            
            foreach ($dep in $missingDeps) {
                $missingDependencies += @{
                    RequiredComponent  = $dep.Required.displayName
                    RequiredSolution   = $dep.Required.solution
                    DependentType      = $dep.Dependent.type
                    DependentComponent = $dep.Dependent.displayName
                }
                
                Write-Host "  - Required: $($dep.Required.displayName) from $($dep.Required.solution)"
            }
        }
    }
    catch {
        Write-Warning "Failed to check for missing dependencies: $($_.Exception.Message)"
    }
}

# Fetch target branch for comparison
Write-Host "Fetching $TargetBranch branch..."
git fetch origin $TargetBranch 2>$null

$targetSolutionXmlPath = "$SolutionFolder/Other/Solution.xml"
$targetBranchVersion = $null
$isNewSolution = $false

# Check if solution exists in target branch
$ErrorActionPreference = "SilentlyContinue"
git cat-file -e "origin/${TargetBranch}:$targetSolutionXmlPath" 2>$null
$gitExitCode = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($gitExitCode -eq 0) {
    # Get version from target branch
    $targetContent = git show "origin/${TargetBranch}:$targetSolutionXmlPath" 2>$null
    if ($targetContent) {
        try {
            [xml]$targetXml = $targetContent
            $targetBranchVersion = $targetXml.ImportExportXml.SolutionManifest.Version
            Write-Host "Target branch version: $targetBranchVersion"
        }
        catch {
            Write-Warning "Failed to parse target branch Solution.xml"
        }
    }
}
else {
    Write-Host "Solution does not exist in target branch - this is a NEW solution"
    $isNewSolution = $true
}

# Compare versions
$shouldCreatePR = $true
$versionComparisonReason = ""

if ($isNewSolution) {
    $versionComparisonReason = "New solution"
}
elseif ($targetBranchVersion) {
    $comparison = Compare-Versions -Version1 $CurrentVersion -Version2 $targetBranchVersion
    
    if ($comparison -gt 0) {
        $versionComparisonReason = "Version incremented from $targetBranchVersion to $CurrentVersion"
        Write-Host "✅ $versionComparisonReason"
    }
    elseif ($comparison -eq 0) {
        $versionComparisonReason = "Version unchanged at $CurrentVersion"
        Write-Warning "⚠️ $versionComparisonReason - consider incrementing"
    }
    else {
        $versionComparisonReason = "Version decreased from $targetBranchVersion to $CurrentVersion"
        Write-Warning "⚠️ $versionComparisonReason - this may be unintended"
    }
}

# Output results
$result = @{
    ShouldCreatePR          = $shouldCreatePR
    VersionComparisonReason = $versionComparisonReason
    IsNewSolution           = $isNewSolution
    CurrentVersion          = $CurrentVersion
    TargetBranchVersion     = $targetBranchVersion
    MissingDependencies     = $missingDependencies
}

# GitHub Actions output
if ($env:GITHUB_OUTPUT) {
    "should_create_pr=$($shouldCreatePR.ToString().ToLower())" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    "version_comparison_reason=$versionComparisonReason" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    "is_new_solution=$($isNewSolution.ToString().ToLower())" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    "has_missing_dependencies=$($missingDependencies.Count -gt 0)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
}

# Azure DevOps Pipelines output
if ($env:TF_BUILD) {
    Write-Host "##vso[task.setvariable variable=SHOULD_CREATE_PR]$shouldCreatePR"
    Write-Host "##vso[task.setvariable variable=VERSION_COMPARISON_REASON]$versionComparisonReason"
    Write-Host "##vso[task.setvariable variable=IS_NEW_SOLUTION]$isNewSolution"
    Write-Host "##vso[task.setvariable variable=HAS_MISSING_DEPENDENCIES]$($missingDependencies.Count -gt 0)"

    # Base64 encode missing dependencies for PR description
    if ($missingDependencies.Count -gt 0) {
        $depMsg = "## Missing Dependencies`n`n| Required Component | Solution | Dependent Type | Dependent Component |`n|---|---|---|---|`n"
        foreach ($dep in $missingDependencies) {
            $depMsg += "| $($dep.RequiredComponent) | $($dep.RequiredSolution) | $($dep.DependentType) | $($dep.DependentComponent) |`n"
        }
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($depMsg)
        $encoded = [Convert]::ToBase64String($bytes)
        Write-Host "##vso[task.setvariable variable=MISSING_DEPENDENCIES]$encoded"
    }
}

return $result
