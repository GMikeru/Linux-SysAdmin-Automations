#!/bin/bash

# Configurações do Wallpaper
WALLPAPER_URL="https://scconfigmgrappdataCorporate.blob.core.windows.net/customization/LockScreen2025.jpg"
DEST_DIR="$HOME/.local/share/backgrounds"
DEST_FILE="${DEST_DIR}/LockScreen2025.jpg"

echo "Iniciando configuração do wallpaper para o usuário: $USER..."

# 1. Cria a pasta e faz o download do wallpaper, se não existir
if [ ! -d "$DEST_DIR" ]; then
    mkdir -p "$DEST_DIR"
fi

if [ ! -f "$DEST_FILE" ]; then
    echo "Baixando o wallpaper de $WALLPAPER_URL..."
    wget -q -O "$DEST_FILE" "$WALLPAPER_URL"
    if [ $? -ne 0 ]; then
        echo "Erro: Falha ao baixar o wallpaper."
        exit 1
    fi
    chmod 644 "$DEST_FILE"
else
    echo "O arquivo do wallpaper já existe em $DEST_FILE."
fi

EXPECTED_URI="file://$DEST_FILE"

# 2. Detecta se o wallpaper já está aplicado
CURRENT_URI=$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null | tr -d "'")

if [ "$CURRENT_URI" == "$EXPECTED_URI" ]; then
    echo "Sucesso: O wallpaper já está aplicado para o usuário $USER. Nenhuma alteração é necessária."
    exit 0
else
    echo "Wallpaper atual ($CURRENT_URI) é diferente do desejado. Aplicando..."
fi

# 3. Aplica o wallpaper (modo claro e escuro) e a tela de bloqueio
gsettings set org.gnome.desktop.background picture-uri "$EXPECTED_URI"
gsettings set org.gnome.desktop.background picture-uri-dark "$EXPECTED_URI"
gsettings set org.gnome.desktop.screensaver picture-uri "$EXPECTED_URI"

# 4. Validation final
NEW_URI=$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null | tr -d "'")

if [ "$NEW_URI" == "$EXPECTED_URI" ]; then
    echo "Sucesso: Wallpaper aplicado corretamente para o usuário $USER."
    exit 0
else
    echo "Erro: Falha ao aplicar o wallpaper."
    exit 1
fi


