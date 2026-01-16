<#
.SYNOPSIS
    Extracts metadata from a Power Platform solution's Solution.xml file.
.DESCRIPTION
    Reads the Solution.xml file and extracts version, publisher, and description.
    Outputs the values for use in CI/CD pipelines.
.PARAMETER SolutionFolder
    Path to the unpacked solution folder.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SolutionFolder = $env:SOLUTION_FOLDER
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$solutionXml = Join-Path $SolutionFolder "Other/Solution.xml"

if (Test-Path $solutionXml) {
    Write-Host "Reading solution metadata from: $solutionXml"
    
    [xml]$xml = Get-Content $solutionXml
    
    $version = $xml.ImportExportXml.SolutionManifest.Version
    $publisher = $xml.ImportExportXml.SolutionManifest.Publisher.UniqueName
    $uniqueName = $xml.ImportExportXml.SolutionManifest.UniqueName
    $description = ""
    
    if ($xml.ImportExportXml.SolutionManifest.PSObject.Properties.Name -contains 'Description') {
        $description = $xml.ImportExportXml.SolutionManifest.Description
    }

    Write-Host "Solution: $uniqueName"
    Write-Host "Version: $version"
    Write-Host "Publisher: $publisher"
    Write-Host "Description: $description"

    # Output for GitHub Actions
    if ($env:GITHUB_OUTPUT) {
        "solution_name=$uniqueName" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
        "solution_version=$version" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
        "solution_publisher=$publisher" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
        "solution_description=$description" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
    }
    
    # Output for environment variables
    if ($env:GITHUB_ENV) {
        "SOLUTION_NAME=$uniqueName" | Out-File -FilePath $env:GITHUB_ENV -Append
        "SOLUTION_VERSION=$version" | Out-File -FilePath $env:GITHUB_ENV -Append
        "SOLUTION_PUBLISHER=$publisher" | Out-File -FilePath $env:GITHUB_ENV -Append
        "SOLUTION_DESCRIPTION=$description" | Out-File -FilePath $env:GITHUB_ENV -Append
    }
    
    # Return as object for local use
    return @{
        Name        = $uniqueName
        Version     = $version
        Publisher   = $publisher
        Description = $description
    }
}
else {
    Write-Warning "Solution.xml not found at: $solutionXml"
    exit 1
}
