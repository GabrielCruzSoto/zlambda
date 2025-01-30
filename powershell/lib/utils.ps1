function Show-Help {
    Write-Host "Usage: .\zlambda.ps1 [-Runtime <String>] [-Action <String>]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -Runtime     Specify the runtime (aws or local)"
    Write-Host "  -Action      Specify the action to perform (prepare-env, run, deploy)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\zlambda.ps1 -Runtime local -Action run"
    Write-Host "  .\zlambda.ps1 -Runtime aws -Action deploy"
    exit 0
}

function Test-CondaEnvironment {
    try {
        $condaInfo = conda info --json | ConvertFrom-Json
        return $true
    }
    catch {
        return $false
    }
}

function Get-ContentFileConfigValues {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigFile,
        
        [Parameter(Mandatory=$true)]
        [string]$EnvFile
    )

    if (-not (Test-Path $ConfigFile)) {
        throw "Configuration file not found: $ConfigFile"
    }

    # Leer el archivo de configuración como texto para poder hacer reemplazos
    $configContent = Get-Content $ConfigFile -Raw

    # Crear un diccionario para almacenar las variables de entorno
    $envVars = @{}

    if (Test-Path $EnvFile) {
        $envContent = Get-Content $EnvFile
        foreach ($line in $envContent) {
            if ($line -match '^export\s+([^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                $envVars[$key] = $value
                
                # Reemplazar cada variable en el contenido JSON
                $placeholder = "\`${$key}"
                $configContent = $configContent -replace $placeholder, $value
            }
        }
    }

    # Convertir el contenido JSON con las variables reemplazadas a un objeto PowerShell
    try {
        $config = $configContent | ConvertFrom-Json
    }
    catch {
        throw "Error parsing JSON configuration after variable substitution: $_"
    }

    return $config
}