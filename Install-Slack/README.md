# Script Documentation: Instalar Slack

## 1. Overview
**Script Avançado.** A Installation do Slack no Linux enfrenta constantes problemas devido às falhas da arquitetura Electron e às novas restrições de sandbox de distribuições recentes (como o Ubuntu 24.04). Este script de MDM resolve esses problemas fazendo o download da build em formato RPM, convertendo dinamicamente para o ecossistema Debian local, e corrigindo buracos de segurança cruciais.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Slack.sh`

### 2.1. Execution Logic e Autocorreção
- **Health Check Nativo:** Em vez de confiar no DPKG, o script verifica no Kernel se o app quebra: encontra o path, e roda um `slack --version`. Sendo o Intune executado como Root, o script engata `--no-sandbox` para não colapsar o teste. Se falhar, o script assume que a Installation corrompeu e reinstala por cima.
- **Manipulação Cruzada de Pacotes (Alien):** Para manter um único arquivo universal corporativo (RPM) funcional tanto no Ubuntu quanto no Fedora, o script extrai pacotes como `alien`, `libatomic1` e `libasound2` e executa um transpilador em tempo real (`alien --to-deb`), construindo um arquivo compatível com o APT da máquina.

### 2.2. Fixes Críticos (Electron Sandboxing & AppArmor)
- Após implantar, o script entra nas vísceras do aplicativo (`/usr/lib/slack/chrome-sandbox`) e reconcede manualmente o Bit SUID (permissão `4755`) e o ownership do arquivo ao `root`. **Sem isso, o Slack simplesmente recusa-se a abrir no desktop do usuário Linux.**
- **Ubuntu 24.04+ (Noble Numbat):** O script detecta kernels modernos que bloqueiam isolamentos (User Namespaces) e fabrica uma regra vitalícia em `/etc/apparmor.d/slack`, isentando o slack de bloqueios locais através da tag `flags=(unconfined)`, permitindo que o aplicativo respire e inicie normalmente.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file script in the Configuration settings section.

