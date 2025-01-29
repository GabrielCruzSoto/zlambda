# ==========================================================================================================================
# Name Script:  lib/utils.ps1
# Description:  This script allows you to perform actions of a Lambda Function 
#               such as executing locally and deploying to AWS.
# ==========================================================================================================================

$script:VERSION = "0.0.1-SNAPSHOT"

function Write-Info {
    param([string]$message)
    Write-Host "INFO| $message"
}

function Write-Error-And-Exit {
    param(
        [int]$exitCode,
        [string]$errorMessage
    )
    if ($exitCode -ne 0) {
        Write-Host "ERROR| $errorMessage"
        exit $exitCode
    }
}

function Show-Help {
    Write-Host "Usage: $($MyInvocation.ScriptName) [-Runtime <String>] [-Action <String>] [-Help] [-Version]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Runtime   Runtime execution (local/aws)"
    Write-Host "  -Action    Action to perform (prepare-env, run, deploy)"
    Write-Host "  -Help      Show this help message and exit"
    Write-Host "  -Version   Show version and exit"
    exit 0
}

function Show-Version {
    Write-Host "Version $VERSION"
    exit 0
}

function Test-JsonConfig {
    param([string]$configFile)
    
    if (-not (Test-Path $configFile)) {
        Write-Host "ERROR| Configuration file not found: $configFile"
        exit 1
    }
    
    $config = Get-Content $configFile | ConvertFrom-Json
    $requiredFields = @(
        "functionName",
        "infraestructure.runtime",
        "infraestructure.handler",
        "dirSource"
    )
    
    foreach ($field in $requiredFields) {
        $value = $config
        foreach ($part in $field.Split('.')) {
            $value = $value.$part
        }
        if ($null -eq $value) {
            Write-Host "ERROR| Required field missing in config: $field"
            exit 1
        }
    }
}

function Test-CondaInstalled {
    try {
        $null = Get-Command conda -ErrorAction Stop
        return $true
    }
    catch {
        Write-Host "ERROR| Conda is not installed or not in PATH"
        exit 1
    }
}
