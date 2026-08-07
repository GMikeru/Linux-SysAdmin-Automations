#!/bin/bash
# Script para instalar o PostgreSQL Client via Intune
# Instala apenas o cliente de linha de comando (psql), sem o servidor.

# 1. Detecção
if dpkg-query -W -f='${Status}' postgresql-client 2>/dev/null | grep -q "install ok installed"; then
    echo "O PostgreSQL Client já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do PostgreSQL Client..."

# 2. Configuração do modo silencioso
export DEBIAN_FRONTEND=noninteractive

# 3. Atualizar listas de pacotes
apt-get update -qq

# 4. Instalar o cliente PostgreSQL
# O pacote 'postgresql-client' já está nos repositórios oficiais do Ubuntu.
apt-get install -y -qq postgresql-client

# 5. Validation
if [ $? -eq 0 ]; then
    echo "SUCESSO: Installation do PostgreSQL Client concluída perfeitamente!"
    psql --version
    exit 0
else
    echo "ERRO: Ocorreu uma falha na Installation do PostgreSQL Client."
    exit 1
fi


