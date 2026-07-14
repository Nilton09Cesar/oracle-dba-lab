# 🛢️ Oracle DB Monitor

Script de monitoramento proativo para bancos de dados **Oracle**, escrito em **Python** com a biblioteca `oracledb` (modo Thin). Ele verifica consistência do banco, uso de tablespaces (com suporte a AUTOEXTEND) e sessões bloqueadas — tudo automatizado via **cron**, com log colorido, histórico em **CSV** e pronto para virar dashboard no Excel/Power BI.

![Python](https://img.shields.io/badge/Python-3.9-blue?logo=python)
![Oracle](https://img.shields.io/badge/Oracle-Database-red?logo=oracle)
![Status](https://img.shields.io/badge/status-em%20produção-brightgreen)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

---

## 📌 Sobre o projeto

Este projeto nasceu da necessidade de **detectar problemas de espaço e disponibilidade antes que virem incidentes**. Em vez de depender de checagens manuais ou ferramentas pagas, o script roda de forma agendada e:

- ✅ Verifica se o banco está `OPEN`/`READ WRITE` e se todos os datafiles estão `ONLINE`
- ✅ Calcula o uso de cada tablespace em dois cenários: espaço já alocado e espaço máximo possível (considerando `AUTOEXTEND`/`MAXBYTES`)
- ✅ Detecta sessões bloqueadas (problemas de concorrência)
- ✅ Gera alertas coloridos no terminal e logs limpos em arquivo
- ✅ Mantém um histórico contínuo em CSV, pronto para análise em Excel/Power BI

---

## ⚙️ Funcionalidades

| Módulo | Descrição |
|---|---|
| `check_db_consistency()` | Valida modo de abertura do banco e status dos datafiles |
| `check_tablespace_usage()` | Calcula `% alocado` e `% do máximo` por tablespace, considerando AUTOEXTEND |
| `check_blocked_sessions()` | Conta sessões bloqueadas e alerta se ultrapassar o limite configurado |
| `write_csv_rows()` | Grava o histórico de uso em CSV (append automático, com cabeçalho na primeira execução) |
| `ColorFormatter` | Formata os logs com cores ANSI no console (sem "sujar" o arquivo de log) |

### Thresholds configuráveis

```python
TABLESPACE_CRITICAL_PCT = 85.0   # % de uso alocado para disparar alerta crítico
BLOCKED_SESSIONS_ALERT = 2       # Nº de sessões bloqueadas para gerar warning
```

---

## 🖥️ Demonstração

**1. Criação do ambiente virtual Python**

O script roda isolado em uma `venv` dedicada, sem interferir no Python do sistema.

**2. Execução manual do monitoramento**

Log colorido direto no terminal — INFO em branco, WARNING em laranja, permitindo identificar riscos rapidamente:

- Consistência do banco validada (`READ WRITE`, `PRIMARY`)
- Datafiles todos ONLINE
- Alertas automáticos: tablespaces `SYSTEM` e `SYSAUX` próximas do limite de uso alocado (mas com folga graças ao AUTOEXTEND)
- Demais tablespaces com uso saudável
- CSV atualizado automaticamente a cada execução

**3. Estrutura de arquivos gerada**

```
db_monitor/
├── db_monitor.log          # Log acumulado de todas as execuções
├── monitor.py               # Script principal
├── tablespace_usage.csv     # Histórico de uso das tablespaces
├── ultima_execucao.sh       # Extrai apenas o bloco da última execução do log
└── venv/                    # Ambiente virtual Python
```

**4. Transferência do CSV para análise**

O histórico é levado via `scp` para uma máquina Windows, onde é importado no Excel/Power BI para montar dashboards de tendência de uso de disco.

**5. Extração da última execução do log**

Script auxiliar em Bash (`ultima_execucao.sh`) que localiza o **offset de bytes** da última execução usando `grep -abo`, evitando ler o log inteiro em memória — funciona bem mesmo em arquivos grandes.

> 📷 As imagens completas de cada etapa (execução, log colorido, CSV, SCP e importação no Excel) estão disponíveis na pasta `/screenshots` deste repositório.

---

## 🚀 Como usar

### Pré-requisitos

- Python 3.9+
- Acesso a um banco Oracle (local ou remoto) com um usuário de monitoramento
- Pacote `oracledb` (`pip install oracledb`)

### 1. Criar usuário de monitoramento no Oracle

```sql
CREATE USER C##MONITOR IDENTIFIED BY "SenhaSegura123#";

GRANT CREATE SESSION TO C##MONITOR;
GRANT SELECT ON V_$SESSION TO C##MONITOR;
GRANT SELECT ON V_$SYSSTAT TO C##MONITOR;
GRANT SELECT ON DBA_TABLESPACES TO C##MONITOR;
GRANT SELECT ON DBA_DATA_FILES TO C##MONITOR;
GRANT SELECT ON DBA_FREE_SPACE TO C##MONITOR;
GRANT SELECT ON V_$DATABASE TO C##MONITOR;
```

> ⚠️ Use privilégios mínimos necessários e, em produção, prefira Oracle Wallet ou variáveis de ambiente em vez de senha em texto plano no script.

### 2. Preparar o ambiente

```bash
mkdir -p ~/labs/db_monitor
cd ~/labs/db_monitor

python3.9 -m venv venv
source venv/bin/activate
pip install oracledb
```

### 3. Configurar a conexão

Edite as constantes no início de `monitor.py`:

```python
DB_USER = "C##MONITOR"
DB_PASS = "SenhaSegura123#"
DB_DSN = "localhost:1521/ORCL"
```

### 4. Executar manualmente

```bash
python monitor.py
```

### 5. Automatizar com cron (a cada 15 minutos)

```bash
crontab -e
```

```cron
*/15 * * * * /home/oracle/labs/db_monitor/venv/bin/python /home/oracle/labs/db_monitor/monitor.py >> /home/oracle/labs/db_monitor/cron_output.log 2>&1
```

### 6. Consultar apenas a última execução do log

```bash
chmod +x ultima_execucao.sh
./ultima_execucao.sh
```

---

## 📊 Estrutura do CSV gerado

| Campo | Descrição |
|---|---|
| `timestamp` | Data/hora da coleta |
| `tablespace_name` | Nome da tablespace |
| `total_mb` | Espaço total alocado (MB) |
| `used_mb` | Espaço usado (MB) |
| `free_mb` | Espaço livre (MB) |
| `pct_alocado` | % de uso sobre o espaço alocado |
| `max_mb` | Espaço máximo possível (considerando AUTOEXTEND) |
| `pct_maximo` | % de uso sobre o espaço máximo possível |
| `has_autoextend` | 1 se algum datafile tem autoextend, 0 caso contrário |
| `status` | `OK` ou `CRÍTICO` |

Esse CSV pode ser importado diretamente em Excel, Power BI ou qualquer ferramenta de BI para acompanhar a tendência de crescimento das tablespaces ao longo do tempo.

---

## 🛠️ Tecnologias utilizadas

- **Python 3.9** + [`oracledb`](https://oracle.github.io/python-oracledb/) (modo Thin)
- **Oracle Database** (views `v$session`, `v$database`, `dba_data_files`, `dba_free_space`)
- **Bash** (script de extração de log por offset de bytes)
- **Cron** (agendamento)
- **CSV** + **Excel/Power BI** (visualização do histórico)

---

## 📈 Próximos passos (roadmap)

- [ ] Enviar alertas por e-mail/Slack quando status = `CRÍTICO`
- [ ] Migrar credenciais para Oracle Wallet
- [ ] Dashboard automatizado em Power BI conectado direto ao CSV
- [ ] Empacotar como serviço systemd como alternativa ao cron

---

## 📄 Licença

Este projeto está sob a licença MIT — sinta-se livre para usar, adaptar e contribuir.

---

## 👤 Autor

Feito com ☕ e algumas queries `dba_free_space` para manter bancos Oracle saudáveis.

Se este projeto te ajudou, deixe uma ⭐ no repositório!
