
-- Criando os diretórios
mkdir -p ~/labs/db_monitor

cd ~/labs/db_monitor

-- Conecte como SYSDBA
sqlplus / as sysdba

-- Criar o usuário de monitoramento (Exemplo em um PDB ou CDB com prefixo C##)
CREATE USER C##MONITOR IDENTIFIED BY "SenhaSegura123#";

-- Atribuir privilégios específicos para leitura de views de performance e dicionário
GRANT CREATE SESSION TO C##MONITOR;
GRANT SELECT ON V_$SESSION TO C##MONITOR;
GRANT SELECT ON V_$SYSSTAT TO C##MONITOR;
GRANT SELECT ON DBA_TABLESPACES TO C##MONITOR;
GRANT SELECT ON DBA_DATA_FILES TO C##MONITOR;
GRANT SELECT ON DBA_FREE_SPACE TO C##MONITOR;
GRANT SELECT ON V_$DATABASE TO C##MONITOR;

--Criar e ativar o ambiente virtual (venv) usando o Python 3.9
python3.9 -m venv venv
source venv/bin/activate

vim monitor.py

#!/usr/bin/env python3
import os
import sys
import csv
import logging
from datetime import datetime
import oracledb


class ColorFormatter(logging.Formatter):
    """Formatter que aplica cores ANSI por nível de log, apenas no console."""

    # Códigos ANSI básicos
    GREY = "\x1b[38;20m"
    BLUE = "\x1b[34;20m"
    RED = "\x1b[31;20m"
    BOLD_RED = "\x1b[31;1m"
    RESET = "\x1b[0m"

    # Laranja não existe na paleta ANSI de 16 cores padrão.
    # Usamos o código estendido de 256 cores (256-color palette) para
    # obter um laranja de verdade — o "amarelo" \x1b[33m tende a
    # sair esverdeado/pálido em muitos terminais.
    ORANGE = "\x1b[38;5;208m"

    BASE_FORMAT = "%(asctime)s [%(levelname)s] %(message)s"

    # INFO não entra no dicionário: fica com a cor padrão do terminal.
    COLORS = {
        logging.DEBUG: GREY,
        logging.WARNING: ORANGE,
        logging.ERROR: RED,
        logging.CRITICAL: BOLD_RED,
    }

    def format(self, record):
        # Só aplica cor se a saída for um terminal interativo (evita "lixo"
        # ANSI quando a saída é redirecionada para arquivo, pipe, cron, etc.)
        if sys.stdout.isatty():
            color = self.COLORS.get(record.levelno, "")
            formatter = logging.Formatter(f"{color}{self.BASE_FORMAT}{self.RESET}")
        else:
            formatter = logging.Formatter(self.BASE_FORMAT)
        return formatter.format(record)


# Configuração de Logs
LOG_FILE = "/home/oracle/labs/db_monitor/db_monitor.log"

# Handler de arquivo: texto puro, sem códigos de cor (evita "lixo" ao abrir o log)
file_handler = logging.FileHandler(LOG_FILE)
file_handler.setFormatter(logging.Formatter('%(asctime)s [%(levelname)s] %(message)s'))

# Handler de console: colorido, só funciona bem em terminais que suportam ANSI
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setFormatter(ColorFormatter())

logging.basicConfig(
    level=logging.INFO,
    handlers=[file_handler, console_handler]
)

# Credenciais de conexão (Idealmente viriam de variáveis de ambiente ou Oracle Wallet)
DB_USER = "C##MONITOR"
DB_PASS = "SenhaSegura123#"
# Formato do DSN: host:porta/service_name (ajuste para o IP do seu lab e seu serviço)
DB_DSN = "localhost:1521/ORCL"

# Limites de Alerta (Thresholds)
TABLESPACE_CRITICAL_PCT = 85.0
BLOCKED_SESSIONS_ALERT = 2

# Arquivo CSV de histórico de uso de tablespaces
CSV_FILE = "/home/oracle/labs/db_monitor/tablespace_usage.csv"
CSV_FIELDS = [
    "timestamp",
    "tablespace_name",
    "total_mb",
    "used_mb",
    "free_mb",
    "pct_alocado",
    "max_mb",
    "pct_maximo",
    "has_autoextend",
    "status",
]


def write_csv_rows(rows):
    """Grava (append) as linhas coletadas no CSV_FILE.

    Escreve o cabeçalho automaticamente se o arquivo ainda não existir
    ou estiver vazio, e apenas concatena (append) nas execuções seguintes
    — assim o arquivo vira um histórico contínuo de coletas.
    """
    if not rows:
        return

    file_exists = os.path.isfile(CSV_FILE) and os.path.getsize(CSV_FILE) > 0

    try:
        with open(CSV_FILE, mode="a", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=CSV_FIELDS)
            if not file_exists:
                writer.writeheader()
            writer.writerows(rows)
        logging.info(f"📄 CSV atualizado: {CSV_FILE} ({len(rows)} linha(s) adicionada(s))")
    except OSError as e:
        logging.error(f"❌ Falha ao gravar CSV em {CSV_FILE}: {e}")


def check_tablespace_usage(connection):
    """Monitora o espaço em disco ocupado pelas Tablespaces.

    Calcula dois percentuais:
      - pct_alocado: uso em relação ao espaço já alocado hoje nos datafiles.
      - pct_maximo: uso em relação ao tamanho máximo possível, considerando
        AUTOEXTEND (MAXBYTES) quando ligado. Se nenhum datafile da tablespace
        tiver autoextend, os dois percentuais são iguais.

    Também acumula uma linha por tablespace para gravar no CSV_FILE ao final.
    """
    logging.info("--- Validando Espaço das Tablespaces ---")
    query = """
    SELECT
        df.tablespace_name,
        ROUND(df.total_mb, 2) AS total_mb,
        ROUND(df.max_mb, 2) AS max_mb,
        df.has_autoextend,
        ROUND(df.total_mb - NVL(fs.free_mb, 0), 2) AS used_mb,
        ROUND(NVL(fs.free_mb, 0), 2) AS free_mb,
        CASE
            WHEN NVL(df.total_mb, 0) = 0 THEN NULL
            ELSE ROUND((1 - (NVL(fs.free_mb, 0) / df.total_mb)) * 100, 2)
        END AS pct_alocado,
        CASE
            WHEN NVL(df.max_mb, 0) = 0 THEN NULL
            ELSE ROUND(((df.total_mb - NVL(fs.free_mb, 0)) / df.max_mb) * 100, 2)
        END AS pct_maximo
    FROM
        (SELECT
            tablespace_name,
            SUM(NVL(bytes, 0)) / 1024 / 1024 AS total_mb,
            SUM(CASE
                    WHEN autoextensible = 'YES' AND maxbytes > 0 THEN maxbytes
                    ELSE NVL(bytes, 0)
                END) / 1024 / 1024 AS max_mb,
            MAX(CASE WHEN autoextensible = 'YES' THEN 1 ELSE 0 END) AS has_autoextend
         FROM dba_data_files
         GROUP BY tablespace_name) df
    LEFT JOIN
        (SELECT tablespace_name, SUM(bytes) / 1024 / 1024 AS free_mb
         FROM dba_free_space GROUP BY tablespace_name) fs
    ON df.tablespace_name = fs.tablespace_name
    """
    csv_rows = []
    collected_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with connection.cursor() as cursor:
        cursor.execute(query)
        rows = cursor.fetchall()
        for row in rows:
            ts_name, total, max_mb, has_autoextend, used, free, pct_alocado, pct_maximo = row

            # Proteção: se não foi possível calcular o percentual (ex.: datafile
            # OFFLINE/indisponível fazendo total_mb ou pct virarem NULL), não
            # comparamos nada — apenas alertamos e seguimos para a próxima tablespace.
            if pct_alocado is None or total is None:
                logging.warning(
                    f"⚠️ Não foi possível calcular o uso da tablespace {ts_name} "
                    f"(possível datafile OFFLINE ou indisponível). Verifique manualmente."
                )
                continue

            autoextend_txt = "com autoextend" if has_autoextend else "sem autoextend"

            status = "OK"
            if pct_alocado >= TABLESPACE_CRITICAL_PCT:
                status = "CRÍTICO"
                if has_autoextend and pct_maximo is not None:
                    logging.warning(
                        f"🚨 ALERTA: Tablespace {ts_name} está com {pct_alocado}% do espaço "
                        f"alocado em uso (Limite: {TABLESPACE_CRITICAL_PCT}%), mas apenas "
                        f"{pct_maximo}% do máximo possível ({autoextend_txt}, até {max_mb}MB)."
                    )
                else:
                    logging.warning(
                        f"🚨 ALERTA: Tablespace {ts_name} está com {pct_alocado}% de uso "
                        f"(Limite: {TABLESPACE_CRITICAL_PCT}%) - {autoextend_txt}!"
                    )
            else:
                if has_autoextend and pct_maximo is not None and pct_maximo != pct_alocado:
                    logging.info(
                        f"✅ Tablespace {ts_name}: {pct_alocado}% do alocado em uso "
                        f"({used}MB / {total}MB) | {pct_maximo}% do máximo ({autoextend_txt}, "
                        f"até {max_mb}MB) - Status: {status}"
                    )
                else:
                    logging.info(
                        f"✅ Tablespace {ts_name}: {pct_alocado}% em uso ({used}MB / {total}MB) "
                        f"- {autoextend_txt} - Status: {status}"
                    )

            csv_rows.append({
                "timestamp": collected_at,
                "tablespace_name": ts_name,
                "total_mb": total,
                "used_mb": used,
                "free_mb": free,
                "pct_alocado": pct_alocado,
                "max_mb": max_mb,
                "pct_maximo": pct_maximo,
                "has_autoextend": 1 if has_autoextend else 0,
                "status": status,
            })

    write_csv_rows(csv_rows)


def check_blocked_sessions(connection):
    """Monitora sessões presas ou bloqueadas (Garantindo concorrência e consistência de performance)."""
    logging.info("--- Validando Concorrência e Bloqueios ---")
    query = """
    SELECT count(*)
    FROM v$session
    WHERE blocking_session IS NOT NULL
    """
    with connection.cursor() as cursor:
        cursor.execute(query)
        blocked_count = cursor.fetchone()[0]
        if blocked_count >= BLOCKED_SESSIONS_ALERT:
            logging.warning(f"⚠️ Atenção! Existem {blocked_count} sessões bloqueadas no momento.")
        else:
            logging.info(f"✅ Concorrência saudável: {blocked_count} sessões em estado de bloqueio.")


def check_db_consistency(connection):
    """Garante a consistência analisando o status do banco de dados e dos datafiles."""
    logging.info("--- Validando Consistência e Disponibilidade ---")

    # 1. Verificar status de abertura do banco
    with connection.cursor() as cursor:
        cursor.execute("SELECT name, open_mode, database_role FROM v$database")
        db_info = cursor.fetchone()
        logging.info(f"💾 Banco de Dados: {db_info[0]} | Modo: {db_info[1]} | Role: {db_info[2]}")

    # 2. Verificar se há Datafiles Offline ou que necessitam de Media Recovery
    query_files = """
    SELECT file_name, status, online_status
    FROM dba_data_files
    WHERE status != 'AVAILABLE' OR online_status NOT IN ('ONLINE', 'SYSTEM')
    """
    with connection.cursor() as cursor:
        cursor.execute(query_files)
        offline_files = cursor.fetchall()
        if offline_files:
            for f in offline_files:
                logging.error(f"❌ DATAFILE INCONSISTENTE ENCONTRADO: {f[0]} | Status: {f[1]} | Online: {f[2]}")
        else:
            logging.info("✅ Todos os Datafiles estão ONLINE e disponíveis.")


def main():
    logging.info("========================================")
    logging.info(f"Iniciando Execução do Monitoramento - {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}")
    logging.info("========================================")

    connection = None
    try:
        # Conexão no modo Thin (Não requer instalação do Instant Client no Python se conectado diretamente)
        connection = oracledb.connect(
            user=DB_USER,
            password=DB_PASS,
            dsn=DB_DSN
        )

        # Executar checagens
        check_db_consistency(connection)
        check_tablespace_usage(connection)
        check_blocked_sessions(connection)

    except Exception as e:
        logging.critical(f"Falha crítica de conexão ou execução no banco de dados: {e}")
    finally:
        if connection:
            connection.close()
            logging.info("Conexão com o banco encerrada.")

    logging.info("Monitoramento finalizado com sucesso.\n")


if __name__ == "__main__":
    main()
    
        
-- Checagem Manual 
python monitor.py



-- Passo 4: Automação com o Cron do Linux

    crontab -e

-- Adicione a linha abaixo para executar o script a cada 15 minutos (garantindo que ele carregue o ambiente do Python virtualizado):
   
    */15 * * * * /home/oracle/labs/db_monitor/venv/bin/python /home/oracle/labs/db_monitor/monitor.py >> /home/oracle/labs/db_monitor/cron_output.log 2>&1
    
    
-- Powershell
scp oracle@192.168.0.181:/home/oracle/labs/db_monitor/tablespace_usage.csv C:\Projeto_Monitoramento

-- Automatizando para pegar somente a última execução

$ vim ultima_execucao.sh

#!/bin/bash
#
# ultima_execucao.sh
# Extrai apenas o bloco da última execução de um log de monitoramento,
# usando busca por offset (rápido mesmo em arquivos grandes).
#
# Uso:
#   ./ultima_execucao.sh [caminho_do_log]
#
# Se nenhum caminho for passado, usa db_monitor.log no diretório atual.

set -euo pipefail

LOG_FILE="${1:-db_monitor.log}"
MARCADOR="Iniciando Execução do Monitoramento"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "Erro: arquivo '$LOG_FILE' não encontrado." >&2
    exit 1
fi

# Encontra o byte-offset de todas as ocorrências do marcador e pega a última
offset=$(grep -abo "$MARCADOR" "$LOG_FILE" | tail -1 | cut -d: -f1 || true)

if [[ -z "$offset" ]]; then
    echo "Aviso: marcador '$MARCADOR' não encontrado em '$LOG_FILE'." >&2
    echo "Exibindo as últimas 100 linhas como fallback:" >&2
    tail -n 100 "$LOG_FILE"
    exit 0
fi

# Volta um pouco antes do offset para capturar a linha de "====" que
# normalmente vem logo acima do marcador de início.
voltar=60
inicio=$(( offset > voltar ? offset - voltar : 0 ))

# Pula direto para o ponto de interesse sem ler o arquivo inteiro em memória,
# depois localiza a linha de "====" mais próxima para começar exatamente ali.
tail -c +"$((inicio + 1))" "$LOG_FILE" | awk -v marcador="====" '
    inicio_impressao == 0 && index($0, marcador) > 0 { inicio_impressao = 1 }
    inicio_impressao == 1 { print }
'

chmod +x ultima_execucao.sh

./ultima_execucao.sh


