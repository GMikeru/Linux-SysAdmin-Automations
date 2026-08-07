# Script Documentation: Instalar RMM Agent

## 1. Overview
Script projetado para instalar o agente de RMM (Remote Monitoring and Management) responsável por reportar inventário e métricas da máquina aos painéis corporativos.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar RMM Agent.sh`

### 2.1. Execution Logic (Idempotência Baseada em Arquivo)
- **Detecção (Marker File):** O script depende de uma evidência estática para garantir idempotência. Ele procura o arquivo de log `/var/log/rmm_agent_installed.log`. Se o arquivo existir, significa que o Intune já rodou a configuração com sucesso anteriormente.
- **Implementation:** Utiliza o binário `wget` extraindo o arquivo instalador final (`install_agent.sh`) hospedado no Azure Blob Storage da Corporate para a pasta `/tmp/`.
- **Execução e Gravação de Status:** Aplica a permissão de execução via `chmod +x` e roda o agent script. Caso a rotina termine de forma saudável (`$? -eq 0`), o script atual gera o marker file e adiciona o carimbo de data da Installation (`date`), servindo de prova para execuções futuras.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar RMM Agent.sh` in the Configuration settings section.

