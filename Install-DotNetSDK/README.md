# Script Documentation: Instalar .NET SDK

## 1. Overview
Este script gerencia a Installation autônoma do .NET SDK 10.0 via Intune. Sendo um pacote do SDK, ele automaticamente entrega as dependências de ambiente de runtime necessárias para os desenvolvedores executarem e construírem aplicações .NET.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar .NET SDK.sh`

### 2.1. Execution Logic (Idempotency)
- **Detecção Rígida via dpkg:** Em vez de depender do retorno de arquivos soltos, o script utiliza o gerenciador de pacotes da distribuição (`dpkg-query -W -f='${Status}'`) para verificar com precisão se o pacote base `dotnet-sdk-10.0` está no estado `install ok installed`. Caso positivo, ele retorna `0` mantendo a idempotência.
- **Installation Silenciosa:** O script força `DEBIAN_FRONTEND=noninteractive`, atualiza a árvore do APT e instala silenciosamente usando `apt-get install -y -qq`. 
- **Validation:** Finaliza a Installation invocando o binário via `dotnet --info` para confirmar que a variável de ambiente foi declarada corretamente e printar os dados no log de saída do Intune em caso de auditoria.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy**.
3. Selecione o Profile Type: **Templates > Custom**.
4. Upload the file `Linux - Instalar .NET SDK.sh` in the Configuration settings section.

