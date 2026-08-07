#!/bin/bash
# Script para instalar o Docker via Intune e configurar o grupo docker

# 1. Detecção
# Verifica se o docker-ce está instalado e se o grupo docker existe
if dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -q "install ok installed" && getent group docker > /dev/null; then
    echo "O Docker já está instalado."
    exit 0
fi

echo "Iniciando a Installation do Docker Oficial..."
export DEBIAN_FRONTEND=noninteractive

# 2. Remover versões antigas (conflitantes) caso existam
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null

# 3. Instalar dependências pré-requisitos
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg lsb-release apt-transport-https

# 4. Configurar chave GPG oficial do Docker
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
chmod 644 /etc/apt/keyrings/docker.gpg

# 5. Adicionar repositório oficial
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# 6. Instalar o Docker Engine, CLI, Containerd e Plugins (Buildx e Compose)
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 7. Configuração de Permissões (Grupo Docker)
# O pacote docker-ce já cria o grupo 'docker', mas garantimos aqui
if ! getent group docker > /dev/null; then
    groupadd docker
fi

# O Intune roda scripts como ROOT. Para que o usuário final possa usar o Docker 
# sem precisar de 'sudo', precisamos adicioná-lo ao grupo docker.
# Como pode haver o usuário default (Corporatexperience) e usuários Entra ID, 
# varremos a pasta /home e adicionamos todos os perfis existentes ao grupo.
echo "Adicionando usuários locais ao grupo docker..."
for user_dir in /home/*; do
    if [ -d "$user_dir" ]; then
        username=$(basename "$user_dir")
        usermod -aG docker "$username" 2>/dev/null
        echo "-> Usuário '$username' adicionado ao grupo docker."
    fi
done

# 8. Reiniciar e Habilitar serviço
systemctl restart docker
systemctl enable docker

echo "Installation do Docker concluída com sucesso!"


