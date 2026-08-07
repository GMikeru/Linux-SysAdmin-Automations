# Script Documentation: Instalar PostgreSQL Client

## 1. Overview
Script projetado para prover o utilitário de conexão `psql` aos desenvolvedores. Ele extrai estritamente o "client" da engine relacional para economizar I/O e armazenamento da máquina, evitando rodar instâncias locais completas do SGBD de forma acidental.

## 2. Technical Details
- **Platform:** Linux (Intune Custom Configuration Profile)
- **Language:** Bash
- **Source File:** `Linux - Instalar PostgreSQL Client.sh`

### 2.1. Execution Logic
- **Detecção (Idempotência):** Confere no log histórico do dpkg a presença do metapacote `postgresql-client`.
- **Implementation:** Sincroniza o indexador da Canonical com `-qq` (totalmente silenciado para evitar saturação dos logs da API Graph do Intune) e invoca `apt-get install -y -qq postgresql-client`. O resultado final é testado executando uma chamada de versão (`psql --version`).

## 3. How to Deploy via Intune
1. Go to **Devices > Linux > Configuration Profiles**.
2. Click on **Create > New Policy** (Profile Type: Custom).
3. Upload the file `Linux - Instalar PostgreSQL Client.sh` in the Configuration settings section.

