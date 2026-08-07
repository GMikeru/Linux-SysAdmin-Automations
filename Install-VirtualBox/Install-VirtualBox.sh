#!/bin/bash
# Script para instalar o Oracle VirtualBox via Intune
# Utiliza o repositório oficial da Oracle para garantir atualizações contínuas.

# 1. Detecção
if dpkg-query -W -f='${Status}' virtualbox-7.1 2>/dev/null | grep -q "install ok installed"; then
    echo "O VirtualBox já está instalado no sistema."
    exit 0
fi

echo "Iniciando a Installation do VirtualBox..."

# 2. Configuração do modo silencioso
export DEBIAN_FRONTEND=noninteractive

# 3. Pré-requisitos
# O VirtualBox precisa de headers do kernel e ferramentas de compilação
# para montar os módulos do kernel (vboxdrv, vboxnetflt, etc).
apt-get update -qq
apt-get install -y -qq wget gpg apt-transport-https dkms linux-headers-$(uname -r)

# 4. Registrar as chaves GPG oficiais da Oracle
wget -qO - https://www.virtualbox.org/download/oracle_vbox_2016.asc | gpg --dearmor --yes -o /usr/share/keyrings/oracle-virtualbox-2016.gpg

# 5. Adicionar o repositório oficial da Oracle
CODENAME=$(lsb_release -cs)
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $CODENAME contrib" > /etc/apt/sources.list.d/virtualbox.list

# 6. Atualizar cache e instalar
apt-get update -qq
apt-get install -y -qq virtualbox-7.1

# 7. Adicionar todos os usuários humanos ao grupo 'vboxusers'
# Sem isso, os devs não conseguem acessar dispositivos USB dentro das VMs.
for user_home in /home/*; do
    username=$(basename "$user_home")
    if id "$username" &>/dev/null; then
        usermod -aG vboxusers "$username"
        echo "Usuário '$username' adicionado ao grupo vboxusers."
    fi
done

# 8. Validation
if [ $? -eq 0 ]; then
    echo "SUCESSO: Installation do VirtualBox concluída perfeitamente!"
    exit 0
else
    echo "ERRO: Ocorreu uma falha na Installation do VirtualBox."
    exit 1
fi


