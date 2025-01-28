#!/bin/bash
# ==========================================================================================================================
# Name Script:  lib/utils.sh
# Description:  This script allows you to perform actions of a Lambda Function 
#               such as executing locally and deploying to AWS.
# ==========================================================================================================================
export VERSION="0.0.1-SNAPSHOT"
handle_info() {
    local message=$1
    echo "INFO| $message"
}

handle_error() {
    local exit_code=$1
    local error_message=$2
    if [ $exit_code -ne 0 ]; then
        echo "ERROR| $error_message"
        exit $exit_code
    fi
}

show_help() {
    echo "Uso: $0 [-r ARG_R] [-a ARG_A] [-h]"
    echo
    echo "Opciones:"
    echo "  -r ARG_R   Runtime execution (local/aws)"
    echo "  -a ARG_A   Action to perform (prepare-env, run, deploy)"
    echo "  -h         Show this help message and exit"
    echo "  -v         Show version and exit"
    exit 0
}

show_version() {
    echo "Version $VERSION"
    exit 0
}

validate_json_config() {
    local file_config=$1
    if [ ! -f "$file_config" ]; then
        echo "ERROR| No se encuentra el archivo de configuración: $file_config"
        exit 1
    fi
    local required_fields=("functionName" "infraestructure.runtime" "infraestructure.handler" "dirSource")
    for field in "${required_fields[@]}"; do
        if [ "$(jq -r ".$field" "$file_config")" == "null" ]; then
            echo "ERROR| Campo requerido faltante en config: $field"
            exit 1
        fi
    done
}

prepare_json_config() {
    local file_config=$1
    local file_environment=$2
    validate_json_config $file_config
    if [ ! -f "$file_environment" ]; then
        echo "ERROR| No se encuentra el archivo de configuración: $file_environment"
        exit 1
    fi
    source $file_environment
    content_config=$(jq -c '.' "$file_config")
    content_config=$(echo "$content_config" | envsubst)
    echo $content_config
}
validate_is_conda() {
    if ! command -v conda &> /dev/null; then
        handle_error 1 "Conda is not installed or not in PATH"
    fi   
}
