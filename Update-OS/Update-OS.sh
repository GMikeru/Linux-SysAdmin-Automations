#!/bin/bash
# Validate and install Ubuntu OS updates

echo "Sincronizando lista de pacotes..."
apt-get update -qq

# Simula a atualização para verificar se há pacotes pendentes
UPGRADABLE_LINE=$(apt-get -s upgrade | grep "^[0-9]\+ upgraded")
UPGRADED_COUNT=$(echo "$UPGRADABLE_LINE" | awk '{print $1}')

# Verifica se a quantidade de pacotes para atualizar é 0
if [ "$UPGRADED_COUNT" = "0" ] || [ -z "$UPGRADED_COUNT" ]; then
    echo "O sistema operacional Ubuntu já está totalmente atualizado. Nenhuma ação necessária."
    exit 0
fi

echo "Foram encontrados $UPGRADED_COUNT pacotes para atualizar. Iniciando o processo de atualização..."

# Define variáveis de ambiente para garantir que a Installation seja totalmente silenciosa
# e não trave o script do Intune pedindo confirmações (ex: sobrescrever arquivos de configuração)
export DEBIAN_FRONTEND=noninteractive

# Realiza o upgrade seguro (mantendo arquivos de configuração locais existentes)
apt-get upgrade -y -q -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Realiza o dist-upgrade para cobrir atualizações de kernel ou pacotes que mudaram dependências
apt-get dist-upgrade -y -q -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Limpa os pacotes antigos e cache que não são mais necessários para liberar espaço
apt-get autoremove -y -q
apt-get clean

echo "Atualização do S.O concluída com sucesso."


