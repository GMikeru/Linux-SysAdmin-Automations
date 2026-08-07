# Script Documentation: Instalar DbGate

## 1. Overview
Script de Installation simples focado na distribuição do cliente visual de bancos de dados open-source DbGate, fazendo uso da arquitetura universal Snap.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar DbGate.sh`

### 2.1. Execution Logic (Idempotency)
- **Detection:** Confirma via lista de snappacks se o `dbgate` encontra-se rodando no ambiente chamando `snap list dbgate`.
- **Prerequisites:** Garante que o motor daemon Snapd esteja presente na máquina (o que já é o padrão em servidores e desktops Ubuntu modernos, mas garante o fallback com apt install caso ausente).
- **Installation:** Invoca `snap install dbgate` para concluir a Installation conteinerizada.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar DbGate.sh` in the Configuration settings section.

