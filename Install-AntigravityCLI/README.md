# Script Documentation: Instalar Antigravity CLI

## 1. Overview
Script projetado para baixar, verificar a integridade (via SHA512) e instalar de forma global e autônoma a ferramenta de linha de comando corporativa "Antigravity CLI" (`agy`).

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Antigravity CLI.sh`

### 2.1. Execution Logic (Idempotência e Segurança)
- **Detection:** Verifica se o binário já existe em `/usr/local/bin/agy`. Se sim, a Installation é considerada concluída (Idempotente).
- **Detecção de Ambiente Dinâmica:** O script identifica se o kernel está rodando em `amd64` ou `arm64`, e também checa se a `libc` do sistema é padrão (`glibc`) ou `musl` (comum em distros como Alpine).
- **Segurança (Checksum):** Em vez de baixar um binário cego, o script faz um *parse POSIX* manual (via `sed`) em um arquivo `manifest.json` para extrair a URL de download e o hash SHA512 esperado. Após o download, um `sha512sum` é rodado para validar se o arquivo não foi adulterado.
- **Bootstrapper:** Após mover o executável, o script aciona a própria CLI para auto-finalizar a configuração chamando `agy install --dir /usr/local/bin`.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Antigravity CLI.sh` in the Configuration settings section.

