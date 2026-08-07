#!/bin/bash
# Script para instalar o Composer globalmente via Intune

# 1. Detecção (Idempotência)
if command -v composer >/dev/null 2>&1; then
    echo "O Composer já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do Composer..."

# 2. Modo silencioso para automação
export DEBIAN_FRONTEND=noninteractive

# Garantir que o PHP e dependências mínimas existam
if ! command -v php >/dev/null 2>&1; then
    echo "PHP não encontrado. Instalando php-cli e dependências mínimas..."
    apt-get update -qq
    apt-get install -y -qq php-cli unzip curl
fi

# 3. Baixar e verificar o instalador do Composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'c8b085408188070d5f52bcfe4ecfbee5f727afa458b2573b8eaaf77b3419b0bf2768dc67c86944da1544f06fa544fd47') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"

# 4. Instalar o Composer
# O Intune roda como root, adicionamos --quiet para não poluir o log
php composer-setup.php --quiet

# Limpar arquivo de Installation
php -r "unlink('composer-setup.php');"

# 5. Mover para /usr/local/bin (não precisa de sudo no contexto Intune)
echo "Movendo o Composer para /usr/local/bin/composer..."
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

echo "Installation do Composer concluída com sucesso!"


