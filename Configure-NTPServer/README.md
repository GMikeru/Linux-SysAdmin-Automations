# Script Documentation: NTP Server pool.ntp.br

## 1. Overview
**Script Avançado (Auditoria de Compliance).** Mais do que um instalador comum, esta é uma política robusta de saneamento. O script roda constantemente como forma de conformidade fiscal para garantir que todos os servidores e terminais da corporação apontem o relógio interno (NTP) estritamente para o pool do projeto de horários brasileiro, removendo apontamentos legados.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - NTP Server pool.ntp.br.sh`

### 2.1. Execution Logic Contínua
- **Auto-Configuração:** Varre a presença do Chrony NTP. Caso este processo não exista, resolve falhas de terceiros ignorando bloqueios silenciosamente e despacha `apt-get install chrony`, já validando a versão no dpkg. Confirma o estado do Systemctl e inicia o processo à força.
- **Auditoria de Parâmetros e Fallbacks:** Inspeciona recursivamente a configuração central (`/etc/chrony.conf`), e mais dois pontos vitais de subdiretórios `conf.d/` e `sources.d/`. Localizando qualquer apontamento para a fonte antiga e obsoleta (neste caso definido como `gps.ntp.br`), ele processa backups via `.bak` em cada arquivo alterado e força o rewrite para `pool.ntp.br`.
- **Exclusividade Topológica:** Não contente com a alteração, o script vai atrás das instâncias `ubuntu.pool` default de fábrica da Canonical, anulando-as via comentário `#`. E por fim, injeta uma tag especial informando que o nosso repositório é prioritário sob todos `(pool.ntp.br prefer)`.
- **Restart e Relatório Final:** O Daemon Chrony é recarregado. Todas as etapas emitem outputs detalhados para os logs gravados em `/var/log/intune-chrony-ntp-fix.log` de forma que a equipe técnica de TI possa extraí-los remotamente atestando a validade dos registros corporativos em caso de auditorias.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file script in the Configuration settings section.

