#!/bin/bash

# 1. Detecção
if dpkg-query -W -f='${Status}' flameshot 2>/dev/null | grep -q "install ok installed"; then
    echo "O Flameshot já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do Flameshot..."

# 2. Configuração do modo silencioso
export DEBIAN_FRONTEND=noninteractive

# 3. Sincronizar as listas de pacotes do Ubuntu
apt-get update -qq

# 4. Instalar o aplicativo Flameshot
apt-get install -y -qq flameshot

# 5. Validation
if [ $? -eq 0 ]; then
    echo "SUCESSO: Installation do Flameshot concluída perfeitamente!"
    exit 0
else
    echo "ERRO: Ocorreu uma falha na Installation do Flameshot."
    exit 1
fi


