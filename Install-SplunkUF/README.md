# Script Documentation: Instalar Splunk Universal Forwarder

## 1. Overview
**Script Avançado.** Este script é um agente mantenedor e instalador inteligente. Ele monitora a presença da ferramenta Universal Forwarder (Splunk), compara de forma semântica a versão rodando em background com a versão estipulada pela corporação, faz atualizações in-place e orquestra usuários de sistema invisíveis sem afetar as rotinas dos desenvolvedores.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Splunk.sh`

### 2.1. Execution Logic (Controle Cíclico)
- **Versionamento Dinâmico:** Extrai via regex a versão base no comando `splunk version` (Ex: `10.0.1`) e compara semanticamente (`sort -V`) contra a variável desejada no script (`10.2.2`). A máquina define sozinha se fará *Installation, Upgrade* ou apenas garantirá o *Health Check* da ferramenta rodando.
- **Preparação e Segurança de Sessão:** O Forwarder nunca pode rodar atrelado ao usuário Root ou ao desenvolvedor (para evitar escavação de logs). O script fabrica no ato o usuário virtual oculto (`useradd -r -s /sbin/nologin splunk`). As extrações do `tar.gz` para dentro do `/opt` são imediatamente repassadas ao ownership deste usuário fantasma (`chown -R`).
- **Autenticação Automática e Deployment:** Fabrica um arquivo mestre local `user-seed.conf` imputando credenciais fixas e em seguida obriga o instalador a aceitar todas as licenças EULAs e realizar login silencioso no painel remoto (IP corporativo `10.0.0.52`). Por fim, amarra o inicializador (boot-start) no Daemon SystemD para sempre carregar o agente quando o Linux for reiniciado.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file script in the Configuration settings section.
4. *Nota:* Sempre que houver necessidade de upgrade de parque, alterar as variáveis de URL e de Versionamento dentro deste script garantirá o deploy generalizado nas máquinas do Intune.

