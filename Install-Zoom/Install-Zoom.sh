#!/bin/bash
# Script para instalar o Zoom via Intune
# O script baixa diretamente o cliente mais recente da página oficial.

ZOOM_URL="https://zoom.us/client/latest/zoom_amd64.deb"
TMP_DEB="/tmp/zoom_amd64.deb"

# 1. Detecção (Idempotência)
# O pacote oficial do Zoom para Linux atende pelo nome 'zoom' no dpkg.
if dpkg-query -W -f='${Status}' zoom 2>/dev/null | grep -q "install ok installed"; then
    echo "O Zoom já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do Zoom..."

# 2. Configuração do modo silencioso
export DEBIAN_FRONTEND=noninteractive

# 3. Pré-requisitos (Garante que wget exista)
apt-get update -qq
apt-get install -y -qq wget

# 4. Baixar o pacote direto do site oficial
echo "Baixando a última versão do Zoom para Linux..."
if ! wget -q -O "$TMP_DEB" "$ZOOM_URL"; then
    echo "ERRO: Falha ao baixar o pacote deb do Zoom."
    exit 1
fi

# 5. Instalar o pacote
# IMPORTANTE: Usamos 'apt-get install' passando o arquivo local (.deb) porque 
# o Zoom depende de inúmeras bibliotecas gráficas (libgl1, libegl1, libxcb).
# Se usássemos o antigo 'dpkg -i', a Installation quebraria pedindo dependências.
# O apt resolve isso perfeitamente de forma automática na mesma chamada.
echo "Aplicando o pacote e resolvendo dependências de sistema..."
apt-get install -y -qq "$TMP_DEB"

# Limpeza após Installation
rm -f "$TMP_DEB"

# 6. Validation
if [ $? -eq 0 ]; then
    echo "SUCESSO: Installation do Zoom concluída perfeitamente!"
    exit 0
else
    echo "ERRO: Ocorreu uma falha na Installation do Zoom."
    exit 1
fi


