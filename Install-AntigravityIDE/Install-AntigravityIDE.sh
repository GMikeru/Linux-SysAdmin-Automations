#!/bin/bash
# Script para instalar o Antigravity IDE via Intune (formato .tar.gz)

DOWNLOAD_URL="https://scconfigmgrappdataCorporate.blob.core.windows.net/customization/Antigravity%20IDE.dmg"

INSTALL_DIR="/opt/antigravity-ide"

# 1. Detecção (Idempotência)
if [ -d "$INSTALL_DIR" ] && [ -x "$INSTALL_DIR/antigravity-ide" ] 2>/dev/null; then
    echo "O Antigravity IDE já está instalado."
    exit 0
fi

echo "Iniciando a Installation do Antigravity IDE..."

# 2. Pré-requisitos
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl tar libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0 libsecret-1-0 libgbm1

# 3. Download do Binário
ARCHIVE_PATH="/tmp/antigravity_ide.tar.gz"
echo "Baixando o pacote do repositório corporativo..."

if ! curl -fsSL -o "$ARCHIVE_PATH" "$DOWNLOAD_URL"; then
    echo "ERRO: Falha ao baixar o arquivo."
    rm -f "$ARCHIVE_PATH"
    exit 1
fi

# 4. Extração
echo "Extraindo os arquivos..."
mkdir -p /opt/antigravity-tmp
if ! tar -xzf "$ARCHIVE_PATH" -C /opt/antigravity-tmp 2>/dev/null; then
    # Se tar.gz falhar, tenta extrair como zip (caso o blob contenha outro formato)
    apt-get install -y -qq unzip
    if ! unzip -qo "$ARCHIVE_PATH" -d /opt/antigravity-tmp; then
        echo "ERRO: Falha na extração do pacote. Verifique o formato do ficheiro."
        rm -rf /opt/antigravity-tmp "$ARCHIVE_PATH"
        exit 1
    fi
fi

# 5. Posicionando os Arquivos em /opt
# Descobre a sub-pasta extraída (se existir)
EXTRACTED_FOLDER=$(find /opt/antigravity-tmp -maxdepth 1 -mindepth 1 -type d | head -n 1)

if [ -z "$EXTRACTED_FOLDER" ]; then
    # Se não houver subpasta, os arquivos foram extraídos direto na raiz do tmp
    EXTRACTED_FOLDER="/opt/antigravity-tmp"
fi

rm -rf "$INSTALL_DIR"
mv "$EXTRACTED_FOLDER" "$INSTALL_DIR"

# Se sobrou a pasta temporária (porque os arquivos estavam numa subpasta), limpamos
rm -rf /opt/antigravity-tmp

# 6. Ajustar permissões para que QUALQUER utilizador consiga executar
# --- Propriedade: root (apenas root pode alterar), mas todos podem ler e executar ---
chown -R root:root "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"

# --- CORREÇÃO CRÍTICA: chrome-sandbox do Electron ---
# Aplicações Electron (como o Antigravity IDE) utilizam um processo de sandbox
# que EXIGE o bit SUID (setuid) no binário chrome-sandbox.
# Sem isto, a aplicação falha silenciosamente ao abrir para utilizadores não-root.
SANDBOX_BIN=$(find "$INSTALL_DIR" -name "chrome-sandbox" -type f 2>/dev/null | head -n 1)
if [ -n "$SANDBOX_BIN" ]; then
    chown root:root "$SANDBOX_BIN"
    chmod 4755 "$SANDBOX_BIN"
    echo "Permissão SUID aplicada ao chrome-sandbox."
fi

# --- Garantir que o executável principal tem permissão de execução para todos ---
EXEC_PATH=$(find "$INSTALL_DIR" -maxdepth 1 -type f -name "antigravity*" -o -name "Antigravity*" | head -n 1)

# Fallback: procurar qualquer executável ELF na raiz
if [ -z "$EXEC_PATH" ]; then
    EXEC_PATH=$(find "$INSTALL_DIR" -maxdepth 1 -type f -executable | while read -r f; do
        file "$f" 2>/dev/null | grep -q "ELF" && echo "$f" && break
    done)
fi

if [ -n "$EXEC_PATH" ]; then
    chmod 755 "$EXEC_PATH"
    echo "Executável principal identificado: $EXEC_PATH"
else
    echo "AVISO: Não foi possível identificar o executável principal automaticamente."
fi

# 7. Criar Symlink global no terminal
if [ -n "$EXEC_PATH" ]; then
    ln -sf "$EXEC_PATH" /usr/local/bin/antigravity-ide
    echo "Symlink criado em /usr/local/bin/antigravity-ide"
fi

# 8. Criar Ícone no Menu de Aplicativos (.desktop) para todos os utilizadores
DESKTOP_FILE="/usr/share/applications/antigravity-ide.desktop"

# Verifica se existe um ícone disponível dentro da pasta da aplicação
ICON_PATH=$(find "$INSTALL_DIR" -maxdepth 3 \( -name "icon.png" -o -name "*.png" \) -type f | head -n 1)
if [ -z "$ICON_PATH" ]; then
    ICON_PATH="utilities-terminal" # Ícone genérico caso não encontre
fi

# Garante que o Exec aponta para o executável correto (ou symlink)
EXEC_DESKTOP="${EXEC_PATH:-/usr/local/bin/antigravity-ide}"

cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=Antigravity IDE
Comment=Antigravity IDE - Agentic Coding
Exec=$EXEC_DESKTOP --no-sandbox %U
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=antigravity-ide
EOF

chmod 644 "$DESKTOP_FILE"

# 9. Atualizar base de dados do desktop (para o ícone aparecer imediatamente)
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database /usr/share/applications/ 2>/dev/null
fi

# 10. Limpeza do download
rm -f "$ARCHIVE_PATH"

# 11. Validation
if [ -d "$INSTALL_DIR" ] && [ -n "$EXEC_PATH" ]; then
    echo "SUCESSO: Installation do Antigravity IDE concluída perfeitamente!"
    echo "Qualquer utilizador pode abrir pelo menu de aplicativos ou executando: antigravity-ide"
    exit 0
else
    echo "ERRO: Ocorreu uma falha na Installation do Antigravity IDE."
    exit 1
fi


