# Script Documentation: Instalar SentinelOne Agent (EDR)

## 1. Overview
Installation autônoma do agente SentinelOne (Endpoint Detection and Response), principal antivírus e software de segurança contra invasões e malwares adotado pela companhia.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar SentinelOne Agent (EDR).sh`

### 2.1. Execution Logic
- **Detecção Dupla:** Certifica-se de que o diretório `/opt/sentinelone` foi estruturado no disco e que o nome base do pacote `sentinelagent` consta ativo nos manifestos do dpkg.
- **Installation Local:** Faz o download direto do pacote `.deb` engessado na versão `v23_2_2_358` armazenado no Blob da Azure. Diferente de instalações APT nativas, ele invoca o utilitário de baixo nível `dpkg -i` aliado da tag `--force-all`, obrigando a escrita. Em seguida, aciona `apt-get install -f -y` para corrigir possíveis árvores de dependência fragmentadas.
- **Token de Gerenciamento e Acionamento:** Invoca a API do EDR (`sentinelctl`) passando a string de Token (Management Token) necessária para atrelar a máquina ao painel em Nuvem. Por fim, inicia o daemon local via `sentinelctl control start`.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar SentinelOne Agent (EDR).sh` in the Configuration settings section.

