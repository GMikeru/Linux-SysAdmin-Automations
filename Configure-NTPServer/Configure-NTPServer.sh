#!/bin/bash
###############################################################################
# Script: intune-chrony-ntp-fix.sh
# Descrição: Script de compliance para Microsoft Intune (Linux Ubuntu 26 LTS)
#            - Valida se o Chrony NTP está instalado e ativo
#            - Se encontrar "gps.ntp.br" na configuração, altera para "pool.ntp.br"
#            - Registra todas as ações em log para auditoria
#
# Uso no Intune: Devices > Linux > Configuration scripts
#   - Run as: Root
#   - Execution frequency: conforme política (1x por semana)
#
# Data: 2026-07-28
###############################################################################

set -euo pipefail

# ========================== CONFIGURAÇÕES ====================================
LOG_FILE="/var/log/intune-chrony-ntp-fix.log"
CHRONY_CONF="/etc/chrony/chrony.conf"
CHRONY_CONF_DIR="/etc/chrony/conf.d"
OLD_NTP="gps.ntp.br"
NEW_NTP="pool.ntp.br"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"
# =============================================================================

# ========================== FUNÇÕES ==========================================
log() {
    local LEVEL="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$LEVEL] $*" | tee -a "$LOG_FILE"
}

exit_ok() {
    log "INFO" "Resultado: COMPLIANT"
    exit 0
}

exit_fail() {
    log "ERROR" "Resultado: NON-COMPLIANT — $1"
    exit 1
}
# =============================================================================

log "INFO" "========== Início da verificação Chrony NTP =========="
log "INFO" "Hostname: $(hostname)"
log "INFO" "OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"

# ---------- 1. VERIFICAR SE O CHRONY ESTÁ INSTALADO --------------------------
if ! command -v chronyd &>/dev/null; then
    log "WARN" "Chrony não encontrado. Tentando instalar..."

    # apt-get update pode falhar por repos de terceiros (ex: Microsoft GPG expirada)
    # Chrony está no repo main do Ubuntu, então ignoramos erros de update
    apt-get update -qq 2>&1 | tee -a "$LOG_FILE" || log "WARN" "apt-get update teve erros (repos de terceiros) — continuando mesmo assim..."

    if apt-get install -y -qq chrony 2>&1 | tee -a "$LOG_FILE"; then
        # Confirmar que realmente instalou
        if dpkg -s chrony &>/dev/null; then
            log "INFO" "Chrony instalado com sucesso."
        else
            exit_fail "Falha ao instalar o Chrony (dpkg não confirma Installation)."
        fi
    else
        exit_fail "Falha ao instalar o Chrony (apt-get install retornou erro)."
    fi
fi

CHRONY_VERSION=$(chronyd --version 2>/dev/null | head -1)
log "INFO" "Chrony detectado: $CHRONY_VERSION"

# ---------- 2. VERIFICAR SE O SERVIÇO ESTÁ ATIVO -----------------------------
if ! systemctl is-enabled chrony &>/dev/null; then
    log "WARN" "Serviço chrony não está habilitado. Habilitando..."
    systemctl enable chrony
    log "INFO" "Serviço chrony habilitado."
fi

if ! systemctl is-active chrony &>/dev/null; then
    log "WARN" "Serviço chrony não está rodando. Iniciando..."
    systemctl start chrony
    log "INFO" "Serviço chrony iniciado."
fi

# ---------- 3. VERIFICAR E CORRIGIR CONFIGURAÇÃO NTP --------------------------
CHANGES_MADE=0

# 3a. Substituir gps.ntp.br → pool.ntp.br no arquivo principal
if [ -f "$CHRONY_CONF" ]; then
    if grep -qi "$OLD_NTP" "$CHRONY_CONF"; then
        log "WARN" "Encontrado '$OLD_NTP' em $CHRONY_CONF — corrigindo para '$NEW_NTP'..."

        # Backup antes de alterar
        cp "$CHRONY_CONF" "${CHRONY_CONF}${BACKUP_SUFFIX}"
        log "INFO" "Backup criado: ${CHRONY_CONF}${BACKUP_SUFFIX}"

        # Substituir todas as ocorrências (server, pool, peer)
        sed -i "s|${OLD_NTP}|${NEW_NTP}|gi" "$CHRONY_CONF"
        log "INFO" "Substituição concluída em $CHRONY_CONF"
        CHANGES_MADE=1
    else
        log "INFO" "'$OLD_NTP' NÃO encontrado em $CHRONY_CONF — OK."
    fi
else
    log "WARN" "Arquivo $CHRONY_CONF não encontrado!"
fi

# 3b. Verificar arquivos em /etc/chrony/conf.d/ (drop-in configs)
if [ -d "$CHRONY_CONF_DIR" ]; then
    for CONF_FILE in "$CHRONY_CONF_DIR"/*.conf; do
        [ -f "$CONF_FILE" ] || continue
        if grep -qi "$OLD_NTP" "$CONF_FILE"; then
            log "WARN" "Encontrado '$OLD_NTP' em $CONF_FILE — corrigindo..."

            cp "$CONF_FILE" "${CONF_FILE}${BACKUP_SUFFIX}"
            log "INFO" "Backup criado: ${CONF_FILE}${BACKUP_SUFFIX}"

            sed -i "s|${OLD_NTP}|${NEW_NTP}|gi" "$CONF_FILE"
            log "INFO" "Substituição concluída em $CONF_FILE"
            CHANGES_MADE=1
        fi
    done
fi

# 3c. Verificar /etc/chrony/sources.d/ (Ubuntu 24.04+)
CHRONY_SOURCES_DIR="/etc/chrony/sources.d"
if [ -d "$CHRONY_SOURCES_DIR" ]; then
    for SRC_FILE in "$CHRONY_SOURCES_DIR"/*.sources; do
        [ -f "$SRC_FILE" ] || continue
        if grep -qi "$OLD_NTP" "$SRC_FILE"; then
            log "WARN" "Encontrado '$OLD_NTP' em $SRC_FILE — corrigindo..."

            cp "$SRC_FILE" "${SRC_FILE}${BACKUP_SUFFIX}"
            log "INFO" "Backup criado: ${SRC_FILE}${BACKUP_SUFFIX}"

            sed -i "s|${OLD_NTP}|${NEW_NTP}|gi" "$SRC_FILE"
            log "INFO" "Substituição concluída em $SRC_FILE"
            CHANGES_MADE=1
        fi
    done
fi

# 3d. GARANTIR QUE pool.ntp.br SEJA A FONTE PRINCIPAL
#     - Comentar pools padrão do Ubuntu (ntp.ubuntu.com, ubuntu.pool.ntp.org)
#     - Adicionar pool.ntp.br com diretiva 'prefer' no topo
if [ -f "$CHRONY_CONF" ]; then
    # Backup se ainda não foi feito nesta execução
    if [ "$CHANGES_MADE" -eq 0 ]; then
        cp "$CHRONY_CONF" "${CHRONY_CONF}${BACKUP_SUFFIX}"
        log "INFO" "Backup criado: ${CHRONY_CONF}${BACKUP_SUFFIX}"
    fi

    # Comentar pools padrão do Ubuntu (se ainda não estão comentados)
    if grep -qE '^pool\s+(ntp\.ubuntu\.com|[0-9]+\.ubuntu\.pool\.ntp\.org)' "$CHRONY_CONF"; then
        sed -i 's|^pool\s\+ntp\.ubuntu\.com|# &|' "$CHRONY_CONF"
        sed -i 's|^pool\s\+[0-9]\+\.ubuntu\.pool\.ntp\.org|# &|' "$CHRONY_CONF"
        log "INFO" "Pools padrão do Ubuntu comentados (ntp.ubuntu.com, ubuntu.pool.ntp.org)"
        CHANGES_MADE=1
    fi

    # Verificar se pool.ntp.br já existe com 'prefer'
    if grep -qi "^pool\s\+${NEW_NTP}.*prefer" "$CHRONY_CONF"; then
        log "INFO" "'$NEW_NTP' já configurado como fonte principal (prefer) — OK."
    else
        # Remover entradas antigas de pool.ntp.br sem 'prefer' (evitar duplicatas)
        sed -i "/^pool\s\+${NEW_NTP}/d" "$CHRONY_CONF"

        # Adicionar pool.ntp.br como PRIMEIRA entrada pool (após a linha 'confdir')
        # prefer = fonte preferida pelo chrony | maxsources 4 = até 4 servidores do pool
        if grep -q '^confdir' "$CHRONY_CONF"; then
            sed -i "/^confdir.*conf\.d/a\\
\\
# === NTP PRINCIPAL (solicitação do cliente) ===\\
pool ${NEW_NTP} iburst maxsources 4 prefer" "$CHRONY_CONF"
        else
            # Fallback: adicionar no início do arquivo
            sed -i "1i\\
# === NTP PRINCIPAL (solicitação do cliente) ===\\
pool ${NEW_NTP} iburst maxsources 4 prefer\\
" "$CHRONY_CONF"
        fi
        log "INFO" "'pool ${NEW_NTP} iburst maxsources 4 prefer' adicionado como fonte PRINCIPAL"
        CHANGES_MADE=1
    fi
fi

# ---------- 4. RESTART DO CHRONY SE HOUVE ALTERAÇÕES -------------------------
if [ "$CHANGES_MADE" -eq 1 ]; then
    log "INFO" "Reiniciando chrony para aplicar alterações..."
    systemctl restart chrony
    sleep 3

    if systemctl is-active chrony &>/dev/null; then
        log "INFO" "Chrony reiniciado com sucesso."
    else
        exit_fail "Chrony não reiniciou após alterações."
    fi
fi

# ---------- 5. VALIDAÇÃO FINAL -----------------------------------------------
# Verificar se o novo NTP está sendo usado
log "INFO" "--- Fontes NTP ativas ---"
chronyc sources 2>/dev/null | tee -a "$LOG_FILE" || true

# Verificar se gps.ntp.br NÃO aparece mais em nenhum arquivo de config (ativo)
REMAINING=$(grep -rlE "^(pool|server|peer)\s+.*${OLD_NTP}" /etc/chrony/ 2>/dev/null | grep -v ".bak." || true)
if [ -n "$REMAINING" ]; then
    exit_fail "Ainda existe '$OLD_NTP' ativo nos arquivos: $REMAINING"
fi

# Verificar se pool.ntp.br está configurado como preferido
if grep -qE "^pool\s+${NEW_NTP}.*prefer" "$CHRONY_CONF" 2>/dev/null; then
    log "INFO" "'$NEW_NTP' confirmado como fonte PRINCIPAL (prefer) no Chrony. ✓"
elif grep -rqi "$NEW_NTP" /etc/chrony/ 2>/dev/null; then
    log "WARN" "'$NEW_NTP' presente mas sem diretiva 'prefer' — funcional porém não prioritário."
else
    exit_fail "'$NEW_NTP' não encontrado na configuração do Chrony."
fi

# Exibir configuração final para auditoria
log "INFO" "--- Configuração final de $CHRONY_CONF ---"
cat "$CHRONY_CONF" | tee -a "$LOG_FILE"

log "INFO" "========== Verificação concluída =========="
exit_ok


