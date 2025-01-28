#!/bin/bash
# ==========================================================================================================================
# Name Script:  lib/commands/local.lambda-run.sh
# Description:  This script allows you to run a Lambda Function locally.
#               
# ==========================================================================================================================


lambda_run() {
    lambda_config=$1
    function_name=$(echo "$lambda_config"| jq -r '.functionName')
    echo "function_name: $function_name"
    lambda_config_vars=$(echo "$lambda_config"| jq -c '.infraestructure.env.Variables')
    for key in $(echo "${lambda_config_vars}" | jq -r 'keys[]'); do
        value=$(echo "${lambda_config_vars}" | jq -r ".[\"${key}\"]")
        export "${key}=${value}"
        echo "key: $key, value: $value"
    done
    name_virt_env=$(echo "${function_name}-env"|sed 's/"//g')
    eval "$(conda shell.bash hook)"
    conda activate "$name_virt_env"
    handle_error $? "Error activating virtual environment: $name_virt_env"
    python3 main.py
}