function Use-LocalRun {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Config
    )

    $handlerPath = $Config.handler_path
    if (-not $handlerPath) {
        throw "handler_path not specified in config"
    }

    if (-not (Test-Path $handlerPath)) {
        throw "Handler file not found: $handlerPath"
    }

    Write-Host "Running Lambda function locally..."
    Write-Host "Handler: $handlerPath"
    
    # Import the handler module
    $handlerDir = Split-Path -Parent $handlerPath
    $handlerFile = Split-Path -Leaf $handlerPath
    $handlerName = [System.IO.Path]::GetFileNameWithoutExtension($handlerFile)
    
    Push-Location $handlerDir
    try {
        Import-Module ".\$handlerFile" -Force
        
        # Execute the handler
        $eventData = @{
            # Add your test event data here
            "test" = "event"
        }
        
        $context = @{
            "function_name" = $Config.function_name
            "function_version" = "$VERSION"
            "memory_limit_in_mb" = 128
            "aws_request_id" = [guid]::NewGuid().ToString()
        }

        $result = & $handlerName $eventData $context
        Write-Host "Lambda execution result:"
        $result | ConvertTo-Json -Depth 10
    }
    finally {
        Pop-Location
    }
}