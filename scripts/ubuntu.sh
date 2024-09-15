#!/bin/bash
set -x  # Adiciona saída de depuração

# Fonte de configuração
CONFIG_FILE="./config/ubuntu.json"

# Função para remover aplicativos Snap e GNOME padrão
cleanup_system() {
    echo "Removendo GNOME padrão..."
    sudo apt-get remove --purge -y gnome-shell gnome-core ubuntu-gnome-desktop
    sudo apt-get autoremove -y

    echo "Removendo aplicativos Snap..."
    SNAP_APPS=$(snap list | awk 'NR>1 {print $1}')
    if [ -n "$SNAP_APPS" ]; then
        for app in $SNAP_APPS; do
            echo "Removendo snap: $app"
            sudo snap remove "$app"
        done
    else
        echo "Nenhum aplicativo Snap encontrado para remoção."
    fi

    echo "Removendo snapd..."
    sudo apt-get remove --purge -y snapd
    sudo apt-get autoremove -y

    echo "Instalando Snap..."
    sudo apt update
    sudo apt install -y snapd
    sudo systemctl enable --now snapd.socket
}

# Função para instalar pacotes
install_packages() {
    # Chama a função de limpeza
    # cleanup_system

    # Verifica se o jq está instalado; se não, instala
    if ! command -v jq &> /dev/null; then
        echo "jq não encontrado. Instalando..."
        sudo apt update
        sudo apt install -y jq
    fi

    # Usa jq para ler a lista de pacotes e monta uma string com todos os pacotes
    PACKAGES=$(jq -r '.packages[]' "$CONFIG_FILE" | xargs)
    echo "Pacotes a serem instalados: $PACKAGES"

    if [ -z "$PACKAGES" ]; then
        echo "Nenhum pacote encontrado no arquivo de configuração. Abortando."
        exit 1
    fi

        # Usa jq para ler a lista de pacotes e itera sobre eles
    jq -r '.packages[]' "$CONFIG_FILE" | while IFS= read -r package; do
        if [ -n "$package" ]; then
            echo "Instalando o pacote: $package"
            sudo apt-get install -y "$package"

            # Verifica se a instalação foi bem-sucedida
            if [ $? -eq 0 ]; then
                echo "Pacote $package instalado com sucesso."
            else
                echo "Erro ao instalar o pacote $package."
            fi
        fi
    done
}

# Função para aplicar configurações
apply_configurations() {
    echo "Aplicando configurações no Ubuntu..."

    # Usa jq para iterar sobre cada configuração
    jq -c '.configurations[] | select(.command != null)' "$CONFIG_FILE" | while IFS= read -r item; do
        command=$(echo "$item" | jq -r '.command')
        description=$(echo "$item" | jq -r '.description')

        echo "Executando: $description"

        # Verifica se o comando não é nulo antes de executar
        if [ -n "$command" ]; then
            eval "$command"
        else
            echo "Comando vazio ou não encontrado"
        fi
    done
}

# Executar funções
install_packages
apply_configurations

# echo "Ativando o GDM (GNOME Display Manager)"
# sudo systemctl enable --now gdm
# sudo systemctl start --now gdm

echo "Reiniciando o sistema"
# Descomente a linha abaixo para reiniciar o sistema
# sudo reboot
