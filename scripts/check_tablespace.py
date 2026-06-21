#!/usr/bin/env python3.9
import oracledb

# Cores ANSI
RESET  = "\033[0m"
VERMELHO = "\033[1;31m"  # Vermelho negrito — crítico (> 85%)
AMARELO  = "\033[1;33m"  # Amarelo negrito — atenção  (> 70%)
VERDE    = "\033[1;32m"  # Verde negrito   — normal   (<= 70%)

connection = oracledb.connect(
    user="APP_MONITOR",
    password="sua senha",
    host="Seu IP",
    port=1521,
    service_name="orclpdb.localdomain"
)

cursor = connection.cursor()

query = """
SELECT
    df.tablespace_name,
    ROUND(df.total_mb,2) total_mb,
    ROUND(fs.free_mb,2) free_mb,
    ROUND((df.total_mb - fs.free_mb),2) used_mb,
    ROUND(((df.total_mb - fs.free_mb) / df.total_mb) * 100,2) used_pct
FROM
    (SELECT tablespace_name,
            SUM(bytes)/1024/1024 total_mb
     FROM dba_data_files
     GROUP BY tablespace_name) df,

    (SELECT tablespace_name,
            SUM(bytes)/1024/1024 free_mb
     FROM dba_free_space
     GROUP BY tablespace_name) fs

WHERE df.tablespace_name = fs.tablespace_name
ORDER BY used_pct DESC
"""

cursor.execute(query)

print("\n===== MONITORAMENTO TABLESPACE =====\n")

for row in cursor:

    tablespace = row[0]
    total      = row[1]
    free       = row[2]
    used       = row[3]
    pct        = row[4]

    # Define a cor de acordo com o percentual de uso
    if pct > 85:
        cor = VERMELHO
    elif pct > 70:
        cor = AMARELO
    else:
        cor = VERDE

    print(f"""{cor}
Tablespace : {tablespace}
Total MB   : {total}
Free MB    : {free}
Used MB    : {used}
Uso %      : {pct}
{RESET}""")

    if pct > 85:
        print(f"{VERMELHO}🔴 ALERTA: TABLESPACE ACIMA DE 85%!{RESET}\n")

cursor.close()
connection.close()

