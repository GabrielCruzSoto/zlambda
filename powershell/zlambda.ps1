# ==========================================================================================================================
# Name Script:  zlambda.ps1
# Description:  This script allows you to perform actions of a Lambda Function 
#               such as executing locally and deploying to AWS
#
# Usage: .\zlambda.ps1 [-Runtime <String>] [-Action <String>]
#
# Parameters:
#   -Runtime     Specify the runtime AWS or local
#   -Action      Specify the action to perform prepare-env, run, deploy
#
# Examples:
#   .\zlambda.ps1 -Runtime local -Action run
# ==========================================================================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$Runtime,
    
    [Parameter(Mandatory=$false)]
    [string]$Action
)

$script:VERSION = "1.0.0"
$script:BASE_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$BASE_DIR\lib\utils.ps1"
. "$BASE_DIR\lib\commands\manager.command.ps1"
. "$BASE_DIR\lib\commands\aws.deploy.command.ps1"
. "$BASE_DIR\lib\commands\local.lambda-prepare-env.command.ps1"
. "$BASE_DIR\lib\commands\local.lambda-run.ps1"

Write-Host "Zlambda CLI - Lambda Development Toolkit"
Write-Host "Version $VERSION"
Write-Host "================================================================================================================="


try {
    switch ($Runtime.ToLower()) {
        "aws" {
            Write-Host "Not Implements" -ForegroundColor Red
            exit 1
        }
        "local" {
            if (-not (Test-CondaEnvironment)) {
                throw "Conda environment is required for local runtime"
            }
            Use-RuntimeLocal -Action $Action 
        }
        default {
            if ($Runtime) {
                throw "Error: Invalid runtime $Runtime"
            }
            Show-Help
        }
    }
}
catch {
    Write-Error $_.Exception.Message
    Show-Help
    exit 1
}