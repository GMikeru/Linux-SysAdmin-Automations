# Script Documentation: Instalar Docker (e grupo local)

## 1. Overview
Este é um dos scripts mais vitais para os desenvolvedores. Ele instala o Docker Engine Oficial (removendo versões snap/repo velhas que conflitam), e executa a tarefa crítica de vincular todos os usuários locais ao grupo Docker, permitindo a utilização de contêineres sem necessidade de elevar privilégios com o `sudo`.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Docker e colocar no grupo docker.sh`

### 2.1. Execution Logic (Idempotência e Segurança)
- **Detecção Dupla:** Além de validar o `docker-ce` no dpkg, ele só garante idempotência verdadeira verificando através de `getent group docker` se o grupo do Docker foi mapeado corretamente no sistema.
- **Limpeza de Conflitos:** Remove brutalmente versões problemáticas padrão (como `docker.io`, `docker-engine` ou Snaps conflitantes).
- **Repositório Oficial:** Assim como o DBeaver, adota a política moderna de Keyrings (GPG `dearmor`) para adicionar com segurança o repositório oficial da docker.com validando a code-name do sistema operacional dinamicamente (`lsb_release -cs`).
- **Installation Completa:** Além do motor, instala o novo padrão de ecossistema (`docker-compose-plugin` e `docker-buildx-plugin`).
- **Fix Crítico de Permissões (Usuários do Intune):** Como as máquinas ingressadas no Entra ID e geridas pelo Intune criam sessões de rede para os desenvolvedores que não rodam nativamente como root, o script varre o subdiretório `/home` inteiro e injeta todos os perfis identificados, de forma contínua, para o grupo secundário `docker` (utilizando o usermod append `-aG`). O serviço do daemon é reiniciado na sequência para validar as credenciais.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Docker e colocar no grupo docker.sh` in the Configuration settings section.

