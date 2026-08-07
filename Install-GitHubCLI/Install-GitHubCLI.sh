#!/bin/bash
# Script para instalar o GitHub CLI (gh) via Intune

# 1. Detecção (Idempotência)
# O pacote oficial chama-se 'gh'
if dpkg-query -W -f='${Status}' gh 2>/dev/null | grep -q "install ok installed"; then
    echo "O GitHub CLI (gh) já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do GitHub CLI..."

# 2. Configuração de modo totalmente silencioso para Intune
export DEBIAN_FRONTEND=noninteractive

# 3. Garantir pacotes base para download de chaves
apt-get update -qq
apt-get install -y -qq curl gpg apt-transport-https

# 4. Baixar e registrar a chave GPG oficial
# Usamos o caminho padronizado da GitHub para a chave criptográfica
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

# 5. Registrar o repositório apt da GitHub
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list

# 6. Baixar e Instalar de fato o CLI
apt-get update -qq
apt-get install -y -qq gh

# 7. Verificação final
if [ $? -eq 0 ]; then
    echo "SUCESSO: Installation do GitHub CLI concluída perfeitamente!"
    exit 0
else
    echo "ERRO: Ocorreu uma falha no download ou Installation do pacote 'gh'."
    exit 1
fi


