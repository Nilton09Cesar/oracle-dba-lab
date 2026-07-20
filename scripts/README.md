# Monitoramento de Tablespaces Oracle com Python

Um script prático e visual para monitoramento de Tablespaces no Oracle Database, com alertas coloridos e boas práticas de DBA.

## 🎯 Objetivo

Criar um health check leve e automatizável para monitorar o uso de tablespaces, facilitando a identificação rápida de espaços críticos.

### Funcionalidades
- Exibição colorida (🟢 Amarelo 🔴 Vermelho) diretamente no terminal
- Cálculo preciso de uso em MB e percentual
- Alertas automáticos quando uso > 85%
- Uso de usuário dedicado de monitoramento (melhor prática de segurança)



## 🚀 Como Usar

### 1. Criar o usuário de monitoramento (no PDB)

```
ALTER SESSION SET CONTAINER=orclpdb;

CREATE USER APP_MONITOR IDENTIFIED BY "sua_senha";

GRANT CREATE SESSION TO APP_MONITOR;

GRANT CREATE SESSION, SELECT_CATALOG_ROLE TO APP_MONITOR;
```
--- 

### 2. Configurar e executar os scripts

# Criar diretório (se ainda não existir)
```
mkdir -p /monitor_tbs/scripts

chown -R oracle:oinstall /monitor_tbs/scripts

chmod -R 775 /monitor_tbs/scripts
```
---

# Executar os scripts
```
$ cd /monitor_tbs/scripts/

$ vim test_connection.py

$ python3.9 scripts/test_connection.py
```


### Testando Conexão 
```

$ python3.9 /monitor_tbs/scripts/test_connection.py

$ cd /monitor_tbs/scripts/

$ vim check_tablespace.py

$ python3.9 scripts/check_tablespace.py
```
---

### Executar
```
$ python3.9 /monitor_tbs/scripts/check_tablespace.py

```
----

# 🔧 Melhorias Futuras (Roadmap)

#### Envio automático de alertas por e-mail ou Telegram

#### Geração de relatório HTML/PDF

#### Monitoramento de TEMP, UNDO e ASM

#### Agendamento via cron + systemd

#### Integração com Prometheus + Grafana

----

# 🛠️ Tecnologias Utilizadas

### Python 3.9+

### oracledb (driver oficial da Oracle)

### Oracle Database 19c (Multitenant - CDB/PDB)

### Linux (Oracle Linux)

### Shell Scripting

---

# 👨‍💻 Sobre o Autor
## Nilton Cesar

### Este projeto faz parte do meu portfólio prático, onde estou construindo habilidades reais em:
### Automação de tarefas DBA
### Monitoramento e performance
## Boas práticas de administração Oracle








