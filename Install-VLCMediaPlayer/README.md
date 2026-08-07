# Script Documentation: Instalar VLC Media Player

## 1. Overview
Script de baixa complexidade utilizado para padronizar o tocador de multimídias universal `vlc` em endpoints corporativos Linux.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar VLC Media Player.sh`

### 2.1. Execution Logic
- **Detection:** Valida se a ferramenta já conta como `install ok installed` via `dpkg-query`.
- **Installation Direta:** Utilizando o espelho oficial e nativo da distro Ubuntu (uma vez que não há demanda corporativa crítica para repositórios externos do VLC), sincroniza o índice local e instala o pacote `vlc`.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file script in the Configuration settings section.

