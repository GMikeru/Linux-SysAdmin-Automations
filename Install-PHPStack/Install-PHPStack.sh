#!/bin/bash
# Script para instalar o PHP via Intune
# Utiliza o repositório PPA do Ondřej Surý (Padrão mundial para desenvolvedores PHP no Ubuntu)
# que garante a versão mais recente em vez das versões defasadas do sistema nativo.

# 1. Detecção (Idempotência)
# Se o pacote base 'php' ou 'php-cli' estiver instalado, ele não roda novamente
if dpkg-query -W -f='${Status}' php-cli 2>/dev/null | grep -q "install ok installed"; then
    echo "O PHP já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do PHP e suas extensões mais comuns..."

# 2. Configuração do modo totalmente silencioso para o Intune
export DEBIAN_FRONTEND=noninteractive

# 3. Preparando o sistema para receber repositórios externos (PPAs)
apt-get update -qq
apt-get install -y -qq software-properties-common curl ca-certificates lsb-release apt-transport-https

# 4. Adicionar o repositório PPA oficial de PHP para Ubuntu
# Isso garante acesso imediato às ramificações mais novas (ex: PHP 8.2, 8.3+)
echo "Adicionando PPA do Ondřej Surý..."
if ! add-apt-repository -y ppa:ondrej/php >/dev/null 2>&1 || ! apt-get update -qq >/dev/null 2>&1; then
    echo "Aviso: O PPA ppa:ondrej/php não suporta esta versão do Ubuntu ou está offline."
    echo "Limpando o repositório quebrado para não afetar o sistema e usando o PHP padrão..."
    add-apt-repository -r -y ppa:ondrej/php >/dev/null 2>&1 || true
    rm -f /etc/apt/sources.list.d/ondrej-ubuntu-php-*.sources /etc/apt/sources.list.d/ondrej-ubuntu-php-*.list
    apt-get update -qq || true
fi

# 5. Baixar e instalar o PHP
# Instalamos as bibliotecas centrais e também um pacote das extensões (módulos) 
# mais cobrados e usados pela comunidade e frameworks (Laravel, Symfony, etc).
apt-get install -y -qq php php-cli php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-bcmath

# 6. Validation
if [ $? -eq 0 ]; then
    echo "SUCESSO: Installation do PHP concluída perfeitamente!"
    # Exibe a versão instalada no log do Intune
    php -v
    exit 0
else
    echo "ERRO: Ocorreu uma falha no processo de Installation do PHP."
    exit 1
fi


