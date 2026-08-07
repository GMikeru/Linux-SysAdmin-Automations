#!/bin/bash
# Script para instalar o MySQL Client via Intune
# Instala apenas o cliente de linha de comando (mysql), sem o servidor.

# 1. Detecção (Idempotência)
if dpkg-query -W -f='${Status}' mysql-client 2>/dev/null | grep -q "install ok installed"; then
    echo "O MySQL Client já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do MySQL Client..."

# 2. Configuração do modo silencioso
export DEBIAN_FRONTEND=noninteractive

# 3. Atualizar listas de pacotes
apt-get update -qq

# 4. Instalar o cliente MySQL
# O pacote 'mysql-client' já está nos repositórios oficiais do Ubuntu.
apt-get install -y -qq mysql-client

# 5. Validation
if [ $? -eq 0 ]; then
    echo "SUCESSO: Installation do MySQL Client concluída perfeitamente!"
    mysql --version
    exit 0
else
    echo "ERRO: Ocorreu uma falha na Installation do MySQL Client."
    exit 1
fi


