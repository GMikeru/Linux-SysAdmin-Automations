#!/bin/bash
# Script para instalar o Visual Studio Code via Intune

# 1. Detecção
if dpkg-query -W -f='${Status}' code 2>/dev/null | grep -q "install ok installed"; then
    echo "O Visual Studio Code já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do Visual Studio Code..."

# 2. Modo silencioso para automação
export DEBIAN_FRONTEND=noninteractive

# 3. Pré-requisitos
apt-get update -qq
apt-get install -y -qq wget gpg apt-transport-https

# 4. Adicionar a chave GPG da Microsoft
# Usamos a pasta recomendada moderna /usr/share/keyrings
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor --yes -o /usr/share/keyrings/packages.microsoft.gpg

# 5. Adicionar o repositório oficial do VSCode
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list

# 6. Atualizar a lista do apt e instalar o pacote 'code'
apt-get update -qq
apt-get install -y -qq code

echo "Installation do Visual Studio Code concluída com sucesso!"


