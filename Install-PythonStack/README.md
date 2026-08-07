# Script Documentation: Instalar Python3, Pip e Venv

## 1. Overview
Equipa as workstations Linux com as versões base da linguagem Python 3, acopladas com o gerenciador de pacotes universal (Pip) e a biblioteca de sub-ambientes virtuais isolados (Venv).

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar Python3, Pip e Venv.sh`

### 2.1. Execution Logic (Idempotência Tripla)
- **Detection:** Como o ecossistema é quebrado em três módulos fundamentais no Debian/Ubuntu, a proteção de idempotência utiliza uma expressão condicional (AND - `&&`) para averiguar no dpkg se `python3`, `python3-pip` e `python3-venv` constam instalados simultaneamente (com espaço em branco ao final do nome para prevenir falsos positivos com extensões).
- **Installation Estruturada:** O ambiente APT exporta a flag `DEBIAN_FRONTEND=noninteractive` mitigando travamentos e roda a extração linear das três entidades via repósitórios nativos (estáveis).

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar Python3, Pip e Venv.sh` in the Configuration settings section.

