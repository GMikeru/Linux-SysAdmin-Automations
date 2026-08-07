#!/bin/bash
# Script para instalar o AWS Client VPN via Intune

# 1. Detecção (Idempotência)
if dpkg-query -W -f='${Status}' awsvpnclient 2>/dev/null | grep -q "install ok installed"; then
    echo "O AWS Client VPN já está instalado."
    exit 0
fi

echo "Iniciando a Installation do AWS Client VPN..."
export DEBIAN_FRONTEND=noninteractive

# 2. Instalar dependências necessárias
apt-get update -qq
apt-get install -y -qq wget gpg apt-transport-https

# 3. Adicionar a chave GPG oficial da AWS
wget -qO- https://d20adtppz83p9s.cloudfront.net/GTK/latest/debian-repo/awsvpnclient_public_key.asc > /etc/apt/trusted.gpg.d/awsvpnclient_public_key.asc

# 4. Configurar o repositório da AWS
echo "deb [arch=amd64] https://d20adtppz83p9s.cloudfront.net/GTK/latest/debian-repo ubuntu main" > /etc/apt/sources.list.d/aws-vpn-client.list

# 5. Atualizar repositório e instalar o VPN Client
apt-get update -qq
apt-get install -y -qq awsvpnclient

echo "Installation do AWS Client VPN concluída com sucesso!"


