# Script Documentation: Instalar Microsoft Edge & Configurar Políticas (MDM)

## 1. Overview
Equivalente ao script do Chrome, este script de MDM implanta o Microsoft Edge (Stable) para Linux juntamente com o Google Endpoint Verification. Ele força injetar políticas JSON corporativas no Edge limitando os acessos e unificando o ecossistema de controle de segurança Zero Trust (acessos permitidos, extensões, bloqueios rígidos e contas exclusivas Corporate).

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Microsoft Edge e Google Endpoint Verification _ Configurar Politicas.sh`

### 2.1. Execution Logic (Idempotência Tripla)
- **Detection:** O Intune só considera a máquina 100% "Compliant" e pula o script caso três condições sejam verdadeiras: pacote `microsoft-edge-stable` e `endpoint-verification` no DPKG, E o arquivo físico do JSON da corporação estar presente em `/etc/opt/edge/policies/managed/endpoint_policy.json`.
- **Registro Híbrido:** Intercala GPGs de dois players (Microsoft e Google) no `/usr/share/keyrings/`.

### 2.2. Políticas Injetadas no Edge (Policies)
Uma vez gerado o JSON no diretório `/etc/opt/edge/policies/managed/`, o navegador Edge no Linux perde a permissão local e adota regras corporativas (sinalizado como "Gerenciado pela sua organização"):
- **Extensões Agressivas (`ExtensionInstallForcelist`):** Força o Endpoint Verification.
- **Whitelist Zero Trust (`AllowedDomainsForApps`):** Bloqueia logins fora de domínios restritos à corporação.
- **Blocklist (`URLBlocklist`):** Pune conexões a domínios como `discord.com`.
- **Bloqueio de Sessão Pessoal (`RestrictSigninToPattern`):** Qualquer tentativa de autenticação com um usuário pessoal (ex: `@outlook.com` ou `@gmail.com`) é sumariamente bloqueada no navegador, sendo obrigatório que combine com a Expressão Regular `.*@Corporate\.com\.br`.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Microsoft Edge e Google Endpoint Verification _ Configurar Politicas.sh`.

