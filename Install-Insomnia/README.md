# Script Documentation: Instalar Insomnia

## 1. Overview
Script projetado para implantar rapidamente o cliente de API (Insomnia) nos ambientes de desenvolvimento, aproveitando o empacotamento universal do ecossistema Snapcraft.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Insomnia.sh`

### 2.1. Execution Logic (Idempotency)
- **Detection:** Diferente de pacotes Debian, pacotes Snap não respondem ao `dpkg`. Sendo assim, a detecção verifica o cache ativo do isolamento snap via `snap list insomnia`.
- **Pré-requisito do Daemon:** Garante a presença do pacote de infraestrutura `snapd` via `apt-get` se não estiver presente na máquina.
- **Implementation:** Aciona silenciosamente a linha de comando `snap install insomnia`.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Insomnia.sh` in the Configuration settings section.

