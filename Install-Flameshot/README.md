# Script Documentation: Instalar Flameshot

## 1. Overview
Script para instalar a ferramenta de captura e anotação de tela `Flameshot` diretamente dos repositórios nativos do Ubuntu de forma autônoma.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Flameshot.sh`

### 2.1. Execution Logic (Idempotency)
- **Detection:** O script roda uma query `dpkg-query -W -f='${Status}' flameshot` no sistema operacional para certificar-se de que a string `install ok installed` é retornada. Isso garante que a ferramenta não será baixada desnecessariamente em loops do Intune (Idempotente).
- **Installation:** Define a variável de ambiente `DEBIAN_FRONTEND=noninteractive` (evitando pausas por prompts interativos) e invoca `apt-get install -y -qq flameshot`.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Flameshot.sh` in the Configuration settings section.

