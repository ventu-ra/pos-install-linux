#!/bin/bash
set -x  # Adiciona saída de depuração

# Fonte de configuração
CONFIG_FILE="./config/ubuntu.yml"

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

    # Verifica se o yq está instalado; se não, instala
    if ! command -v yq &> /dev/null; then
        echo "yq não encontrado. Instalando..."
        VERSION="v4.21.1"  # Substitua pela versão desejada
        BINARY="yq"
        wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}_linux_amd64.tar.gz -O - |\
        tar xz && sudo mv ${BINARY} /usr/bin/yq
        sudo chmod +x /usr/bin/yq
    fi

    # Usa yq para ler a lista de pacotes e monta uma string com todos os pacotes
    PACKAGES=$(yq e '.packages[]' "$CONFIG_FILE" | xargs)
    echo "Pacotes a serem instalados: $PACKAGES"

    if [ -z "$PACKAGES" ]; then
        echo "Nenhum pacote encontrado no arquivo de configuração. Abortando."
        exit 1
    fi

    echo "Instalando pacotes no Ubuntu..."
    sudo apt update
    sudo apt install -y $PACKAGES
}

# Função para aplicar configurações
apply_configurations() {
    echo "Aplicando configurações no Ubuntu..."

    # Usa yq para iterar sobre cada configuração
    yq e '.configurations[] | select(.command != null)' "$CONFIG_FILE" | while IFS= read -r item; do
        command=$(echo "$item" | yq e '.command' -)
        description=$(echo "$item" | yq e '.description' -)

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

echo "Ativando o GDM (GNOME Display Manager)"
sudo systemctl enable --now gdm
sudo systemctl start --now gdm

echo "Reiniciando o sistema"
# Descomente a linha abaixo para reiniciar o sistema
# sudo reboot
