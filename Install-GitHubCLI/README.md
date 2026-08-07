# Script Documentation: Instalar GitHub CLI (gh)

## 1. Overview
Automatiza a configuração de chaveiro GPG e a Installation global da interface de linha de comando nativa da GitHub (`gh`) em ambientes Linux geridos.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar GitHub CLI.sh`

### 2.1. Execution Logic (Idempotency)
- **Detection:** Faz uso da Validation rígida via base nativa local (`dpkg-query -W`) procurando pelo binário nomeado exatamente como `gh`.
- **Implementação Segura:** Dispensa o `apt-key` (depreciado e reportado como inseguro em versões recentes do Ubuntu). Realiza o parse da chave do repositório da GitHub via cURL com falha silenciosa em caso de erro, armazenando a chave `.gpg` com as devidas permissões na pasta moderna e isolada (`/usr/share/keyrings`).
- **Configuração do APT:** Cria o pointer do source.list (`github-cli.list`) injetando dinamicamente a arquitetura encontrada através do comando `dpkg --print-architecture` (evitando falhas em processadores ARM vs x86) vinculando o repositório com o modo `signed-by`.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar GitHub CLI.sh` in the Configuration settings section.

