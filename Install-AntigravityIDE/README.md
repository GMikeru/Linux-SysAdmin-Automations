# Script Documentation: Instalar Antigravity IDE

## 1. Overview
Script robusto para a implantação global (para todos os usuários) do ambiente de desenvolvimento "Antigravity IDE", extraindo o software empacotado para o diretório corporativo `/opt`.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Antigravity IDE.sh`

### 2.1. Execution Logic (Idempotência e Permissões Críticas)
- **Installation Estruturada:** Baixa o arquivo do Azure Blob Storage e garante as dezenas de dependências de interface gráfica (X11, NSS, GTK) instaladas via `apt-get`. O pacote é extraído para `/opt/antigravity-ide`.
- **Correção de Sandbox (SUID):** Aplicativos Electron no Linux exigem o acionamento do sandbox de segurança do Chromium (`chrome-sandbox`). Como a implantação é feita por Root, o script localiza especificamente este binário de segurança e aplica `chmod 4755` (bit SUID). Se isto não for feito, usuários comuns não conseguem abrir a IDE (ela encerra silenciosamente).
- **Integração Desktop:** Para que o usuário veja a IDE na gaveta de aplicativos nativa do Linux, o script escreve um arquivo de atalho Desktop Entry (`.desktop`) na pasta `/usr/share/applications` para registrar o software no GNOME/KDE e roda o comando `update-desktop-database` para recarregar o cache visual.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Antigravity IDE.sh` in the Configuration settings section.

