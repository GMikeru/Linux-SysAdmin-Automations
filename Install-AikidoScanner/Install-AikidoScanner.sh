#!/bin/bash
# ==============================================================================
# Script Intune para Installation e Proteção com Aikido Local Scanner
# ==============================================================================
# - Instala automaticamente dependências faltantes sem falhar o script (curl, unzip).
# - Resiliência em loop: Se um repositório git estiver corrompido, o script pula
#   e continua protegendo os demais, em vez de falhar toda a política do Intune.
# - Criação da pasta de hooks automática se ela não existir.

VERSION="v1.0.116"
BASE_URL="https://aikido-local-scanner.s3.eu-west-1.amazonaws.com/${VERSION}"
INSTALL_DIR="/usr/local/bin"
BINARY="aikido-local-scanner"

BIN_PATH="${INSTALL_DIR}/${BINARY}"
TMP_DIR=""
FOUND_REPOS=0
CHANGED_REPOS=0
SKIPPED_REPOS=0

export DEBIAN_FRONTEND=noninteractive

log_info() { echo "INFO - $1"; }
log_ok() { echo "OK - $1"; }
log_error() { echo "ERRO - $1"; }

cleanup() {
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}

fail() {
    log_error "$1"
    cleanup
    exit 1
}

trap cleanup EXIT

log_info "Iniciando auditoria do Aikido"

# Validation de privilégio (Intune já usa root, mas validamos por garantia)
if [ "$(id -u)" -ne 0 ]; then
    fail "Este script requer execucao como root"
fi

# Installation autônoma de dependências via Intune (evita abortar Installation)
apt-get update -qq
apt-get install -y -qq curl unzip

# Validation de comandos core
for cmd in uname find grep dirname chmod stat mv; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        fail "Dependencia de sistema ausente: $cmd"
    fi
done

# ==============================================================================
# 1. VALIDAÇÃO E INSTALAÇÃO DO BINÁRIO
# ==============================================================================
if [ ! -f "$BIN_PATH" ]; then
    log_info "Binario nao encontrado. Instalando..."

    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64|amd64) PLATFORM="linux_X86_64" ;;
        aarch64|arm64) PLATFORM="linux_ARM64" ;;
        *) fail "Arquitetura nao suportada: $ARCH" ;;
    esac

    URL="${BASE_URL}/${PLATFORM}/aikido-pre-commit-local-scanner.zip"
    TMP_DIR="$(mktemp -d)" || fail "Nao foi possivel criar diretorio temporario"

    curl -fsSL -o "$TMP_DIR/aikido.zip" "$URL" || fail "Falha no download do binario"
    unzip -qo "$TMP_DIR/aikido.zip" -d "$TMP_DIR" || fail "Falha ao extrair o pacote"

    if [ ! -f "$TMP_DIR/$BINARY" ]; then
        fail "Binario nao encontrado no pacote baixado"
    fi

    mv "$TMP_DIR/$BINARY" "$BIN_PATH" || fail "Falha ao mover binario para $BIN_PATH"
    chmod +x "$BIN_PATH" || fail "Falha ao aplicar permissao de execucao no binario"

    log_ok "Binario instalado com sucesso"
else
    log_ok "Binario ja presente"
fi

# ==============================================================================
# 2. AUDITORIA DOS REPOSITÓRIOS LOCAIS
# ==============================================================================
# Busca repositorios Git dentro da /home
repos=$(find /home -type d -name ".git" 2>/dev/null)

if [ -z "$repos" ]; then
    log_ok "Nenhum repositorio Git encontrado em /home. Auditoria finalizada."
    exit 0
fi

# O loop usa read para varrer cada pasta encontrada
while IFS= read -r repo; do
    [ -z "$repo" ] && continue

    FOUND_REPOS=$((FOUND_REPOS + 1))
    project="$(dirname "$repo")"
    hook="$project/.git/hooks/pre-commit"

    # Correção Intune 1: Criar a pasta hooks se não existir (alguns gits ficam vazios)
    if [ ! -d "$project/.git/hooks" ]; then
        mkdir -p "$project/.git/hooks"
    fi

    # Preservar o ownership do desenvolvedor real que criou a pasta, para ele não 
    # tomar "Permission Denied" ao rodar um git commit.
    user_owner="$(stat -c '%U' "$project" 2>/dev/null)"
    group_owner="$(stat -c '%G' "$project" 2>/dev/null)"

    if [ -z "$user_owner" ] || [ -z "$group_owner" ]; then
        # Correção Intune 2: Não usar 'fail' no loop, pois isso quebraria os outros projetos
        log_error "Nao foi possivel identificar owner do projeto: $project - Ignorando este."
        continue
    fi

    # Caso 1: Hook ja contem Aikido
    if [ -f "$hook" ] && grep -q "aikido-local-scanner pre-commit-scan" "$hook"; then
        log_info "Hook ja protegido em: $project"
        SKIPPED_REPOS=$((SKIPPED_REPOS + 1))
        continue
    fi

    # Caso 2: Hook inexistente ou alterado
    if [ ! -f "$hook" ]; then
        log_info "Hook ausente. Aplicando protecao em: $project"
    else
        log_info "Hook alterado/vazio. Forcando restauracao em: $project"
    fi

    # Escrevendo o arquivo de hook (sobrescrevendo forçadamente para segurança)
    cat <<'HOOK' > "$hook"
#!/bin/bash
/usr/local/bin/aikido-local-scanner pre-commit-scan .
HOOK

    chmod +x "$hook" || { log_error "Falha de permissao: $project"; continue; }
    chown "$user_owner":"$group_owner" "$hook" 2>/dev/null || { log_error "Falha de chown: $project"; continue; }

    CHANGED_REPOS=$((CHANGED_REPOS + 1))
    log_ok "Protecao aplicada com sucesso em: $project"

done <<< "$repos"

log_ok "Auditoria concluida!"
echo "Resumo -> Repos encontrados: $FOUND_REPOS | Corrigidos: $CHANGED_REPOS | Ja seguros: $SKIPPED_REPOS"
exit 0


