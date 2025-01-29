function New-CondaEnvironment {
    param(
        [string]$runtimeLambda,
        [string]$functionName
    )
    
    Write-Host "function_name: $functionName"
    $nameVirtEnv = $functionName -replace '"', '' + "-env"
    Write-Info "Creating virtual environment: $nameVirtEnv"
    
    $existingEnvs = conda env list | Out-String
    if ($existingEnvs -notmatch $nameVirtEnv) {
        $pythonVersion = $runtimeLambda -replace '"', ''
        conda create -n $nameVirtEnv python=$pythonVersion -y
        Write-Error-And-Exit $LASTEXITCODE "Error creating virtual environment: $nameVirtEnv"
    }
    
    # Activar el entorno virtual
    conda activate $nameVirtEnv
    Write-Error-And-Exit $LASTEXITCODE "Error activating virtual environment: $nameVirtEnv"
}

function Get-Layers {
    param([string]$layers)
    
    Write-Info "Downloading layers..."
    $layersJson = $layers | ConvertFrom-Json
    
    foreach ($layer in $layersJson) {
        $name = $layer.name
        $version = $layer.version
        $libPip = $layer.lib_pip
        
        if ([string]::IsNullOrEmpty($libPip)) {
            Write-Info "Downloading layer: $name version: $version"
            
            $location = aws lambda get-layer-version `
                --layer-name $name `
                --version-number $version `
                --query 'Content.Location' `
                --output text
                
            Invoke-WebRequest -Uri $location -OutFile "temp_layers/$name.zip"
            Write-Error-And-Exit $LASTEXITCODE "Error downloading Layer $name from AWS"
            Write-Info "Downloading layer: $name version: $version successful"
        }
    }
}

function Install-Layers {
    param(
        [string]$layers,
        [string]$functionName
    )
    
    $nameVirtEnv = $functionName -replace '"', '' + "-env"
    $layersJson = $layers | ConvertFrom-Json
    
    foreach ($layer in $layersJson) {
        $name = $layer.name
        $version = $layer.version
        $libPip = $layer.lib_pip
        
        if ([string]::IsNullOrEmpty($libPip)) {
            Write-Info "Installing layer: $name version: $version"
            
            Expand-Archive -Path "temp_layers/$name.zip" -DestinationPath "temp_layers/$name" -Force
            Write-Error-And-Exit $LASTEXITCODE "Error extracting layer $name"
            
            $condaBase = conda info --base
            $sourcePath = "temp_layers/$name/python/lib/python3.12/site-packages/*"
            $destPath = "$condaBase/envs/$nameVirtEnv/Lib/site-packages/"
            
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
            Write-Error-And-Exit $LASTEXITCODE "Error copying layer $name to conda"
        }
    }
}

function Install-PipLibraries {
    param(
        [string]$layers,
        [string]$functionName
    )
    
    $nameVirtEnv = $functionName -replace '"', '' + "-env"
    $layersJson = $layers | ConvertFrom-Json
    
    foreach ($layer in $layersJson) {
        $libPip = $layer.lib_pip
        
        if (-not [string]::IsNullOrEmpty($libPip)) {
            Write-Info "Installing pip library: $libPip"
            conda run -n $nameVirtEnv pip install $libPip
            Write-Error-And-Exit $LASTEXITCODE "Error installing pip library: $libPip"
        }
    }
}

function Initialize-Environment {
    param(
        [string]$configFile = "lambda-config.json"
    )
    
    Test-JsonConfig $configFile
    Test-CondaInstalled
    
    $config = Get-Content $configFile | ConvertFrom-Json
    $functionName = $config.functionName
    $runtime = $config.infraestructure.runtime
    $layers = $config.infraestructure.layers | ConvertTo-Json
    
    New-CondaEnvironment $runtime $functionName
    
    if (-not (Test-Path "temp_layers")) {
        New-Item -ItemType Directory -Path "temp_layers"
    }
    
    Get-Layers $layers
    Install-Layers $layers $functionName
    Install-PipLibraries $layers $functionName
    
    Write-Info "Environment preparation completed successfully"
}
