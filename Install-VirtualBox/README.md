# Script Documentation: Instalar Oracle VirtualBox

## 1. Overview
Installation segura e otimizada da máquina virtual VirtualBox na versão corporativa 7.1. O script integra a plataforma utilizando o repositório nativo da Oracle e ajusta os grupos de segurança locais.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Oracle VirtualBox.sh`

### 2.1. Execution Logic e Correção de Kernel
- **Detection:** Query no dpkg visando exclusivamente o pacote core `virtualbox-7.1`.
- **Compilação Dinâmica (DKMS):** O VirtualBox exige que módulos de rede e ponte (como o `vboxdrv`) sejam compilados no núcleo do Linux. O script previne falhas graves instalando preventivamente as bibliotecas `dkms` e extraindo o cabeçalho exato do kernel em execução via `linux-headers-$(uname -r)`.
- **Autenticação:** Processa a chave GPG da Oracle (versão 2016) para dentro do diretório `/usr/share/keyrings/oracle-virtualbox-2016.gpg` e injeta a fonte APT detectando o CodeName da distro via `lsb_release -cs`.
- **Fix de USBs:** No Intune, o usuário não é sudo. Sendo assim, o script itera sob `/home/*` adicionando todas as credenciais locais ao grupo restrito `vboxusers`. Isso é obrigatório para que os desenvolvedores consigam conectar Pen drives e dispositivos ao VirtualBox (USB Passthrough).

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Oracle VirtualBox.sh` in the Configuration settings section.

