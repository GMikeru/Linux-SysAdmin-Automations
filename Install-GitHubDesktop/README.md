# Script Documentation: Instalar GitHub Desktop

## 1. Overview
Instala o fork comunitário Linux oficializado e mais estável da ferramenta GitHub Desktop (desenvolvido por `shiftkey`), visto que a GitHub não disponibiliza uma interface oficial do Desktop construída nativamente pela Microsoft para ecossistemas puros Linux.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar GitHub Desktop.sh`

### 2.1. Execution Logic (Idempotência e Resolução de Conflitos)
- **Detecção Inicial:** Utiliza query via banco de dependências DPKG validando se o nome base do pacote `github-desktop` consta como instalado e pronto.
- **Prevenção de Quebras de Repositórios:** O script intencionalmente roda um `rm -f /etc/apt/sources.list.d/shiftkey-packages.list` eliminando versões mortas do repositório antigo do `shiftkey` que costumavam causar logs de erro de Update (`404 Not Found`) ao aplicar updates corporativos do Ubuntu. 
- **Atualização de Mirror:** Migra o sistema forçadamente para o mirror estável seguro moderno (`mirror.mwt.me/shiftkey-desktop/deb/`), convertendo o GPG via pipe `--dearmor` para armazenamento assinado local.
- **Installation Autônoma:** Injeta e sincroniza a lista nova procedendo com o comando APT em backend não-interativo silencioso.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar GitHub Desktop.sh` in the Configuration settings section.

