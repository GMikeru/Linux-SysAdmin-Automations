# Script Documentation: Instalar Terraform

## 1. Overview
Script projetado para instalar a ferramenta de Infraestrutura como Código (Terraform) via repositórios originais HashiCorp, habilitando a equipe de infra e desenvolvimento a ter uma CLI imune às vulnerabilidades defasadas das versões padrão do Ubuntu.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Terraform .sh`

### 2.1. Execution Logic (Idempotency)
- **Detection:** A existência da CLI é inspecionada puramente no PATH pela rotina `command -v terraform`.
- **Registro GPG (Zero Trust):** Substitui o comando perigoso do Debian legados, baixando a assinatura oficial de lançamentos da base e repassando pelo `gpg --dearmor` convertendo-a para os arquivos limpos criptografados aceitos pelas travas do Kernel Linux atual (`/usr/share/keyrings`). O source file gerado obriga todo pacote provindo deste domínio a combinar com a assinatura injetada.
- **Installation:** Baixa e implanta o software silenciosamente, extraindo no log de saída o `terraform version` para reportar metadados nas dashboards de sucesso do Intune.

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file script in the Configuration settings section.

