#!/bin/bash
# Script para instalar Python3, Pip e Venv via Intune

# 1. Detecção
if dpkg -l | grep -q "python3 " && \
   dpkg -l | grep -q "python3-pip " && \
   dpkg -l | grep -q "python3-venv "; then
    echo "Python3, Pip e Venv já estão instalados no sistema."
    exit 0
fi

echo "Instalando Python3, Pip e Venv..."

# 2. Configuração de ambiente silencioso para Intune
export DEBIAN_FRONTEND=noninteractive

# 3. Atualização de repositórios e Installation
apt-get update -qq
apt-get install -y -qq python3 python3-pip python3-venv

echo "Installation concluída com sucesso!"


