# Script Documentation: Instalar Claude Code

## 1. Overview
Este script instala globalmente o **Claude Code** (ferramenta oficial da Anthropic) via Intune. Ele é uma adaptação robusta do script oficial para garantir que a CLI seja instalada silenciosamente de forma global, com validações de segurança severas (hashes).

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Claude Code.sh`

### 2.1. Execution Logic (Idempotência e Segurança)
- **Resolução de Platform:** Detecta arquitetura (x64 ou arm64) e bibliotecas C (glibc ou musl) dinamicamente.
- **Validation e Checksum (Zero Trust):** O script não baixa binários às cegas. Ele consulta o manifest JSON de releases em `downloads.claude.ai`, extrai a versão "latest", parseia o arquivo JSON (usando `jq` ou regex em fallback nativo) para resgatar o SHA-256 e recusa a Installation se a assinatura hash baixar não conferir perfeitamente com a criptografia da Anthropic.
- **Installation Global e Integração (Shell Integration):** Como o Intune roda scripts sob o usuário `root`, instalar ferramentas de linha de comando no perfil root tornaria o Claude Code inacessível. O script contorna isso baixando para `/usr/local/bin/claude` e criando um loop em `/home/*`. O script executa o comando nativo `claude install` (que injeta aliases e auto-complete) imitando (via `su - $user`) cada usuário do sistema, configurando perfeitamente a IDE no terminal do usuário final.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Claude Code.sh` in the Configuration settings section.

