#!/bin/bash
# Script para instalar o Insomnia via Intune (Snap)

# 1. Detecção (Idempotência)
if snap list insomnia >/dev/null 2>&1; then
    echo "O Insomnia já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do Insomnia via Snap..."

# 2. Modo silencioso para automação
export DEBIAN_FRONTEND=noninteractive

# Garantir que o snapd está instalado (caso não esteja)
if ! command -v snap >/dev/null 2>&1; then
    echo "Snapd não encontrado. Instalando snapd..."
    apt-get update -qq
    apt-get install -y -qq snapd
fi

# 3. Instalar o pacote (sem sudo, pois Intune roda como root)
snap install insomnia

echo "Installation do Insomnia concluída com sucesso!"


