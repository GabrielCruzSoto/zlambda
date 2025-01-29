# ==========================================================================================================================
# Name Script:  zlambda.ps1
# Description:  This script allows you to perform actions of a Lambda Function 
#               such as executing locally and deploying to AWS
#
# Usage: .\zlambda.ps1 -Runtime <aws|local> -Action <prepare-env|run|deploy>
#
# Examples:
#   .\zlambda.ps1 -Runtime local -Action prepare-env
# ==========================================================================================================================

param(
    [Parameter()]
    [ValidateSet('aws', 'AWS', 'local', 'Local')]
    [string]$Runtime,
    
    [Parameter()]
    [ValidateSet('prepare-env', 'run', 'deploy')]
    [string]$Action
)

$script:BASE_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Importar módulos
. "$BASE_DIR\lib\utils.ps1"
. "$BASE_DIR\lib\commands\manager.command.ps1"
. "$BASE_DIR\lib\commands\aws.deploy.command.ps1"
. "$BASE_DIR\lib\commands\local.lambda-prepare-env.command.ps1"
. "$BASE_DIR\lib\commands\local.lambda-run.ps1"

Write-Host "Zlambda CLI - Lambda Development Toolkit"
Write-Host "Version $VERSION"
Write-Host "================================================================================================================="

$FILE_CONFIG = "config/lambda_config.json"
$FILE_CLOUDFORMATION = "config/templete-cf-lambda.yaml"
$FILE_ENV = ".local.env"

# Validar y preparar la configuración
if (-not (Test-Path $FILE_CONFIG)) {
    Write-Host "Error: Configuration file not found: $FILE_CONFIG"
    exit 1
}

$CONTENT_FILE_CONFIG = Get-Content $FILE_CONFIG | ConvertFrom-Json

# Procesar los parámetros
if ([string]::IsNullOrEmpty($Runtime)) {
    Show-Help
    exit 1
}

# Ejecutar la acción correspondiente según el runtime
switch ($Runtime.ToLower()) {
    { $_ -in 'aws', 'AWS' } {
        Invoke-AwsRuntime -Action $Action
    }
    { $_ -in 'local', 'Local' } {
        Test-CondaInstalled
        Invoke-LocalRuntime -Action $Action -Config $CONTENT_FILE_CONFIG
    }
    default {
        Write-Host "Error: Invalid runtime $Runtime"
        Show-Help
        exit 1
    }
}
