function Use-LocalPrepareEnvironment {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Content_json
    )
    
    $Function_Name = $Content_json.functionName
    $Runtime_Lambda = $Content_json.infraestructure.runtime
    $Runtime_Lambda = $Runtime_Lambda.Replace("python", "")
    $Name_Virt_Env = $Function_Name + "-env"
    $Layers = $Content_json.infraestructure.layers
    Write-Host "Preparing local environment..."
    New-CondaEnvironment $Name_Virt_Env $Runtime_Lambda
    if (-not (Test-Path "temp_layers")) {
        New-Item -ItemType Directory -Path "temp_layers"
    }else{
        Remove-Item temp_layers -Recurse -Force
        New-Item -ItemType Directory -Path "temp_layers"
    }
    Step-DownloaderLayerFromAWS -Layers $Layers -Name_Virt_Env $Name_Virt_Env
    Step-CopyLayersInEnvConda -Layers $Layers -Name_Virt_Env $Name_Virt_Env
    Step-InstallLibWithconda -Layers $Layers -Name_Virt_Env $Name_Virt_Env
    Remove-Item temp_layers -Recurse -Force
    Write-Host "Local environment prepared successfully!"

}

function Step-DownloaderLayerFromAWS {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Layers,

        [Parameter(Mandatory=$true)]
        [string]$Name_Virt_Env
    )

    foreach ($layer in $layers) {
        $name = $layer.name
        $version = $layer.version
        $libPip = $layer.lib_pip
        Write-Host "Layer: $name version: $version"
        
        if ([string]::IsNullOrEmpty($libPip)) {
            Write-Host "Downloading layer: $name version: $version"
            
            $location = aws lambda get-layer-version `
                --layer-name $name `
                --version-number $version `
                --query 'Content.Location' `
                --output text
                
            Invoke-WebRequest -Uri $location -OutFile "temp_layers/$name.zip"
            Write-Host "Downloading layer: $name version: $version successful"
        }
    }
        
}

function Step-CopyLayersInEnvConda {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Layers,
        
        [Parameter(Mandatory=$true)]
        [string]$Name_Virt_Env
    )
    foreach ($layer in $Layers) {
        $name = $layer.name
        $version = $layer.version
        $libPip = $layer.lib_pip
  
        if ([string]::IsNullOrEmpty($libPip)) {
            Write-Host "Installing layer: $name version: $version"
            Expand-Archive -Path "temp_layers/$name.zip" -DestinationPath "temp_layers/$name" -Force
            $condaBase = conda info --base
            $sourcePath = "temp_layers/$name/python/lib/python3.12/site-packages/*"
            $destPath = "$condaBase/envs/$Name_Virt_Env/Lib/site-packages/"
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
        }
    }
}

function Step-InstallLibWithconda {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Layers,
        
        [Parameter(Mandatory=$true)]
        [string]$Name_Virt_Env
    )
    foreach ($layer in $layers) {
        $libPip = $layer.lib_pip
        if (-not [string]::IsNullOrEmpty($libPip)) {
            Write-Host "Activando entorno virtual: $Name_Virt_Env"
            conda activate $Name_Virt_Env
            Write-Host "Intentando instalar librería: $libPip"
            
            # Mantener el formato original para pip
            $pipPackage = $libPip
            # Convertir formato para conda (== a =)
            $condaPackage = $libPip -replace '==', '='
            $packageName = $condaPackage.Split('=')[0]
            
            # Verificar si el paquete está en Conda
            $result = conda search $packageName 2>$null
            
            if ($result -match $packageName) {
                Write-Host "Instalando con conda: $condaPackage"
                try {
                    conda run -n $Name_Virt_Env conda install -y $condaPackage
                    if ($LASTEXITCODE -ne 0) {
                        throw "Error en la instalación con conda"
                    }
                }
                catch {
                    Write-Host "Falló la instalación con conda, intentando con conda-forge..."
                    conda run -n $Name_Virt_Env conda install -c conda-forge -y $libPip
                    if ($LASTEXITCODE -ne 0) {
                        Write-Host "Error instalando $pipPackage en el entorno $Name_Virt_Env" -ForegroundColor Red
                        exit 1
                    }
                }
            } else {
                Write-Host "Paquete no encontrado en conda, instalando con conda-forge: $pipPackage"
                conda run -n $Name_Virt_Env conda install -c conda-forge -y $libPip
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Error instalando $pipPackage en el entorno $Name_Virt_Env" -ForegroundColor Red
                    exit 1
                }
            }
            
            Write-Host "Librería instalada con éxito: $libPip"
        }
    }
}

function New-CondaEnvironment {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name_Virt_Env,
        [Parameter(Mandatory=$true)]
        [string]$Runtime_Lambda
    )
    try {
        if (-not (conda info --envs | Select-String -Pattern $Name_Virt_Env -Quiet)) {
            conda create -n $Name_Virt_Env python=$Runtime_Lambda -y
        }    
    }catch{
        Write-Host "Error creating conda environment: $Name_Virt_Env"
        exit 1
    }
    try{
        conda activate $Name_Virt_Env
    }catch{
        Write-Host "Error activating conda environment: $Name_Virt_Env"
        exit 1
    }
    Write-Host "Conda environment: $Name_Virt_Env created and activated"
}