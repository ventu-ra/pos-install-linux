#!/bin/bash

echo "Iniciando o processo de instalação..."

DISTRO=$(cat /etc/*release | grep ^ID= | cut -d '=' -f 2)

CONFIG_DIR="./config"
SCRIPTS_DIR="./scripts"

echo "Distribuição detectada: $DISTRO"


case "$DISTRO" in
  fedora)
    echo "Executando script para Ubuntu..."
    bash fedora/install.sh
    ;;
  *)
    echo "Distrobuição não suportada"
    exit 1
    ;;
esac
