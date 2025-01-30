$FILE_CONFIG = "config\lambda_config.json"
$FILE_ENV = ".local.env"
function Use-RuntimeAws {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Action
    )

    switch ($Action.ToLower()) {
        "deploy" {
            $CONTENT_JSON = Get-FileConfig
            Deploy-ToAws $CONTENT_JSON
        }
        default {
            throw "Invalid action for AWS runtime: $Action"
        }
    }
}

function Use-RuntimeLocal {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Action
    )

    switch ($Action.ToLower()) {
        "prepare-env" {
            $CONTENT_JSON = Get-FileConfig -ConfigFile $FILE_CONFIG -EnvFile $FILE_ENV
            Use-LocalPrepareEnvironment -Content_json $CONTENT_JSON
        }
        "run" {
            Write-Host "Not Implements" -ForegroundColor Red
            exit 1
        }
        default {
            throw "Invalid action for local runtime: $Action"
        }
    }
}

function Get-FileConfig{
    return Get-ContentFileConfigValues -ConfigFile $FILE_CONFIG -EnvFile $FILE_ENV
}