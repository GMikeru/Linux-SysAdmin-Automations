#!/bin/bash
# ==============================================================================
# Script de Installation do Antigravity CLI via Intune
# ==============================================================================
# O script original foi otimizado para não ser interativo e para garantir que a 
# Installation fique global para todos os usuários da máquina, em vez de ficar 
# escondida dentro da pasta /root (já que o Intune roda scripts como root).

set -euo pipefail

# Configuração de Execução Silenciosa
export DEBIAN_FRONTEND=noninteractive

# 1. Configurações base
DOWNLOAD_BASE_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app"
# Alterado de $HOME/.local/bin para um diretório global padrão do Linux
TARGET_DIR="/usr/local/bin"
BINARY_PATH="$TARGET_DIR/agy"

# 2. Detecção (Idempotência para o Intune)
if [ -f "$BINARY_PATH" ]; then
    echo "O Antigravity CLI já está instalado em $BINARY_PATH."
    exit 0
fi

echo "Iniciando a Installation do Antigravity CLI..."

# Garante a presença do curl ou wget para download
apt-get update -qq || true
apt-get install -y -qq curl wget

# 3. Detecção da Plataforma (Focado em Linux para Microsoft Intune)
arch="amd64"
case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *) echo "Fatal: Arquitetura $(uname -m) não suportada." >&2; exit 1 ;;
esac

# Detection musl (ex: Alpine), mas para Ubuntu padrão será linux_amd64
platform=""
if [ -f /lib/libc.musl-x86_64.so.1 ] || [ -f /lib/libc.musl-aarch64.so.1 ] || ldd /bin/ls 2>&1 | grep -q musl; then
    platform="linux_${arch}_musl"
else
    platform="linux_${arch}"
fi

echo "✓ Plataforma detectada: $platform"

# 4. Busca do Manifest JSON e Parser POSIX
echo "Consultando repositório de release..."
MANIFEST_URL="$DOWNLOAD_BASE_URL/manifests/$platform.json"
manifest_json=$(curl -fsSL "$MANIFEST_URL" 2>/dev/null || true)

if [ -z "$manifest_json" ]; then
    echo "Fatal: Não foi possível acessar o servidor para baixar o manifest." >&2
    exit 1
fi

parse_json_key() {
    local payload="$1"
    local key="$2"
    echo "$payload" | sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

version=$(parse_json_key "$manifest_json" "version")
url=$(parse_json_key "$manifest_json" "url")
sha512=$(parse_json_key "$manifest_json" "sha512")

if [ -z "$url" ] || [ -z "$sha512" ]; then
    echo "Fatal: Falha ao realizar parse do manifest." >&2
    exit 1
fi

echo "✓ Versão mais recente disponível: $version"

# 5. Download e Verificação de Checksum (SHA512)
STAGING_DIR="/tmp/antigravity_staging"
mkdir -p "$STAGING_DIR"

is_tar_gz=false
case "$url" in
    *.tar.gz*) is_tar_gz=true ;;
esac

if [ "$is_tar_gz" = true ]; then
    staging_payload="$STAGING_DIR/agy.tar.gz"
    extracted_binary="$STAGING_DIR/antigravity"
else
    staging_payload="$STAGING_DIR/agy"
    extracted_binary="$staging_payload"
fi

cleanup() {
    rm -rf "$STAGING_DIR" 2>/dev/null || true
}
trap cleanup EXIT

echo "Baixando pacote do CLI..."
curl -fsSL -o "$staging_payload" "$url"

actual_hash=$(sha512sum "$staging_payload" | cut -d' ' -f1 || true)
if [ "$actual_hash" != "$sha512" ]; then
    echo "ERRO DE SEGURANÇA: Checksum (SHA512) do arquivo baixado não confere com o manifest!" >&2
    exit 1
fi
echo "✓ Download concluído e integridade verificada."

# 6. Extração e Installation do Binário
if [ "$is_tar_gz" = true ]; then
    echo "Extraindo do arquivo compactado..."
    tar -xzf "$staging_payload" -C "$STAGING_DIR" antigravity 2>/dev/null || true
fi

mkdir -p "$TARGET_DIR"

if ! cp "$extracted_binary" "$BINARY_PATH" 2>/dev/null; then
    echo "Fatal: Erro ao tentar mover o executável para $BINARY_PATH" >&2
    exit 1
fi

chmod +x "$BINARY_PATH"

# 7. Configuração Nativa do Antigravity
echo "Acionando script interno de bootstrapper da CLI..."
"$BINARY_PATH" install --dir "$TARGET_DIR" || true

echo "SUCESSO: Installation do Antigravity CLI concluída."
exit 0


