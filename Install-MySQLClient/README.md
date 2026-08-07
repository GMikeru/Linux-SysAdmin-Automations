# Script Documentation: Instalar MySQL Client

## 1. Overview
Script enxuto para instalar especificamente o cliente de linha de comando relacional (`mysql`), ignorando a necessidade de levantar um servidor de banco de dados e economizando recursos computacionais no endpoint.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar MySQL Client.sh`

### 2.1. Execution Logic (Idempotency)
- **Detection:** Faz a busca direta na base instalada pelo pacote `mysql-client`.
- **Implementation:** Aproveitando que o repositório nativo do Ubuntu contém a dependência padrão, ele chama silenciosamente o update dos índices de APT e faz a Installation com o argumento não interativo duplo `-y -qq`.
- **Validation:** Ao finalizar a extração do binário, invoca nativamente um `mysql --version` capturando logs para o portal do Intune confirmando o sucesso na entrega.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar MySQL Client.sh` in the Configuration settings section.

