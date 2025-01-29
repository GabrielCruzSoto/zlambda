create_envionment() {
    runtime_lambda=$1
    function_name=$2
    echo "function_name: $function_name"
    name_virt_env=$(echo "${function_name}-env"|sed 's/"//g')
    handle_info "Creating virtual environment: $name_virt_env"
    if ! conda env list | grep -q "$name_virt_env"; then
        conda create -n "$name_virt_env" python="${runtime_lambda//\"/}" -y
        handle_error $? "Error creating virtual environment: $name_virt_env"
    fi
    eval "$(conda shell.bash hook)"
    conda activate "$name_virt_env"
    handle_error $? "Error activating virtual environment: $name_virt_env"
}
layers_download() {
    layers=$1
    handle_info "Downloading layers..."
    echo "$layers" | jq -c '.[]' | while read -r layer; do
        name=$(echo "$layer" | jq -r '.name')
        version=$(echo "$layer" | jq -r '.version')
        lib_pip=$(echo "$layer" | jq -r '.lib_pip')
        if [ -z "$lib_pip" ] || [ "$lib_pip" == "null" ]; then

            handle_info "Downloading layer: $name version: $version"
            aws lambda get-layer-version \
                --layer-name "$name" \
                --version-number "$version" \
                --query 'Content.Location' \
                --output text | xargs curl -o "temp_layers/${name}.zip"
            handle_error $? "Error al descargar Layers $name de AWS "
            handle_info "Downloading layer: $name version: $version successful"
        fi
    done
}
layers_install() {
    layers=$1
    function_name=$2
    name_virt_env=$(echo "${function_name}-env"|sed 's/"//g')

    echo "$layers" | jq -c '.[]' | while read -r layer; do
        name=$(echo $layer | jq -r '.name')
        version=$(echo $layer | jq -r '.version')
        lib_pip=$(echo $layer | jq -r '.lib_pip')
        if [ -z "$lib_pip" ] || [ "$lib_pip" == "null" ]; then
            handle_info "Installing layer: $name version: $version"
            unzip -q "temp_layers/${name}.zip" -d "temp_layers/${name}"
            handle_error $? "Error al descomprimir layer $name"
            cp -r "temp_layers/${name}/python/lib/python3.12/site-packages/"* "$(conda info --base)/envs/$name_virt_env/lib/python3.12/site-packages/"
            handle_error $? "Error al copiar layer $name a conda" 
        fi
    done
    rm -rf "temp_layers/${name}"
}

install_lib_pip() {
    layers=$1
    function_name=$2
    name_virt_env=$(echo "${function_name}-env"|sed 's/"//g')
    conda activate "$name_virt_env"
    handle_error $? "Error al activar entorno virtual: $name_virt_env"

    handle_info "Installing lib pip..."
    echo "$layers" | jq -c '.[]' | while read -r layer; do
        name=$(echo $layer | jq -r '.name')
        version=$(echo $layer | jq -r '.version')
        lib_pip=$(echo $layer | jq -r '.lib_pip')
        if [ -n "$lib_pip" ] && [ "$lib_pip" != "null" ]; then
            handle_info "lib_pip: $lib_pip"
            pip install $lib_pip
            handle_error $? "Error al instalar lib pip $lib_pip"
        fi
    done
}


prepare_env() {
    lambda_config=$1
    function_name=$(echo $lambda_config | jq -c '.functionName')
    runtime_lambda=$(echo $lambda_config | jq -c '.infraestructure.runtime')
    runtime_lambda=$(echo $runtime_lambda | sed 's/python//')
    echo "runtime_lambda: $runtime_lambda"
    layers=$(echo $lambda_config | jq -c '.infraestructure.layers')
    rm -rf temp_layers
    mkdir temp_layers
    create_envionment $runtime_lambda $function_name
    layers_download $layers
    layers_install $layers $function_name
    install_lib_pip $layers $function_name
    rm -rf temp_layers
}
