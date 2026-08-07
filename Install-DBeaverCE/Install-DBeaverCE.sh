#!/bin/bash
# Script para instalar o DBeaver CE via Intune
# Utiliza o repositório oficial para garantir que o cliente de banco de dados
# receba atualizações automáticas de segurança juntamente com o sistema.

# 1. Detecção (Idempotência)
# O pacote oficial do DBeaver Community Edition chama-se 'dbeaver-ce'
if dpkg-query -W -f='${Status}' dbeaver-ce 2>/dev/null | grep -q "install ok installed"; then
    echo "O DBeaver CE já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do DBeaver CE..."

# 2. Configuração de modo totalmente silencioso (padrão Intune)
export DEBIAN_FRONTEND=noninteractive

# 3. Pré-requisitos
apt-get update -qq
apt-get install -y -qq wget gpg apt-transport-https

# 4. Obter e registrar a chave GPG oficial da DBeaver
# Utilizamos o método "gpg --dearmor" para ser compatível com as 
# rígidas regras de segurança do Ubuntu 22.04+ (que baniu o apt-key).
wget -qO - https://dbeaver.io/debs/dbeaver.gpg.key | gpg --dearmor --yes -o /usr/share/keyrings/dbeaver-archive-keyring.gpg

# 5. Registrar o repositório oficial no sistema
echo "deb [signed-by=/usr/share/keyrings/dbeaver-archive-keyring.gpg] https://dbeaver.io/debs/dbeaver-ce /" > /etc/apt/sources.list.d/dbeaver.list

# 6. Atualizar o cache do apt para enxergar o novo repositório e instalar
apt-get update -qq
apt-get install -y -qq dbeaver-ce

# 7. Validation
if [ $? -eq 0 ]; then
    echo "SUCESSO: Installation do DBeaver CE concluída perfeitamente!"
    exit 0
else
    echo "ERRO: Ocorreu uma falha no processo de Installation do DBeaver."
    exit 1
fi


