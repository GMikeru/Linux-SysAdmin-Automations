# Script Documentation: Atualizar Sistema Operacional

## 1. Overview
Este script é responsável por validar e instalar de forma silenciosa e autônoma todas as atualizações pendentes do sistema operacional Ubuntu (pacotes e dependências de segurança). Ele foi projetado para rodar em background pelo Intune sem interrupções ou prompts ao usuário.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Atualizar Sistema Operacional.sh`

### 2.1. Execution Logic (Idempotency)
- **Detection:** O script simula um `apt-get upgrade` usando o comando `-s` e faz um parse para verificar a contagem de pacotes listados. Se a contagem for zero, o script sai com código `0` sem alterar nada no ambiente, garantindo idempotência.
- **Installation Silenciosa:** Caso haja atualizações, o script define `DEBIAN_FRONTEND=noninteractive` e repassa parâmetros rígidos para o Dpkg (`--force-confdef` e `--force-confold`), o que garante que arquivos de configuração locais existentes nunca sejam sobrescritos acidentalmente e não abram diálogos interativos (famosas telas rosa do debconf).
- **Dist-upgrade e Limpeza:** Além do upgrade padrão, o script roda `dist-upgrade` para cobrir mudanças críticas de kernel/dependências e finaliza com `autoremove` e `clean` para economizar disco.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy**.
3. Selecione o Profile Type: **Templates > Custom**.
4. Upload the file `Linux - Atualizar Sistema Operacional.sh` in the Configuration settings section.
5. Em Atribuições (Assignments), direcione para o grupo de dispositivos ou usuários desejado.

