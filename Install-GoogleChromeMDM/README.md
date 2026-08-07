# Script Documentation: Instalar Google Chrome & Configurar Políticas (MDM)

## 1. Overview
Este é um **script crítico de MDM** que atua como substituto de GPOs. Além de instalar o Google Chrome Stable e a ferramenta Google Endpoint Verification, ele injeta automaticamente chaves no registro Linux (via JSONs) forçando restrições de navegação, Installation forçada de extensões corporativas, controle de logins (apenas contas `@Corporate.com.br`) e bloqueios rígidos (ex: Discord).

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Google Chrome e Google Endpoint Verification.sh`

### 2.1. Execution Logic e Idempotência Dupla
- **Detecção Dupla (Binários + Políticas):** O script não checa apenas os executáveis! Para sair e garantir a idempotência, ele cruza os dados, garantindo que `google-chrome-stable` E o `endpoint-verification` estão no dpkg E também confirma se ambos os arquivos de segurança JSONs da corporação existem simultaneamente nos diretórios vitais (`/etc/opt/chrome/policies`).

### 2.2. Fluxo de Repositórios e Chaves
- Aplica as chaves GPG independentes e registra duas bases diferentes: o repositório Debian oficial do Google Chrome e a base no Cloud de dependências GCP (onde reside o Endpoint Verification). Instala ambos via `apt-get install` simultâneo.

### 2.3. Controle e Injeção de Políticas Corporativas (Policies)
O script cria os diretórios estritos `forced/` e `managed/` em `/etc/opt/chrome/policies` e injeta dois arquivos em formato JSON:
1. **`Corporate_policy.json` (Forced):** Força agressivamente a Installation de extensões através do array `ExtensionInstallForcelist` puxando os metadados diretamente via URL do client de Updates do Google.
2. **`my_policy.json` (Managed):** Injeta os controles corporativos vitais:
   - Bloqueio de domínios via `URLBlocklist` (Proibindo redes como Discord).
   - Domínios permitidos em whitelist para bypass em `AllowedDomainsForApps` (Corporate, Linker, etc.).
   - Modifica a tela de inicialização via chaves `RestoreOnStartup` obrigando os usuários a caírem em `https://app.yourcompany.com`.
   - Limita severamente o sistema de sessão do Chrome (`RestrictSigninToPattern`), travando a ativação de sync de dados exclusivamente para identificadores atrelados à Regex `.*@Corporate\.com\.br`.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Google Chrome e Google Endpoint Verification.sh` in the Configuration settings section.
4. *Atenção:* O arquivo deve ser versionado após cada mudança nos JSONs corporativos, e caso uma URL nova de bloqueio seja adicionada, o nome da policy ou o Check na detecção deverá ser revalidado.

