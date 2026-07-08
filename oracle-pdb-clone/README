# Oracle Database 19c
# Clone de Pluggable Database (PDB) em Arquitetura Multitenant

---

## Informações do Projeto

| Item | Valor |
|------|-------|
| Projeto | Clone de Pluggable Database |
| Banco de Dados | Oracle Database 19c |
| Arquitetura | Multitenant (CDB/PDB) |
| Sistema Operacional | Oracle Linux |
| Ferramenta | SQL*Plus |
| Autor | Nilton cESAR |
| Status | Concluído |

---

# Objetivo

Demonstrar o processo completo de clonagem de uma Pluggable Database (PDB) utilizando Oracle Database 19c em arquitetura Multitenant, validando a integridade da operação, independência física dos datafiles e isolamento lógico dos dados.

Este procedimento é amplamente utilizado para provisionamento de ambientes de desenvolvimento, homologação e testes em ambientes corporativos.

---

# Escopo

O projeto contempla:

- Validação do ambiente Oracle
- Criação de uma nova PDB utilizando Clone Local
- Abertura da nova PDB
- Persistência do estado (SAVE STATE)
- Validação da criação
- Validação dos Datafiles
- Validação do GUID
- Teste de isolamento entre PDBs

---

# Arquitetura

Antes da clonagem:

```
                 CDB ORCL
                     │
      ┌──────────────┴──────────────┐
      │                             │
   ORCLPDB                      PRODPDB
```

Após a clonagem:

```
                 CDB ORCL
                     │
      ┌──────────────┼──────────────┐
      │              │              │
   ORCLPDB        PRODPDB       PDB_CLONE
```

---

# Ambiente

| Componente | Valor |
|------------|-------|
| Oracle Database | 19c |
| Container Database | ORCL |
| PDB Origem | ORCLPDB |
| PDB Clone | PDB_CLONE |
| Open Mode | READ WRITE |
| Log Mode | ARCHIVELOG |

---

# Pré-requisitos

Antes da execução foram verificados:

- Banco em ARCHIVELOG
- Banco aberto em READ WRITE
- Ambiente Multitenant
- Espaço disponível
- PDB origem operacional

Consulta utilizada:
# Procedimento

## 1. Verificação das PDBs

```sql
SELECT name, cdb, open_mode, log_mode
FROM v$database;
```

```sql
SELECT con_id, name, open_mode, restricted
FROM v$pdbs
ORDER BY con_id;
```

### Evidência

<p align="center">
<img src="prints/f1.png" width="900">
</p>

---

## 2. Criação da Nova PDB

```sql
CREATE PLUGGABLE DATABASE pdb_clone
FROM orclpdb;

COL name for A15
COL restricted for a15
SELECT con_id, name, open_mode, restricted FROM v$pdbs ORDER BY con_id;
```

Resultado esperado

```
Pluggable database created.
```

### Evidência

<p align="center">
<img src="prints/f2.png" width="900">
</p>

---

## 3. Abertura da PDB

```sql
ALTER PLUGGABLE DATABASE pdb_clone OPEN;
```

---

## 4. Persistência do Estado

```sql
ALTER PLUGGABLE DATABASE pdb_clone SAVE STATE;
```
## 5. Validação da clonagem: comparação entre o PDB original e o clone
```sql
COL name for A10
COL OPEN_MODE for A15
COl restricted for A10
SELECT con_id, name, guid, open_mode, restricted, creation_time
FROM v$pdbs
WHERE name IN ('ORCLPDB','PDB_CLONE')
ORDER BY con_id;
```
Resultado esperado

- GUID diferente
- OPEN READ WRITE
- Nova data de criação

### Evidência

<p align="center">
<img src="prints/f3.png" width="900">
</p>

---

# Verificação dos datafiles de cada PDB (tamanho e status)

Após o clone foi realizada a conferência dos datafiles de cada PDB

```sql
COL con_name for A10
COL file_name for A60
COL status for A10

SELECT c.name AS con_name, d.file_id, d.file_name, ROUND(d.bytes/1024/1024) AS MB, d.status
FROM cdb_data_files d
JOIN v$containers c ON c.con_id = d.con_id
WHERE c.name IN ('ORCLPDB','PDB_CLONE')
ORDER BY c.name, d.file_id;
```

### Evidência

<p align="center">
<img src="prints/f4.png" width="900">
</p>

---

# Verificando se algum datafile está sendo compartilhado entre
os dois PDBs ( no rows selected )

Consulta utilizada:

```sql
SELECT a.file_name
FROM cdb_data_files a
JOIN cdb_data_files b
ON a.file_name = b.file_name
AND a.con_id <> b.con_id
WHERE a.con_id IN (SELECT con_id FROM v$containers WHERE name = 'ORCLPDB')
AND b.con_id IN (SELECT con_id FROM v$containers WHERE name = 'PDB_CLONE');
```

### Evidência

<p align="center">
<img src="prints/f5.png" width="900">
</p>

---

# Validação da Independência Física

Foi realizada uma comparação direta entre os arquivos físicos.

Resultado

```
No rows selected
```

Conclusão:

Os datafiles da PDB original não são compartilhados com a PDB clonada.

---
# Teste de independência dos PDBs: conexão como usuário da aplicação


```sql
-- ORCLPDB
alter session set container=orclpdb;

col nome for A25
col vaga for A30
col status for A15
SELECT id_candidato, nome, vaga, status,
SUBSTR(cpf,1,4) || '***.***' || SUBSTR(cpf,-3) AS cpf
FROM app_dados.candidatos;

-- PDB_CLONE
alter session set container=pdb_clone;

col nome for A25
col vaga for A30
col status for A15
SELECT id_candidato, nome, vaga, status,
SUBSTR(cpf,1,4) || '***.***' || SUBSTR(cpf,-3) AS cpf
FROM app_dados.candidatos;

```

### Evidência

<p align="center">
<img src="prints/f6.png" width="900">
</p>

<p align="center">
<img src="prints/f7.png" width="900">
</p>

---

# Teste Funcional

Novos registros foram inseridos apenas na PDB_CLONE.
```sql
conn app_dados/se$nha4PW@pdb_clone

show con_name

INSERT INTO candidatos (id_candidato, nome, vaga, status, cpf)
VALUES (6, 'Miguel Ortiz', 'Cientista de Dados', 'Autonomo', '666.666.666-90');

INSERT INTO candidatos (id_candidato, nome, vaga, status, cpf)
VALUES (7, 'Jose Alvarado', 'Desenvolvedor', 'Em analise', '777.777.777-90');
```
### Evidência

<p align="center">
<img src="prints/f8.png" width="900">
</p>


Em seguida foi realizada a conferência:

| Ambiente | Registros |
|-----------|----------|
| ORCLPDB | 5 |
| PDB_CLONE | 7 |


```sql
SELECT id_candidato, nome, vaga, status,
SUBSTR(cpf,1,4) || '***.***' || SUBSTR(cpf,-3) AS cpf
FROM candidatos
ORDER BY 1;
```

### Evidência

<p align="center">
<img src="prints/f9.png" width="900">
</p>

Resultado

As alterações permaneceram restritas à PDB clonada, comprovando o isolamento entre os ambientes.


---

# Resultado Obtido

O ambiente foi provisionado com sucesso.

Foi validado:

- Clone da PDB
- GUID exclusivo
- Datafiles independentes
- Persistência automática do estado
- Isolamento lógico dos dados
- Integridade da PDB original

---

# Aplicações Corporativas

Este procedimento pode ser utilizado para:

- Provisionamento de ambientes de homologação
- Criação de ambientes de desenvolvimento
- Testes de atualização
- Testes de Backup & Recovery
- Testes de aplicações
- Laboratórios para treinamento
- Ambientes Sandbox

---

# Competências Demonstradas

- Oracle Database 19c
- Oracle Multitenant
- Administração de CDB/PDB
- SQL*Plus
- Oracle Managed Files (OMF)
- Administração de Datafiles
- Administração de Containers
- Provisionamento de Ambientes
- Administração Oracle
- Validação pós-implantação

---

# Estrutura do Repositório

```
oracle-pdb-clone
│
├── README.md
├── script_clone_pdb.sql
│
└── prints
    ├── 01-ambiente.png
    ├── 02-create-pdb.png
    ├── 03-open-save-state.png
    ├── 04-guid.png
    ├── 05-datafiles.png
    ├── 06-comparacao-datafiles.png
    └── 07-isolamento.png
```

---

# Conclusão

Este projeto demonstra uma atividade comum da administração Oracle em ambientes Multitenant, evidenciando a criação de uma Pluggable Database por clonagem, validação da infraestrutura gerada e comprovação do isolamento entre ambientes.

Além da execução dos comandos, foram realizadas validações pós-implantação para garantir a consistência da operação, reproduzindo uma rotina típica de administração de banco de dados em ambientes corporativos.
