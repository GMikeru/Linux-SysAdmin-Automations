# Script Documentation: Instalar Chrome Remote Desktop

## 1. Overview
Script simples e direto para instalar e prover dependências do utilitário Chrome Remote Desktop do Google em endpoints Linux.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Chrome Remote Desktop.sh`

### 2.1. Execution Logic (Idempotency)
- **Detection:** Utiliza o gerenciador local de pacotes `dpkg -l` alinhado ao `grep` para confirmar a presença de `chrome-remote-desktop`. Se estiver instalado, a rotina é pulada.
- **Installation:** Faz o download direto do pacote `.deb` da URL oficial do Google (`dl.google.com`) para a pasta `/tmp` usando o utilitário `wget`, e invoca o instalador do sistema (`apt-get install`) para efetuar a configuração do pacote em modo autônomo.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Chrome Remote Desktop.sh` in the Configuration settings section.

