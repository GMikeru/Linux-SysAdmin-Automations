# Script Documentation: Instalar Git (via PPA Oficial)

## 1. Overview
Este script instala o Git via repositório PPA oficial. No Linux (Ubuntu), os pacotes da base padrão costumam ficar defasados, portanto adicionar o PPA oficial do Git Core garante que a equipe de engenharia tenha acesso as features, correções de segurança e comandos mais modernos.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Git.sh`

### 2.1. Execution Logic (Idempotency)
- **Detection:** A existência do Git é avaliada diretamente no banco de dados local do apt via `dpkg-query` buscando a string de estado `install ok installed`.
- **Registro do PPA:** O script instala silenciosamente a base requerida (`software-properties-common`), em seguida injeta o repositório externo do time oficial (`ppa:git-core/ppa`) no cache do sistema com a flag de auto-aceite `-y`. 
- **Installation e Validation:** Atualiza os indíces locais e dispara a Installation base autônoma com o parâmetro silencioso de nível dois (`-qq`).

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Git.sh` in the Configuration settings section.

