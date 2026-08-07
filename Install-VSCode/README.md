# Script Documentation: Instalar Visual Studio Code

## 1. Overview
Installation padrão do editor corporativo Visual Studio Code via repositório APT oficial da Microsoft, provendo acesso dinâmico a atualizações do software.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Visual Studio Code (VsCode).sh`

### 2.1. Execution Logic (Idempotency)
- **Detection:** Realiza verificação rápida buscando o status do pacote base `code` no banco do dpkg.
- **Implementação Segura:** Dispensa comandos instáveis, formatando e convertendo a chave GPG via script nativo para o formato moderno de Keyring do Ubuntu (`packages.microsoft.gpg`). Registra o source list, e despacha a ordem silenciosa de `apt-get install code`.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file script in the Configuration settings section.

