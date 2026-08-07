# Script Documentation: Instalar DBeaver CE

## 1. Overview
Este script instala o DBeaver Community Edition a partir do seu repositório oficial, assegurando que o cliente de banco de dados continue recebendo patches de segurança e novas features automaticamente junto aos updates do sistema operacional.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar DBeaver CE.sh`

### 2.1. Execution Logic (Compatibilidade Ubuntu 22.04+)
- **Detection:** Verifica no dpkg se `dbeaver-ce` já está perfeitamente instalado (`install ok installed`).
- **GPG Keyrings:** Abandona o uso da ferramenta ultrapassada `apt-key add` (que causa alertas de segurança no Ubuntu a partir da versão 22.04). Em vez disso, baixa a chave oficial do repositório da DBeaver.io, passa pelo comando `gpg --dearmor` e a isola limpa e seguramente no diretório oficial `/usr/share/keyrings/dbeaver-archive-keyring.gpg`.
- **Implementação do Repositório:** A lista de sources é criada contendo a flag estrita `signed-by`, forçando o apt a aceitar apenas pacotes do DBeaver assinados por aquela chave em específico.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar DBeaver CE.sh` in the Configuration settings section.

