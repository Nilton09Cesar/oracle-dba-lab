#!/usr/bin/env python3.9
import oracledb

try:

    connection = oracledb.connect(
    user="APP_MONITOR",
    password="sua senha",
    host="Seu IP",
    port=1521,
    service_name="orclpdb.localdomain"
)

    print("Conectado com sucesso!")

    connection.close()

except Exception as e:
    print("Erro:", e)
