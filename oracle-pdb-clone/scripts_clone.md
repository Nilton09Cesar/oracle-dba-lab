# Projeto: Clonagem de Pluggable Database (PDB) no Oracle Database 19c

## Objetivo

Este projeto demonstra o processo de clonagem de uma **Pluggable Database (PDB)** utilizando a arquitetura **Oracle Multitenant**.

Durante a execução são realizadas validações antes e após a clonagem, garantindo que o ambiente foi criado corretamente e que os datafiles do novo PDB são independentes do banco de origem.

---

## Tecnologias utilizadas

- Oracle Database 19c
- Oracle Multitenant (CDB/PDB)
- Oracle Managed Files (OMF)
- SQL*Plus
- Oracle Linux

---

## Pré-requisitos

- Banco Oracle instalado e funcionando
- Banco em arquitetura Multitenant (CDB/PDB)
- PDB de origem criada (`ORCLPDB`)
- `DB_CREATE_FILE_DEST` configurado
- Usuário com privilégios para criar PDB

---

# Script Completo

## 1. Verificar a versão do Oracle Database

```sql
SELECT banner_full
FROM v$version
WHERE ROWNUM = 1;
```

---

## 2. Confirmar o container atual

```sql
SHOW CON_NAME
```

Resultado esperado:

```
CDB$ROOT
```

---

## 3. Validar informações do banco

```sql
COL name FOR A15

SELECT name,
       cdb,
       open_mode,
       log_mode
FROM v$database;
```

Verificações importantes:

- Banco é CDB
- OPEN_MODE = READ WRITE
- LOG_MODE conforme ambiente

---

## 4. Listar todos os PDBs

```sql
COL name FOR A15
COL restricted FOR A15

SELECT con_id,
       name,
       open_mode,
       restricted
FROM v$pdbs
ORDER BY con_id;
```

---

## 5. Verificar Oracle Managed Files (OMF)

```sql
SHOW PARAMETER db_create_file_dest

SHOW PARAMETER db_recovery_file_dest
```

Como o parâmetro `DB_CREATE_FILE_DEST` está configurado, o Oracle criará automaticamente todos os datafiles do clone.

---

# Clonagem

## 6. Criar o novo PDB

```sql
CREATE PLUGGABLE DATABASE pdb_clone
FROM orclpdb;
```

---

## 7. Abrir o novo PDB

```sql
ALTER PLUGGABLE DATABASE pdb_clone OPEN;
```

---

## 8. Salvar o estado do PDB

```sql
ALTER PLUGGABLE DATABASE pdb_clone SAVE STATE;
```

Assim, após reinicializações do CDB, o PDB será aberto automaticamente.

---

# Validação

## 9. Comparar PDB original e clone

```sql
COL name FOR A10
COL open_mode FOR A15
COL restricted FOR A10

SELECT con_id,
       name,
       guid,
       open_mode,
       restricted,
       creation_time
FROM v$pdbs
WHERE name IN ('ORCLPDB','PDB_CLONE')
ORDER BY con_id;
```

---

## 10. Verificar os datafiles

```sql
COL con_name FOR A10
COL file_name FOR A60
COL status FOR A10

SELECT c.name AS con_name,
       d.file_id,
       d.file_name,
       ROUND(d.bytes/1024/1024) AS MB,
       d.status
FROM cdb_data_files d
JOIN v$containers c
ON c.con_id = d.con_id
WHERE c.name IN ('ORCLPDB','PDB_CLONE')
ORDER BY c.name,
         d.file_id;
```

---

## 11. Confirmar que não existem datafiles compartilhados

### Consulta 1

```sql
SELECT a.file_name
FROM cdb_data_files a
JOIN cdb_data_files b
ON a.file_name = b.file_name
AND a.con_id <> b.con_id
WHERE a.con_id IN
(
SELECT con_id
FROM v$containers
WHERE name='ORCLPDB'
)
AND b.con_id IN
(
SELECT con_id
FROM v$containers
WHERE name='PDB_CLONE'
);
```

Resultado esperado:

```
0 linhas retornadas
```

---

### Consulta alternativa

```sql
SELECT file_name,
       COUNT(DISTINCT con_id) AS qtd_pdbs
FROM cdb_data_files
WHERE con_id IN
(
SELECT con_id
FROM v$containers
WHERE name IN ('ORCLPDB','PDB_CLONE')
)
GROUP BY file_name
HAVING COUNT(DISTINCT con_id) > 1;
```

---

### Consulta otimizada

```sql
SELECT a.file_name
FROM cdb_data_files a
JOIN cdb_data_files b
ON a.file_name = b.file_name
WHERE a.con_id =
(
SELECT con_id
FROM v$containers
WHERE name='ORCLPDB'
)
AND b.con_id =
(
SELECT con_id
FROM v$containers
WHERE name='PDB_CLONE'
)
AND a.con_id <> b.con_id;
```

---

# Configuração do Oracle Net

## 12. Registrar o novo serviço no tnsnames.ora

```bash
cd $ORACLE_HOME/network/admin

vi tnsnames.ora
```

Adicionar:

```text
PDB_CLONE =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = dba-ol7)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = pdb_clone)
    )
  )
```

---

# Testes Funcionais

## 13. Consultar dados no PDB original

```sql
ALTER SESSION SET CONTAINER=orclpdb;

COL nome FOR A25
COL vaga FOR A30
COL status FOR A15

SELECT id_candidato,
       nome,
       vaga,
       status,
       SUBSTR(cpf,1,4)||'***.***'||SUBSTR(cpf,-3) AS cpf
FROM app_dados.candidatos;
```

---

## 14. Consultar os mesmos dados no PDB clonado

```sql
ALTER SESSION SET CONTAINER=pdb_clone;

COL nome FOR A25
COL vaga FOR A30
COL status FOR A15

SELECT id_candidato,
       nome,
       vaga,
       status,
       SUBSTR(cpf,1,4)||'***.***'||SUBSTR(cpf,-3) AS cpf
FROM app_dados.candidatos;
```

---

# Teste de Independência

## 15. Inserir novos registros apenas no clone

```sql
CONNECT app_dados/se$nha4PW@pdb_clone

SHOW CON_NAME

INSERT INTO candidatos
VALUES
(
6,
'Miguel Ortiz',
'Cientista de Dados',
'Autonomo',
'666.666.666-90'
);

INSERT INTO candidatos
VALUES
(
7,
'Jose Alvarado',
'Desenvolvedor',
'Em analise',
'777.777.777-90'
);
```

---

## 16. Confirmar os registros

```sql
SELECT id_candidato,
       nome,
       vaga,
       status,
       SUBSTR(cpf,1,4)||'***.***'||SUBSTR(cpf,-3) AS cpf
FROM candidatos
ORDER BY 1;
```

---

## 17. Validar que o PDB original permaneceu inalterado

```sql
CONNECT clara/se$nha2PW@orclpdb

SHOW PDBS
```

---

## 18. Consulta utilizando uma View com privilégios restritos

```sql
SELECT *
FROM app_dados.vw_candidatos_recrutamento;
```

Este teste demonstra que:

- o clone possui seus próprios dados;
- alterações realizadas no clone não afetam o banco original;
- o princípio do **Least Privilege** permanece preservado.

---

# Resultado

Ao final deste projeto foi possível:

- Clonar uma PDB utilizando Oracle Multitenant.
- Utilizar Oracle Managed Files (OMF).
- Validar a criação do clone.
- Confirmar a independência dos datafiles.
- Configurar o acesso via Oracle Net.
- Demonstrar isolamento entre PDB original e PDB clonado.
- Validar consultas utilizando usuários com privilégios distintos.

---

# Competências Demonstradas

- Oracle Database 19c
- Oracle Multitenant
- CDB/PDB
- SQL*Plus
- Oracle Managed Files (OMF)
- Administração de Banco de Dados
- Oracle Net Services
- Gerenciamento de Datafiles
- Administração de Usuários
- Segurança de Banco de Dados
- Least Privilege
- Oracle Linux
