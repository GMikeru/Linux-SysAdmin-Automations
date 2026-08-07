# Script Documentation: Instalar Composer

## 1. Overview
Script projetado para instalar o **Composer** (gerenciador de pacotes do PHP) de maneira global.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Composer.sh`

### 2.1. Execution Logic (Idempotency)
- **Detection:** Verifica nativamente a existência da ferramenta através do comando `command -v composer`. Se encontrar, garante a idempotência abortando a execução (exit 0).
- **Prerequisites:** Confere se o pacote `php-cli` está instalado (vital para o Composer rodar). Se ausente, invoca o gerenciador `apt-get` para resolver a dependência silenciosamente.
- **Verificação de Segurança:** Baixa o instalador do Composer e roda uma verificação rígida `hash_file('sha384')`. Se o hash não bater exatamente com a assinatura mantida pela equipe do Composer, a Installation é imediatamente cancelada para evitar envenenamento.
- **Installation Global:** Move o arquivo `.phar` construído para `/usr/local/bin/composer` e atribui permissões de execução.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Composer.sh` in the Configuration settings section.

