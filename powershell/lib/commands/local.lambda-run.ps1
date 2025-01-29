# ==========================================================================================================================
# Name Script:  lib/commands/local.lambda-run.ps1
# Description:  This script allows you to run a Lambda Function locally.
#               
# ==========================================================================================================================

function Invoke-LambdaRun {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$LambdaConfig
    )

    $functionName = $LambdaConfig.functionName
    Write-Host "function_name: $functionName"

    # Configurar variables de entorno desde la configuración
    if ($LambdaConfig.infraestructure.env.Variables) {
        $envVars = $LambdaConfig.infraestructure.env.Variables
        foreach ($key in $envVars.PSObject.Properties.Name) {
            $value = $envVars.$key
            [Environment]::SetEnvironmentVariable($key, $value)
            Write-Host "key: $key, value: $value"
        }
    }

    # Activar el entorno virtual de conda
    $nameVirtEnv = $functionName -replace '"', '' + "-env"
    conda activate $nameVirtEnv
    Write-Error-And-Exit $LASTEXITCODE "Error activating virtual environment: $nameVirtEnv"

    # Ejecutar la función lambda
    python main.py
}
