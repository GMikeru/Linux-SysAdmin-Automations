# Script Documentation: Instalar Zoom

## 1. Overview
Script para Installation do cliente Zoom a partir do seu repositório de download direto oficial (o Zoom não provê espelho APT).

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Zoom.sh`

### 2.1. Execution Logic e Resolução de Dependências
- **Detection:** Escaneia o inventário local do Linux buscando a versão em uso do pacote `zoom`.
- **Aquisição de Asset:** Faz o download do pacote estático `.deb` de Installation compilado a partir da url universal mais recente fornecida pelo próprio desenvolvedor (`https://zoom.us/client/latest/zoom_amd64.deb`).
- **Engenharia de Installation (APT Local):** Aplica uma técnica robusta forçando a extração via `apt-get install ./pacote.deb` em detrimento do obsoleto `dpkg -i`. Essa diferença é colossal, pois clientes corporativos como o Zoom dependem de extensões Qt, XCB e OpenGL complexas que causariam quebra imediata do comando se injetadas via DPKG, o APT auto-instala toda a árvore necessária em milissegundos evitando logs de falha no Intune.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file script in the Configuration settings section.

