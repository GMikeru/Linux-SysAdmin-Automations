#!/bin/bash
# Script para instalar o Git via Intune

# 1. Detecção
if dpkg-query -W -f='${Status}' git 2>/dev/null | grep -q "install ok installed"; then
    echo "O Git já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do Git..."

# 2. Configuração de modo totalmente silencioso
export DEBIAN_FRONTEND=noninteractive

# 3. Adicionar o Repositório Oficial do Git (PPA)
# As versões que vêm nativas no Ubuntu tendem a ficar defasadas rápido. 
# Adicionar o PPA garante que os desenvolvedores tenham acesso aos recursos mais novos do Git.
apt-get update -qq
apt-get install -y -qq software-properties-common
add-apt-repository -y ppa:git-core/ppa

# 4. Atualizar lista do apt com o novo repositório e instalar
apt-get update -qq
apt-get install -y -qq git

# 5. Validation
if [ $? -eq 0 ]; then
    echo "SUCESSO: Installation do Git concluída perfeitamente!"
    exit 0
else
    echo "ERRO: Ocorreu uma falha na Installation do Git."
    exit 1
fi


