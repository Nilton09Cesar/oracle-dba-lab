# Oracle Database 19c | Clone de Pluggable Database (PDB) em Ambiente Multitenant

![Oracle](https://img.shields.io/badge/Oracle-19c-red)
![Linux](https://img.shields.io/badge/OS-Oracle%20Linux-blue)
![Status](https://img.shields.io/badge/Status-Concluído-success)
![SQL](https://img.shields.io/badge/SQL-Oracle-important)
![License](https://img.shields.io/badge/License-MIT-green)

## 📌 Sobre o Projeto

Este projeto demonstra a criação de uma **Pluggable Database (PDB)** através do recurso de **Clone Local** do Oracle Database 19c em arquitetura **Multitenant (CDB/PDB)**.

O objetivo foi simular uma atividade frequentemente realizada por DBAs em ambientes corporativos, como criação de ambientes de homologação, desenvolvimento, testes ou atualização de aplicações, validando todo o processo de clonagem e garantindo o isolamento entre as bases.

Ao final do projeto foi comprovado que:

- O clone recebeu um novo GUID.
- Os datafiles são independentes da PDB original.
- Alterações realizadas na PDB clonada não impactam a PDB de origem.

---

# 🎯 Objetivos

- Praticar administração Oracle Multitenant.
- Criar uma PDB por clonagem.
- Validar a independência física dos datafiles.
- Demonstrar isolamento dos dados.
- Simular uma atividade comum executada por DBAs em produção.

---

# 🏗 Ambiente

| Item | Descrição |
|-------|-----------|
| Banco de Dados | Oracle Database 19c |
| Sistema Operacional | Oracle Linux |
| Arquitetura | Multitenant (CDB/PDB) |
| CDB | ORCL |
| PDB Origem | ORCLPDB |
| PDB Clone | PDB_CLONE |
| SQL Client | SQL*Plus |

---

# 📚 Conceitos Utilizados

- Oracle Multitenant
- Container Database (CDB)
- Pluggable Database (PDB)
- Clone Local
- Oracle Managed Files (OMF)
- Datafiles
- GUID
- Save State
- Administração Oracle

---

# 🔍 Etapa 1 — Verificando o Ambiente

Antes da clonagem foi validado:

- Banco em ARCHIVELOG
- Ambiente Multitenant
- CDB aberta
- PDBs existentes

```sql
SHOW CON_NAME;

SELECT name,
       cdb,
       open_mode,
       log_mode
FROM v$database;

SELECT con_id,
       name,
       open_mode,
       restricted
FROM v$pdbs
ORDER BY con_id;
```

---

# 🚀 Etapa 2 — Criação da PDB Clone

Foi realizada a clonagem da PDB ORCLPDB.

```sql
CREATE PLUGGABLE DATABASE pdb_clone
FROM orclpdb;
```

Resultado:

```
Pluggable database created.
```

---

# 🔓 Etapa 3 — Abrindo a PDB

```sql
ALTER PLUGGABLE DATABASE pdb_clone OPEN;
```

---

# 💾 Etapa 4 — Persistindo o Estado

Para garantir abertura automática após restart.

```sql
ALTER PLUGGABLE DATABASE pdb_clone SAVE STATE;
```

---

# 🔍 Etapa 5 — Validação da Nova PDB

Foi verificado:

- GUID exclusivo
- Data de criação
- Estado OPEN

```sql
SELECT
    con_id,
    name,
    guid,
    open_mode,
    restricted,
    creation_time
FROM v$pdbs
WHERE name IN ('ORCLPDB','PDB_CLONE');
```

Resultado esperado:

|PDB|GUID|
|----|----|
|ORCLPDB|GUID original|
|PDB_CLONE|Novo GUID|

Cada PDB possui identidade própria.

---

# 📁 Etapa 6 — Validação Física dos Datafiles

Foi comparado o armazenamento físico das duas PDBs.

Consulta utilizada:

```sql
SELECT
    c.name,
    d.file_name
FROM cdb_data_files d
JOIN v$containers c
ON c.con_id = d.con_id
WHERE c.name IN ('ORCLPDB','PDB_CLONE')
ORDER BY c.name;
```

Resultado observado:

- Cada PDB possui seu próprio conjunto de datafiles.
- Não existe compartilhamento físico.

---

# 🔍 Etapa 7 — Comparação dos Arquivos

Foi realizada uma comparação direta dos arquivos.

Resultado:

```
no rows selected
```

Isso confirma que:

✅ Nenhum datafile da PDB original é compartilhado com a PDB clonada.

---

# 🧪 Etapa 8 — Teste de Isolamento

Na PDB original:

```sql
SELECT *
FROM app_dados.candidatos;
```

Resultado:

```
5 registros
```

Na PDB clonada foram inseridos novos candidatos.

```sql
INSERT INTO candidatos (...)
VALUES (...);
```

Após isso:

Na PDB Clone:

```
7 registros
```

Na PDB Original:

```
5 registros
```

Resultado:

✔️ As alterações ficaram restritas à PDB_CLONE.

---

# ✅ Resultado Final

Ao final do projeto foi comprovado que:

- Clone criado com sucesso.
- Nova identidade (GUID).
- Datafiles independentes.
- Estado persistido.
- Ambiente pronto para uso.
- Isolamento completo entre as PDBs.

---

# 📷 Evidências

## Ambiente Inicial

```
/prints/01-ambiente.png
```

## Criação da PDB

```
/prints/02-create-pdb.png
```

## Abertura da PDB

```
/prints/03-open-save-state.png
```

## GUID da PDB

```
/prints/04-guid.png
```

## Datafiles

```
/prints/05-datafiles.png
```

## Comparação dos Arquivos

```
/prints/06-comparacao-datafiles.png
```

## Teste de Isolamento

```
/prints/07-isolamento-pdb.png
```

---

# 📈 O que um DBA aprende neste projeto

- Administração de Oracle Multitenant.
- Provisionamento de novos ambientes.
- Clonagem de PDB.
- Gerenciamento de Containers.
- Administração de Datafiles.
- Persistência de estado.
- Validação de isolamento de dados.
- Consultas em views administrativas.
- Boas práticas de validação pós-clone.

---

# 💼 Aplicações Corporativas

Este procedimento é amplamente utilizado para:

- Ambientes de Homologação
- Ambientes de Desenvolvimento
- Testes de Atualizações
- Testes de Performance
- Testes de Backup e Recovery
- Treinamentos
- Sandbox para Desenvolvedores

---

# 🚀 Tecnologias Utilizadas

- Oracle Database 19c
- Oracle Multitenant
- SQL*Plus
- Oracle Linux
- SQL

---

# 📂 Estrutura do Projeto

```
clone-pdb-oracle19c/
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
    └── 07-isolamento-pdb.png
```

---

# 👨‍💻 Autor

**Nilton**

Oracle Database Administrator (DBA) em formação, desenvolvendo projetos práticos voltados à administração de bancos de dados Oracle, automação de rotinas e boas práticas utilizadas em ambientes corporativos.

- LinkedIn: *(adicione seu link)*
- GitHub: *(adicione seu link)*

---

⭐ Se este projeto foi útil para você, considere deixar uma estrela no repositório.
