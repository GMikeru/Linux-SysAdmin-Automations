#!/bin/bash
# Script para instalar o GitHub Desktop via Intune
# Utiliza o repositório Linux mais popular e estável do GitHub Desktop (fork oficial 'shiftkey')

# 1. Detecção (Idempotência)
if dpkg-query -W -f='${Status}' github-desktop 2>/dev/null | grep -q "install ok installed"; then
    echo "O GitHub Desktop já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do GitHub Desktop..."

# 2. Modo silencioso para automação Intune
export DEBIAN_FRONTEND=noninteractive

# 3. Pré-requisitos e Dependências
apt-get update -qq
apt-get install -y -qq wget gpg apt-transport-https

# 4. Obter a chave GPG do repositório seguro (usando o mirror MWT atualizado)
wget -qO - https://mirror.mwt.me/shiftkey-desktop/gpgkey | gpg --dearmor --yes -o /usr/share/keyrings/mwt-desktop.gpg

# Remover lista antiga se existir para evitar conflitos
rm -f /etc/apt/sources.list.d/shiftkey-packages.list

# 5. Adicionar o repositório do shiftkey ao APT
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/mwt-desktop.gpg] https://mirror.mwt.me/shiftkey-desktop/deb/ any main" > /etc/apt/sources.list.d/mwt-desktop.list

# 6. Atualizar repositórios novamente e realizar a Installation do pacote
apt-get update -qq
apt-get install -y -qq github-desktop

# 7. Validation
if [ $? -eq 0 ]; then
    echo "Installation do GitHub Desktop concluída com sucesso!"
    exit 0
else
    echo "ERRO: A Installation do pacote github-desktop falhou."
    exit 1
fi


