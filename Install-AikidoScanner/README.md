# Script Documentation: Instalar Aikido Local Scanner

## 1. Overview
Este é um script de segurança avançada. Ele instala o binário do "Aikido Local Scanner" e realiza uma varredura (auditoria) em todos os repositórios Git de desenvolvedores presentes no diretório `/home`. Ele força a injeção de um *Git Hook* (`pre-commit`) em cada projeto para garantir que o código seja escaneado por vulnerabilidades antes de cada commit.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Aikido Local Scanner.sh`

### 2.1. Execution Logic (Idempotência e Resiliência)
- **Installation do Binário:** Baixa o arquivo do Amazon S3 de acordo com a arquitetura do processador (`x86_64` ou `arm64`) e extrai o executável para `/usr/local/bin/aikido-local-scanner`.
- **Auditoria de Hooks (Pre-commit):** 
  - O script varre o diretório `/home` atrás de pastas `.git`.
  - Verifica se o `pre-commit` hook já contém o gatilho do Aikido (garantindo idempotência no projeto).
  - Caso não exista (ou tenha sido alterado/burlado), o script recria e sobrescreve o hook forçando o escaner a rodar.
- **Resiliência Crítica:** O loop de auditoria é protegido contra quebras de permissão. Ele detecta quem é o usuário "dono" original daquele repositório (usando `stat`) e aplica um `chown` no hook gerado, garantindo que o desenvolvedor não tome erros de *Permission Denied* ao commitar. Se um repositório estiver inacessível/corrompido, o loop simplesmente "pula" para o próximo sem falhar o script todo (evitando que o Intune reporte erro geral na máquina).

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Aikido Local Scanner.sh` in the Configuration settings section.

