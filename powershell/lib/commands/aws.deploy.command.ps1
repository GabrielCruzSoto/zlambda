function Deploy-ToAws {
    Write-Host "Deploying Lambda function to AWS..."
    
    # Verify AWS CLI is installed
    try {
        $awsVersion = aws --version
        Write-Host "AWS CLI version: $awsVersion"
    }
    catch {
        throw "AWS CLI is required but not found. Please install AWS CLI first."
    }

    # Verify AWS credentials
    try {
        $caller = aws sts get-caller-identity | ConvertFrom-Json
        Write-Host "Deploying as: $($caller.Arn)"
    }
    catch {
        throw "AWS credentials not found or invalid. Please configure AWS credentials first."
    }

    # Package the Lambda function
    Write-Host "Packaging Lambda function..."
    if (-not (Test-Path "package")) {
        New-Item -ItemType Directory -Path "package"
    }

    # Copy source files
    Copy-Item -Path "src/*" -Destination "package/" -Recurse -Force
    
    if (Test-Path "requirements.txt") {
        Push-Location "package"
        try {
            pip install -r ../requirements.txt -t .
        }
        finally {
            Pop-Location
        }
    }

    # Create deployment package
    Compress-Archive -Path "package/*" -DestinationPath "function.zip" -Force
    
    # Deploy using CloudFormation
    if (Test-Path "config/templete-cf-lambda.yaml") {
        Write-Host "Deploying with CloudFormation..."
        aws cloudformation deploy `
            --template-file config/templete-cf-lambda.yaml `
            --stack-name lambda-function `
            --capabilities CAPABILITY_IAM `
            --parameter-overrides FunctionZipPath=function.zip
    }
    else {
        Write-Warning "CloudFormation template not found. Skipping deployment."
    }

    # Cleanup
    Remove-Item -Path "package" -Recurse -Force
    Remove-Item -Path "function.zip" -Force

    Write-Host "Deployment completed successfully!"
}