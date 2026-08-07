# Script Documentation: Instalar NVM e Node.js v24

## 1. Overview
Installation corporativa do Node Version Manager (NVM) e do Node.js versão 24. Diferente da Installation tradicional do NVM (que restringe a ferramenta apenas à home do usuário que rodou o comando), este script instala o ambiente de forma **global e colaborativa** para todos os usuários logados na máquina.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar NVM e Node 24.sh`

### 2.1. Execution Logic Global e Permissões Críticas
- **Detecção Estrutural:** Ele verifica se o arquivo master `nvm.sh` existe no diretório global `/usr/local/nvm`. Carrega as macros do shell ativas e roda um `nvm ls 24` para validar se o binário específico da versão 24 já foi implantado.
- **Redirecionamento Global:** O script bloqueia o download padrão para `~/.nvm` (que no MDM seria o `/root/`), alocando e criando um diretório comum `/usr/local/nvm`. O arquivo instalador cruza o pipe invocando o bash para instalar o core.
- **Profile Global (Auto-carregamento):** O script cria o arquivo `/etc/profile.d/nvm.sh`. Isso injeta automaticamente as variáveis de ambiente e o recurso de "auto-completar com TAB" para todos os usuários locais e redes do Azure AD sempre que qualquer janela de terminal bash é aberta.
- **Installation do Node e Modificação CHMOD:** Usando a interface interna instalada, dispara `nvm install 24` apontando-a como padrão do sistema operativo (`alias default`). A jogada vital de MDM está no final: `chmod -R a+rwx` abre a porta de leitura, escrita e deleção dessa pasta vital, garantindo que os desenvolvedores consigam invocar `nvm install 18` (por exemplo) sozinhos sem requerer que a TI os dê poderes superusuários de máquina (Visto que o NVM fatalmente cracha se executado usando `sudo`).

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar NVM e Node 24.sh` in the Configuration settings section.

