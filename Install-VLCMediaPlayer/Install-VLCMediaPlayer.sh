#!/bin/bash
# Script para instalar o VLC Media Player via Intune
# O VLC já está presente nos repositórios oficiais do Ubuntu.

# 1. Detecção (Idempotência)
if dpkg-query -W -f='${Status}' vlc 2>/dev/null | grep -q "install ok installed"; then
    echo "O VLC já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do VLC..."

# 2. Configuração do modo silencioso
export DEBIAN_FRONTEND=noninteractive

# 3. Atualizar listas de pacotes
apt-get update -qq

# 4. Instalar o VLC
apt-get install -y -qq vlc

# 5. Validation
if [ $? -eq 0 ]; then
    echo "SUCESSO: Installation do VLC concluída perfeitamente!"
    exit 0
else
    echo "ERRO: Ocorreu uma falha na Installation do VLC."
    exit 1
fi


