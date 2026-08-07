# Script Documentation: Bloqueio de USB

## 1. Overview
Este script implementa uma restrição de segurança no nível de kernel do Linux, bloqueando a utilização de dispositivos de armazenamento USB (Pen drives e HDs externos).

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Bloqueio de USB.sh`

### 2.1. Execution Logic (Idempotency)
- **Detection:** O script utiliza o comando `grep` para verificar se os módulos `usb-storage` e `uas` já encontram-se bloqueados (via blacklist) no Configuration file `/etc/modprobe.d/disable-usb-storage.conf`. Se ambos já estiverem declarados, o script se encerra sem alterar nada.
- **Implementation:** O script insere as strings `blacklist usb-storage` e `blacklist uas` no arquivo, forçando o kernel Linux a não carregar os drivers de armazenamento em massa. Por fim, corrige as permissões do arquivo para `644`.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy**.
3. Selecione o Profile Type: **Templates > Custom**.
4. Upload the file `Linux - Bloqueio de USB.sh` in the Configuration settings section.
5. Em Atribuições (Assignments), direcione para o grupo de dispositivos ou usuários alvo (geralmente atribuído a todo o parque ou setores de alto risco).

