#Requires -Version 7.0 -RunAsAdministrator
#------------------------------------------------------------------------------
# FILE:         action.ps1
# CONTRIBUTOR:  Jeff Lill
# COPYRIGHT:    Copyright (c) 2005-2021 by neonFORGE LLC.  All rights reserved.
#
# The contents of this repository are for private use by neonFORGE, LLC. and may not be
# divulged or used for any purpose by other organizations or individuals without a
# formal written and signed agreement with neonFORGE, LLC.

# Verify that we're running on a properly configured neonFORGE GitHub runner 
# and import the deployment and action scripts from neonCLOUD.

# NOTE: This assumes that the required [$NC_ROOT/Powershell/*.ps1] files
#       in the current clone of the repo on the runner are up-to-date
#       enough to be able to obtain secrets and use GitHub Action functions.
#       If this is not the case, you'll have to manually pull the repo 
#       first on the runner.

$ncRoot = $env:NC_ROOT

if ([System.String]::IsNullOrEmpty($ncRoot) -or ![System.IO.Directory]::Exists($ncRoot))
{
    throw "Runner Config: neonCLOUD repo is not present."
}

$ncPowershell = [System.IO.Path]::Combine($ncRoot, "Powershell")

Push-Location $ncPowershell | Out-Null
. ./includes.ps1
Pop-Location | Out-Null

try
{
    # Fetch the arguments

    $repo     = Get-ActionInput "repo"     $true
    $workflow = Get-ActionInput "workflow" $true
    $branch   = Get-ActionInput "branch"   $true
    $inputs   = Get-ActionInput "inputs"   $false

    # [inputs] is either empty or a YAML formatted string.  We're going to parse any
    # YAML and then convert it to JSON, so we can pass it to the new workflow via the
    # GitHub CLI.

    $jsonInputs = "{}"

    if (![System.String]::IsNullOrWhitespace($inputs))
    {
        $jsonInputs = ConvertTo-Json $(ConvertFrom-Yaml $inputs)
    }

    # Start the workflow.

    Invoke-ActionWorkflow $repo $workflow -branch $branch -inputJson $jsonInputs
}
catch
{
    Write-ActionException $_
    exit 1
}
