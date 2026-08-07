#!/bin/bash
# Script para instalar o Slack via Intune/Landscape
# Instala no sistema e garante o funcionamento (compatível com distros RHEL/Fedora e Debian/Ubuntu).


SLACK_RPM_URL="https://scconfigmgrappdataCorporate.blob.core.windows.net/customization/slack-4.49.89-0.1.el8.x86_64.rpm"
TMP_DIR="/tmp/slack_install"
TMP_RPM="${TMP_DIR}/slack.rpm"


# Função para verificar se o Slack está instalado e funcionando (Health Check)
check_slack_health() {
   # 1. Verifica se o comando existe no PATH
   if ! command -v slack &>/dev/null; then
       return 1
   fi


   # 2. Descobre o caminho real do executável do Slack
   local slack_bin
   slack_bin=$(readlink -f "$(command -v slack)")
  
   if [ ! -f "$slack_bin" ]; then
       return 1
   fi

   # 4. Executa a checagem de versão. Apps corrompidos ou bloqueados pelo AppArmor geralmente falham aqui.
   # Como o Intune/Landscape roda como root, o Electron crasha (Trace/breakpoint trap) se não usarmos --no-sandbox
   local extra_args=""
   if [ "$EUID" -eq 0 ]; then
       extra_args="--no-sandbox"
   fi


   if ! "$slack_bin" $extra_args --version &>/dev/null; then
       return 1
   fi


   return 0
}


echo "================================================="
echo " Verificação de Installation e Saúde do Slack"
echo "================================================="


if check_slack_health; then
   echo "O Slack já está instalado e funcionando perfeitamente no sistema."
   exit 0
else
   echo "Slack não encontrado ou a Installation atual está corrompida."
   echo "Iniciando processo de Installation/correção..."
fi


mkdir -p "$TMP_DIR"


if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
   # ---------- Distros baseadas em RHEL / Fedora / CentOS ----------
   echo "Sistema baseado em RPM detectado."


   if rpm -qa | grep -q slack; then
       echo "Removendo pacote corrompido do Slack..."
       if command -v dnf &>/dev/null; then
           dnf remove -y slack
       else
           yum remove -y slack
       fi
   fi


   echo "Baixando o pacote Slack do repositório corporativo..."
   if ! curl -fsSL -o "$TMP_RPM" "$SLACK_RPM_URL"; then
       echo "ERRO: Falha ao baixar o pacote RPM do Slack."
       rm -rf "$TMP_DIR"
       exit 1
   fi


   echo "Instalando o Slack..."
   if command -v dnf &>/dev/null; then
       dnf install -y "$TMP_RPM"
   else
       yum localinstall -y "$TMP_RPM"
   fi


elif command -v apt-get &>/dev/null; then
   # ---------- Distros baseadas em Debian / Ubuntu ----------
   echo "Sistema baseado em Debian/Ubuntu detectado."
   export DEBIAN_FRONTEND=noninteractive


   if dpkg -l | grep -q slack; then
       echo "Removendo pacote corrompido do Slack..."
       apt-get remove -y --purge slack
   fi


   echo "Instalando pré-requisitos e bibliotecas base..."
   apt-get update -qq
   # Instala dependências incluindo libatomic1 e libasound2 (comuns em Electron, não mapeadas pelo alien)
   # Tenta usar libasound2t64 (Ubuntu 24.04+) se disponível, senão usa libasound2 (Ubuntu 22.04 e anteriores)
   apt-get install -y -qq curl alien libatomic1 libasound2t64 || apt-get install -y -qq curl alien libatomic1 libasound2


   echo "Baixando o pacote Slack do repositório corporativo..."
   if ! curl -fsSL -o "$TMP_RPM" "$SLACK_RPM_URL"; then
       echo "ERRO: Falha ao baixar o pacote RPM do Slack."
       rm -rf "$TMP_DIR"
       exit 1
   fi


   echo "Convertendo pacote RPM para DEB..."
   cd "$TMP_DIR" || exit 1
   alien --to-deb --scripts "$TMP_RPM"


   TMP_DEB=$(find "$TMP_DIR" -maxdepth 1 -name "*.deb" | head -1)
   if [ -z "$TMP_DEB" ]; then
       echo "ERRO: Falha na conversão do pacote RPM para DEB."
       rm -rf "$TMP_DIR"
       exit 1
   fi


   echo "Instalando o Slack..."
   apt-get install -y -qq "./$(basename "$TMP_DEB")"


   # ---------- FIXES COMUNS PARA ELECTRON EM DEBIAN/UBUNTU ----------
  
   # 1. Correção de permissão do Chrome Sandbox (perdida na conversão com Alien)
   # Sem o bit SUID (4755), o app Electron falha ao criar o sandbox e não abre.
   if [ -f "/usr/lib/slack/chrome-sandbox" ]; then
       echo "Corrigindo permissões do chrome-sandbox..."
       chown root:root "/usr/lib/slack/chrome-sandbox"
       chmod 4755 "/usr/lib/slack/chrome-sandbox"
   fi


   # 2. Correção de AppArmor para Ubuntu 24.04+ (Noble)
   # Ubuntu 24.04+ restringe unprivileged User Namespaces. Sem uma política, apps Electron fecham silenciosamente.
   if [ -d "/etc/apparmor.d" ] && command -v apparmor_parser &>/dev/null; then
       echo "Aplicando regra do AppArmor para permitir o Slack..."
       cat << 'EOF' > /etc/apparmor.d/slack
abi <abi/4.0>,
include <tunables/global>


profile slack /usr/lib/slack/slack flags=(unconfined) {
 userns,
 include if exists <local/slack>
}
EOF
       # Recarrega o perfil do apparmor sem interromper o script caso dê erro
       apparmor_parser -r /etc/apparmor.d/slack 2>/dev/null || true
   fi


else
   echo "ERRO: Gestor de pacotes não suportado. Instale o Slack manualmente."
   rm -rf "$TMP_DIR"
   exit 1
fi


# 6. Limpeza
rm -rf "$TMP_DIR"


# 7. Validation Final
echo "Realizando Validation final..."
if check_slack_health; then
   echo "SUCESSO: Installation do Slack concluída perfeitamente e funcionando!"
   exit 0
else
   echo "ERRO: Ocorreu uma falha na Installation ou o Slack continua quebrado."
   exit 1
fi

