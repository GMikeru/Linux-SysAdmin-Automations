# Script Documentation: Instalar AWS VPN

## 1. Overview
Este script instala o cliente oficial da AWS VPN (AWS Client VPN) para Linux, garantindo a configuração correta do repositório oficial da AWS e suas chaves criptográficas (GPG).

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar AWS VPN.sh`

### 2.1. Execution Logic (Idempotency)
- **Detection:** Consulta o gerenciador de pacotes (`dpkg-query`) procurando pelo status `install ok installed` do pacote `awsvpnclient`. Se encontrado, encerra a execução sem alterar o sistema (Idempotente).
- **Adição de Repositório:** Instala os pré-requisitos (`apt-transport-https`, `gpg`, `wget`), faz o download da chave pública da AWS para `/etc/apt/trusted.gpg.d/` e adiciona a URL oficial do repositório no arquivo `/etc/apt/sources.list.d/aws-vpn-client.list`.
- **Installation:** Atualiza o cache do APT e instala o software silenciosamente.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar AWS VPN.sh` in the Configuration settings section.

