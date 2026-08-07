#!/bin/bash
# ==============================================================================
# Script de Verificação / Atualização / Installation do Splunk UF - Intune
# ==============================================================================
# - Garante que as dependências de download (wget/curl) existam
# - Mantém idempotência (só instala/atualiza se necessário)

# --- Configurações ---
SPLUNK_HOME="/opt/splunkforwarder"
SPLUNK_USER_CONF="admin"
SPLUNK_PASSWORD="YourSecurePassword123"
DEPLOY_SERVER="10.0.0.52"
DEPLOY_PORT="8089"
INSTALLER_PATH="/tmp/splunkforwarder-linux-amd64.tgz"

# ATENÇÃO: Corrigido o LATEST_VERSION para bater com a URL (10.2.2) 
# para que o script não fique em loop eterno de atualização no Intune!
LATEST_VERSION="10.2.2"
LATEST_BUILD="80b90d638de6"
SPLUNK_URL="https://download.splunk.com/products/universalforwarder/releases/10.2.2/linux/splunkforwarder-10.2.2-80b90d638de6-linux-amd64.tgz"

# ==============================================================================
# FUNÇÕES AUXILIARES
# ==============================================================================

print_header() { echo "--- $1 ---"; }
print_step() { echo "[$1] $2"; }
print_ok()    { echo "OK - $1"; }
print_info()  { echo "INFO - $1"; }
print_error() { echo "ERRO - $1"; }

# Retorna a versão instalada atualmente (ex: "10.0.1") ou vazio se não instalado
get_installed_version() {
    if [ -f "$SPLUNK_HOME/bin/splunk" ]; then
        "$SPLUNK_HOME/bin/splunk" version --accept-license --no-prompt 2>/dev/null \
            | grep -oP 'Splunk Universal Forwarder \K[0-9]+\.[0-9]+\.[0-9]+'
    fi
}

# Compara versões: retorna 0 se iguais, 1 se arg1 > arg2, 2 se arg1 < arg2
compare_versions() {
    if [ "$1" = "$2" ]; then echo 0; return; fi
    local lower
    lower=$(printf '%s\n' "$1" "$2" | sort -V | head -1)
    if [ "$lower" = "$1" ]; then echo 2; else echo 1; fi
}

# Faz o download do instalador e garante as ferramentas
download_installer() {
    if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq && apt-get install -y -qq wget curl
    fi

    echo "Baixando de: $SPLUNK_URL"
    if ! wget -q -O "$INSTALLER_PATH" "$SPLUNK_URL"; then
        # Fallback para curl caso wget não esteja disponível
        if ! curl -sL -f -o "$INSTALLER_PATH" "$SPLUNK_URL"; then
            print_error "Falha no download. Verifique a conexão com a internet."
            exit 1
        fi
    fi
    print_ok "Download concluído."
}

# Para o serviço do Splunk com segurança
stop_splunk() {
    if "$SPLUNK_HOME/bin/splunk" status 2>/dev/null | grep -q "is running"; then
        "$SPLUNK_HOME/bin/splunk" stop --no-prompt 2>/dev/null
        sleep 2
    fi
    local pids
    pids=$(pgrep -x splunkd 2>/dev/null)
    if [ -n "$pids" ]; then
        kill -9 $pids 2>/dev/null
        sleep 1
    fi
}

# Cria usuário de sistema 'splunk' se não existir
ensure_splunk_os_user() {
    if ! id "splunk" &>/dev/null; then
        useradd -r -m -s /sbin/nologin splunk
        print_ok "Usuário 'splunk' criado."
    fi
}

# Cria o user-seed.conf com as credenciais
create_user_seed() {
    local seed_file="$SPLUNK_HOME/etc/system/local/user-seed.conf"
    if [ ! -f "$seed_file" ]; then
        mkdir -p "$(dirname "$seed_file")"
        cat <<EOF > "$seed_file"
[user_info]
USERNAME = $SPLUNK_USER_CONF
PASSWORD = $SPLUNK_PASSWORD
EOF
        chown splunk:splunk "$seed_file"
        chmod 600 "$seed_file"
        print_ok "Credenciais de administrador injetadas."
    fi
}

# Configura boot-start e deployment server
apply_final_config() {
    "$SPLUNK_HOME/bin/splunk" enable boot-start \
        -user splunk --accept-license --answer-yes --no-prompt 2>/dev/null

    "$SPLUNK_HOME/bin/splunk" set deploy-poll "$DEPLOY_SERVER:$DEPLOY_PORT" \
        -auth "$SPLUNK_USER_CONF:$SPLUNK_PASSWORD" 2>/dev/null

    print_ok "Configurações aplicadas (Boot-start e Deploy Server)."
}

# ==============================================================================
# INÍCIO DA EXECUÇÃO
# ==============================================================================
# Verificação de privilégios
if [[ $EUID -ne 0 ]]; then
    print_error "Este script deve ser executado como root."
    exit 1
fi

INSTALLED_VERSION=$(get_installed_version)

if [ -z "$INSTALLED_VERSION" ]; then
    echo "Status Atual: Splunk UF não detectado na máquina."
    MODE="install"
else
    echo "Versão Instalada: $INSTALLED_VERSION | Versão Alvo: $LATEST_VERSION"
    CMP=$(compare_versions "$INSTALLED_VERSION" "$LATEST_VERSION")
    if [ "$CMP" = "0" ]; then
        echo "Status Atual: Atualizado. Nenhuma Installation necessária."
        MODE="running"
    else
        echo "Status Atual: Desatualizado. Atualização será iniciada."
        MODE="update"
    fi
fi

# ==============================================================================
# MODO: APENAS GARANTIR QUE ESTÁ RODANDO
# ==============================================================================
if [ "$MODE" = "running" ]; then
    if "$SPLUNK_HOME/bin/splunk" status 2>/dev/null | grep -q "is running"; then
        print_ok "Serviço Splunkd está rodando adequadamente."
    else
        echo "Serviço parado. Reiniciando via systemctl ou comando direto..."
        systemctl restart SplunkForwarder 2>/dev/null || \
        su - splunk -s /bin/bash -c "$SPLUNK_HOME/bin/splunk start --no-prompt" 2>/dev/null || \
        "$SPLUNK_HOME/bin/splunk" start --no-prompt
        print_ok "Serviço Splunkd iniciado."
    fi
    exit 0
fi

# ==============================================================================
# MODO: INSTALAÇÃO NOVA OU ATUALIZAÇÃO
# ==============================================================================
if [ "$MODE" = "install" ] || [ "$MODE" = "update" ]; then
    print_step "1" "Baixando binários..."
    download_installer

    if [ "$MODE" = "update" ]; then
        print_step "2" "Parando serviço antigo..."
        stop_splunk
        
        print_step "3" "Extraindo nova versão por cima..."
        tar -xzf "$INSTALLER_PATH" -C /opt --keep-old-files 2>/dev/null || tar -xzf "$INSTALLER_PATH" -C /opt || { print_error "Falha na extração."; exit 1; }
    else
        print_step "2" "Instalando..."
        mkdir -p /opt
        tar -xzf "$INSTALLER_PATH" -C /opt || { print_error "Falha na extração."; exit 1; }
    fi

    ensure_splunk_os_user
    chown -R splunk:splunk "$SPLUNK_HOME"

    if [ "$MODE" = "install" ]; then
        print_step "4" "Semeando credenciais admin..."
        create_user_seed
    fi

    print_step "5" "Subindo o serviço e aceitando licença..."
    su - splunk -s /bin/bash -c "$SPLUNK_HOME/bin/splunk start --accept-license --answer-yes --no-prompt" 2>/dev/null || \
    "$SPLUNK_HOME/bin/splunk" start --accept-license --answer-yes --no-prompt

    print_step "6" "Registrando init-script e Deploy Server..."
    apply_final_config
    
    # Limpeza
    rm -f "$INSTALLER_PATH"
fi

# Verificação Final
NEW_VERSION=$(get_installed_version)
if "$SPLUNK_HOME/bin/splunk" status 2>/dev/null | grep -q "is running"; then
    echo "SUCESSO: Splunk UF $NEW_VERSION operando perfeitamente."
    "$SPLUNK_HOME/bin/splunk" display deploy-poll 2>/dev/null
    exit 0
else
    print_error "Splunk não iniciou corretamente após as operações."
    exit 1
fi


