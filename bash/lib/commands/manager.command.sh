#!/bin/bash
# ==========================================================================================================================
# Name Script:  lib/commands/manager.command.sh
# Description:  
#               
# ==========================================================================================================================
runtime_aws() {
    ARG_ACT=$1
    if [[ $ARG_ACT == "deploy" ]]; then
        handle_info "The command zlambda deploy is not implemented. Use -r aws -a deploy"
        exit 1
    else
        handle_error 1 "Invalid action $ARG_ACT"
    fi
}
runtime_local() {
    ARG_ACT=$1
    CONTENT_FILE_CONFIG=$2
    if [[ $ARG_ACT == "prepare-env" ]]; then
        handle_info "Creating virtual environment..."
        prepare_env $CONTENT_FILE_CONFIG
    elif [[ $ARG_ACT == "run" ]]; then
        handle_info "Running lambda..."
        lambda_run $CONTENT_FILE_CONFIG
    else
        handle_error 1 "Invalid action $ARG_ACT"
    fi
}