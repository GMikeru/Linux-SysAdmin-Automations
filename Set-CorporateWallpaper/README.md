# Script Documentation: Definir Wallpaper Corporate

## 1. Overview
Este script faz o download do Wallpaper oficial da Corporate e o aplica automaticamente na área de trabalho, tanto para o modo claro quanto para o escuro, incluindo a tela de bloqueio do sistema (Screensaver).

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile) - Específico para ambientes GNOME.
- **Language:** Bash
- **Source File:** `Linux - Definir Wallpaper Corporate.sh`
- **Asset/Payload:** Faz o download da imagem a partir de um Blob Storage no Azure (`scconfigmgrappdataCorporate.blob.core.windows.net`).

### 2.1. Execution Logic (Idempotency)
- **Manipulação Local:** A imagem é baixada para o diretório específico do usuário (`$HOME/.local/share/backgrounds/LockScreen2025.jpg`), criando a pasta se ela não existir. Se a imagem já estiver no disco local, o download não é repetido.
- **Detecção via Gsettings:** O script consulta as configurações do gerenciador de desktop do Linux (GNOME) usando o comando `gsettings get org.gnome.desktop.background picture-uri`. Ele compara a URL atual com o caminho local da imagem esperada; se forem iguais, o script encerra (Idempotente).
- **Implementation:** Utiliza os comandos `gsettings set` para gravar o wallpaper em três chaves distintas:
  - `picture-uri` (Fundo Padrão / Modo Claro)
  - `picture-uri-dark` (Fundo em Modo Escuro)
  - `org.gnome.desktop.screensaver picture-uri` (Fundo da Tela de Bloqueio)

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy**.
3. Selecione o Profile Type: **Templates > Custom**.
4. Upload the file `Linux - Definir Wallpaper Corporate.sh` in the Configuration settings section.

*Atenção:* Como o script atua modificando os `gsettings` e manipulando arquivos no `$HOME`, ele geralmente deve ser executado no contexto do usuário final (User context) em vez de System, para que atinja corretamente as chaves do dconf do usuário logado.

