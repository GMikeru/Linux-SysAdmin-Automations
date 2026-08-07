#!/bin/bash
# Script para instalar o .NET SDK via Intune
# 
# NOTA SOBRE O RUNTIME: O pacote do SDK ('dotnet-sdk') já inclui automaticamente
# todos os runtimes ('aspnetcore-runtime' e 'dotnet-runtime'). 
# Portanto, para desenvolvedores, basta instalar o SDK!

# Configuração da versão desejada
DOTNET_VERSION="10.0"

# 1. Detecção (Idempotência)
if dpkg-query -W -f='${Status}' "dotnet-sdk-$DOTNET_VERSION" 2>/dev/null | grep -q "install ok installed"; then
    echo "O .NET SDK $DOTNET_VERSION já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do .NET SDK $DOTNET_VERSION..."

# 2. Configuração do modo silencioso
export DEBIAN_FRONTEND=noninteractive

# 3. Atualizar pacotes
apt-get update -qq

# 4. Instalar o pacote do SDK
# Nos Ubuntus mais recentes, os pacotes do .NET já são integrados aos repositórios oficiais da Canonical.
# O pacote dotnet-sdk também carrega o aspnetcore-runtime como dependência automática.
apt-get install -y -qq "dotnet-sdk-$DOTNET_VERSION"

# 5. Validation
if [ $? -eq 0 ]; then
    echo "SUCESSO: Installation do .NET SDK $DOTNET_VERSION concluída perfeitamente!"
    # Exibe informações completas para gravar no log do Intune
    dotnet --info
    exit 0
else
    echo "ERRO: Ocorreu uma falha no processo de Installation do .NET."
    exit 1
fi


