#!/bin/bash

# Fonte de configuração
CONFIG_FILE="./config/ubuntu.yml"

# Função para instalar pacotes
install_packages() {
    PACKAGES=$(yq '.packages[]' "$CONFIG_FILE")
    echo "Instalando pacotes no Ubuntu..."
    sudo apt update
    sudo apt install -y $PACKAGES
}

# Função para aplicar configurações
apply_configurations() {
    echo "Aplicando configurações no Ubuntu..."
    yq '.configurations[]' "$CONFIG_FILE" | while IFS= read -r item; do
        command=$(echo "$item" | yq '.command')
        description=$(echo "$item" | yq '.description')
        echo "Executando: $description"
        eval "$command"
    done
}

# Executar funções
install_packages
apply_configurations

