# Documentação do Script: Liberação de USB

## 1. Visão Geral
Script "irmão" do Bloqueador de USB. Este script desfaz restrições sistêmicas do Kernel, liberando acesso total a conexões mass storage (Pen Drives e Discos externos) imediatamente e sem a necessidade de reboots da máquina.

## 2. Detalhes Técnicos
- **Plataforma:** Linux (Intune Custom Configuration Profile)
- **Linguagem:** Bash
- **Arquivo de Origem:** `Linux - Liberação de USB.sh`

### 2.1. Lógica de Execução 
- **Detecção:** Inspeciona diretamente se o arquivo proibitivo (`/etc/modprobe.d/disable-usb-storage.conf`) responsável por bloquear o armazenamento foi criado. Caso o arquivo não exista, assume que a liberação já está ativa.
- **Implementação e Hot-Reload (Kernel):** Deleta definitivamente o arquivo blacklist via `rm -f`. A seguir, ele invoca comandos vivos (`modprobe`) para reinserir as diretivas `usb-storage` e `uas` dentro da árvore nativa do kernel em tempo de execução para que o SO volte a montar Pen Drives imediatamente sem travar os usuários aguardando reinicializações físicas.

## 3. How to Deploy via Intune
1. Acesse **Devices > Linux > Configuration Profiles**.
2. Clique em **Create > New Policy** (Profile Type: Custom).
3. Faça o upload do arquivo script na seção Configuration settings.

