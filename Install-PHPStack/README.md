# Script Documentation: Instalar PHP (Stack)

## 1. Overview
Instala a base de desenvolvimento PHP extraindo os binários do Repositório PPA oficial de Ondřej Surý. Isso garante que a engenharia tenha acesso a subversões ativas do PHP (8.2, 8.3+) não disponíveis nos espelhos primários de estabilidade do Ubuntu.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar PHP.sh`

### 2.1. Execution Logic (Idempotência e Fallback)
- **Detection:** O Intune cessa operações (exit 0) se detectar o status `install ok installed` para o pacote base `php-cli`.
- **Injeção de Repositório (e Prevenção):** O script instala a suíte `software-properties-common` para habilitar manipulação de PPAs. Tenta engatar o repositório `ppa:ondrej/php`.
- **Fallback Automático:** Caso o PPA esteja offline ou a versão atual do Ubuntu ainda não seja suportada pelo mantenedor, o script possui uma proteção em shell que desarma (remove) os links quebrados do apt (`/etc/apt/sources.list.d/ondrej*`) e despacha a Installation via repositório normal do sistema para não falhar a política do MDM e deixar a máquina crua.
- **Ecossistema:** Instala em modo massivo `-qq` não apenas o core, mas as extensões fundamentais exigidas por frameworks (Laravel/Symfony): `php-mysql`, `php-zip`, `php-gd`, `php-mbstring`, `php-curl`, `php-xml` e `php-bcmath`.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar PHP.sh` in the Configuration settings section.

