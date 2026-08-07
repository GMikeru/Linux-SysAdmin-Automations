#!/bin/bash
# Script para instalar o NVM e Node.js v24 via Intune

export NVM_DIR="/usr/local/nvm"

# 1. Detecção (Idempotência)
# Verificamos se o script do NVM existe e se o Node 24 já está registrado nele
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    if nvm ls 24 >/dev/null 2>&1; then
        echo "O NVM e o Node.js v24 já estão instalados globalmente."
        exit 0
    fi
fi

echo "Iniciando a Installation do NVM e Node.js v24..."

# 2. Pré-requisitos e Modo Silencioso
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl build-essential

# 3. Installation Global do NVM
# Por padrão o NVM tenta se instalar em ~/.nvm (que no Intune seria /root/.nvm).
# Forçando a variável NVM_DIR para /usr/local/nvm garantimos que ele vá para uma pasta pública.
mkdir -p "$NVM_DIR"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash

# 4. Configuração do Profile (Menu do Terminal)
# Colocamos um script no profile.d. Isso faz com que TODO usuário da máquina
# (incluindo usuários do Azure AD) carreguem o NVM automaticamente ao abrir o Terminal,
# sem precisarem alterar o ~/.bashrc de cada um.
cat << 'EOF' > /etc/profile.d/nvm.sh
# Exporta a variável NVM global
export NVM_DIR="/usr/local/nvm"
# Carrega o NVM
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# Carrega o autocompletar (Tab) do bash
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF

chmod 644 /etc/profile.d/nvm.sh

# 5. Carregar o NVM neste script para prosseguir
. "$NVM_DIR/nvm.sh"

# 6. Instalar o Node.js v24
echo "Baixando e instalando o Node.js versão 24..."
nvm install 24
nvm alias default 24
nvm use default

# 7. Ajuste de Permissões
# Como o root instalou o Node, os arquivos pertencem ao root.
# Damos permissão total a essa pasta global para que os desenvolvedores
# consigam dar `nvm install` em outras versões no futuro sem tomar "Permission Denied"
# ou necessitar usar sudo (o NVM quebra se usado com sudo).
chmod -R a+rwx "$NVM_DIR"

if [ $? -eq 0 ]; then
    echo "SUCESSO: NVM e Node.js v24 instalados e configurados para todos os usuários!"
    exit 0
else
    echo "ERRO: Ocorreu uma falha durante a Installation do Node via NVM."
    exit 1
fi


