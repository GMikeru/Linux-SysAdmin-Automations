#!/bin/bash
# Script para instalar o Terraform via Intune
# Utiliza o repositório oficial da HashiCorp para atualizações contínuas.

# 1. Detecção (Idempotência)
if command -v terraform >/dev/null 2>&1; then
    echo "O Terraform já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do Terraform..."

# 2. Configuração do modo silencioso
export DEBIAN_FRONTEND=noninteractive

# 3. Pré-requisitos
apt-get update -qq
apt-get install -y -qq wget gpg apt-transport-https software-properties-common

# 4. Registrar a chave GPG oficial da HashiCorp
wget -qO - https://apt.releases.hashicorp.com/gpg | gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# 5. Adicionar o repositório oficial da HashiCorp
CODENAME=$(lsb_release -cs)
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $CODENAME main" > /etc/apt/sources.list.d/hashicorp.list

# 6. Atualizar cache e instalar
apt-get update -qq
apt-get install -y -qq terraform

# 7. Validation
if [ $? -eq 0 ]; then
    echo "SUCESSO: Installation do Terraform concluída perfeitamente!"
    terraform version
    exit 0
else
    echo "ERRO: Ocorreu uma falha na Installation do Terraform."
    exit 1
fi


