#!/bin/bash
# ==============================================================================
# Script de Installation do Claude Code via Intune
# ==============================================================================
# Adaptado do instalador oficial (https://docs.anthropic.com/en/docs/claude-code)
# para deployment silencioso via Microsoft Intune em máquinas Linux.
#
# Principais diferenças em relação ao script oficial:
#   - Installation global em /usr/local/bin (Intune roda como root)
#   - Verificação de idempotência (não reinstala se já existir)
#   - Shell integration configurada para TODOS os utilizadores em /home
#   - Mensagens em português e estilo consistente com os demais scripts Intune
==============================================================================

set -euo pipefail

# Configuração de Execução Silenciosa
export DEBIAN_FRONTEND=noninteractive

# --- Configurações ---
DOWNLOAD_BASE_URL="https://downloads.claude.ai/claude-code-releases"
TARGET_DIR="/usr/local/bin"
BINARY_NAME="claude"
BINARY_PATH="$TARGET_DIR/$BINARY_NAME"
STAGING_DIR="/tmp/claudecode_staging"

# 1. Detecção (Idempotência)
# Verifica se o binário do Claude Code já existe no path global
if [ -f "$BINARY_PATH" ]; then
    echo "O Claude Code já está instalado em $BINARY_PATH."
    echo "Versão: $($BINARY_PATH --version 2>/dev/null || echo 'desconhecida')"
    exit 0
fi

echo "Iniciando a Installation do Claude Code..."

# 2. Pré-requisitos
# Nota: usamos || true no update porque PPAs de terceiros podem estar partidos
# (ex: ppa:ondrej/php sem release para esta versão do Ubuntu).
# Os pacotes que precisamos vêm dos repos oficiais do Ubuntu.
apt-get update -qq 2>/dev/null || true
apt-get install -y -qq curl ca-certificates

# 3. Detecção da Plataforma
os="linux"

arch="x64"
case "$(uname -m)" in
    x86_64|amd64) arch="x64" ;;
    arm64|aarch64) arch="arm64" ;;
    *) echo "ERRO: Arquitetura $(uname -m) não suportada." >&2; exit 1 ;;
esac

# Verificação de musl (ex: Alpine) vs glibc (Ubuntu/Debian padrão)
if [ -f /lib/libc.musl-x86_64.so.1 ] || [ -f /lib/libc.musl-aarch64.so.1 ] || ldd /bin/ls 2>&1 | grep -q musl; then
    platform="linux-${arch}-musl"
else
    platform="linux-${arch}"
fi

echo "✓ Plataforma detectada: $platform"

# 4. Obter a versão mais recente
echo "Consultando versão mais recente do Claude Code..."
version=$(curl -fsSL "$DOWNLOAD_BASE_URL/latest" 2>/dev/null || true)

# Validar que o que retornou é mesmo um número de versão (e não uma página de erro)
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "ERRO: Não foi possível obter a versão do Claude Code." >&2
    echo "Verifique a conectividade com downloads.claude.ai e https://www.anthropic.com/supported-countries" >&2
    exit 1
fi

echo "✓ Versão mais recente disponível: $version"

# 5. Obter o manifest e extrair o checksum (SHA256)
echo "Baixando manifest de verificação..."
manifest_json=$(curl -fsSL "$DOWNLOAD_BASE_URL/$version/manifest.json" 2>/dev/null || true)

if [ -z "$manifest_json" ]; then
    echo "ERRO: Falha ao baixar o manifest de verificação." >&2
    exit 1
fi

# Extrair o checksum — tenta jq primeiro, fallback para bash puro
checksum=""
if command -v jq >/dev/null 2>&1; then
    checksum=$(echo "$manifest_json" | jq -r ".platforms[\"$platform\"].checksum // empty")
else
    # Parser POSIX: normaliza JSON e extrai com regex
    normalized=$(echo "$manifest_json" | tr -d '\n\r\t' | sed 's/ \+/ /g')
    if [[ $normalized =~ \"$platform\"[^}]*\"checksum\"[[:space:]]*:[[:space:]]*\"([a-f0-9]{64})\" ]]; then
        checksum="${BASH_REMATCH[1]}"
    fi
fi

if [ -z "$checksum" ] || [[ ! "$checksum" =~ ^[a-f0-9]{64}$ ]]; then
    echo "ERRO: Plataforma $platform não encontrada no manifest." >&2
    exit 1
fi

echo "✓ Checksum obtido para verificação de integridade."

# 6. Download do Binário
mkdir -p "$STAGING_DIR"

cleanup() {
    rm -rf "$STAGING_DIR" 2>/dev/null || true
}
trap cleanup EXIT

staging_binary="$STAGING_DIR/claude"

echo "Baixando binário do Claude Code ($version)..."
if ! curl -fsSL -o "$staging_binary" "$DOWNLOAD_BASE_URL/$version/$platform/claude"; then
    echo "ERRO: Falha no download do binário." >&2
    exit 1
fi

# 7. Verificação de Integridade (SHA256)
actual=$(sha256sum "$staging_binary" | cut -d' ' -f1)

if [ "$actual" != "$checksum" ]; then
    echo "ERRO DE SEGURANÇA: Checksum (SHA256) não confere!" >&2
    echo "  Esperado: $checksum" >&2
    echo "  Obtido:   $actual" >&2
    exit 1
fi

echo "✓ Download concluído e integridade verificada."

# 8. Installation Global do Binário
mkdir -p "$TARGET_DIR"
cp "$staging_binary" "$BINARY_PATH"
chmod +x "$BINARY_PATH"

echo "✓ Binário instalado em $BINARY_PATH"

# 9. Shell Integration para Todos os Utilizadores
# O comando 'claude install' configura a shell integration (autocompletar, aliases, etc.)
# no perfil do utilizador. Como o Intune roda como root, precisamos executar
# para cada utilizador existente em /home.
echo "Configurando shell integration para os utilizadores..."
for user_dir in /home/*; do
    if [ -d "$user_dir" ]; then
        username=$(basename "$user_dir")
        # Verifica se é um utilizador válido com shell
        if id "$username" >/dev/null 2>&1; then
            echo "  -> Configurando para o utilizador '$username'..."
            # Roda o 'claude install' como o utilizador para que os ficheiros
            # de configuração sejam criados com as permissões corretas
            su - "$username" -c "$BINARY_PATH install" 2>/dev/null || true
        fi
    fi
done

# 10. Validation Final
if [ -f "$BINARY_PATH" ] && "$BINARY_PATH" --version >/dev/null 2>&1; then
    installed_version=$("$BINARY_PATH" --version 2>/dev/null || echo "$version")
    echo ""
    echo "✅ SUCESSO: Installation do Claude Code ($installed_version) concluída!"
    echo "   Binário: $BINARY_PATH"
    echo ""
    exit 0
else
    echo "ERRO: Ocorreu uma falha na Installation do Claude Code." >&2
    exit 1
fi


