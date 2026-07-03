
# Projeto Oracle 19c — Gerenciamento de Usuários, Roles e Privilégios

## Objetivo
Simular um cenário corporativo de onboarding de usuários aplicando o princípio do **Least Privilege (Menor Privilégio)** no Oracle Database 19c.

## Tecnologias
- Oracle Database 19c
- Oracle Linux 7.9
- SQL
- Oracle Managed Files (OMF)

---

```sql
/*
================================================================================
 PROJETO: Onboarding de equipe com Least Privilege - Oracle 19c (OL 7.9, OMF on)
 EQUIPE:
   - ALBERTO  -> Analista de Dados   (consulta dados de negócio, sem DDL)
   - CLARA    -> Tech Recruiter      (consulta só dados de RH/candidatos)
   - MARILIA  -> DBA Junior          (operação básica, sem privilégios de risco)
 EXECUTAR COMO: SYS ou usuário com DBA (ex: sqlplus / as sysdba)
================================================================================
*/


-- Como o OMF (Oracle Managed Files) está habilitado, NÃO especificamos
-- caminho de datafile: o Oracle cria automaticamente em DB_CREATE_FILE_DEST.
-- Confirme antes de rodar:
SELECT name, value FROM v$parameter WHERE name = 'db_create_file_dest';

-- ==============================================================================
1. CRIAÇÃO DA TABLESPACE DEDICADA PARA O PROJETO
-- ==============================================================================
CREATE TABLESPACE TS_EQUIPE_NOVA DATAFILE SIZE 200M
  AUTOEXTEND ON NEXT 50M MAXSIZE 2G
  EXTENT MANAGEMENT LOCAL
  SEGMENT SPACE MANAGEMENT AUTO;

-- Tablespace temporária dedicada (opcional, mas recomendado para isolar I/O)
CREATE TEMPORARY TABLESPACE TS_EQUIPE_NOVA_TEMP TEMPFILE SIZE 100M
AUTOEXTEND ON NEXT 50M MAXSIZE 1G;

-- Checar tablespaces criadas
SELECT tablespace_name, status, contents, extent_management
FROM   dba_tablespaces
WHERE  tablespace_name LIKE 'TS_EQUIPE%';


-- ==============================================================================
-- 2. PROFILE (politica de senha + limites de recurso)
-- ==============================================================================
-- Um profile para a equipe toda; se quiser políticas diferentes por papel,
-- duplique o bloco trocando o nome (ex: PRF_DBA_JR mais permissivo em sessões).
CREATE PROFILE PRF_EQUIPE_NOVA LIMIT
  -- ---- Password Policy ----
  PASSWORD_LIFE_TIME           60          -- expira em 60 dias
  PASSWORD_GRACE_TIME          7           -- 7 dias de carência após expirar
  PASSWORD_REUSE_TIME          365         -- não pode reusar senha por 1 ano
  PASSWORD_REUSE_MAX           5           -- nem repetir entre as últimas 5
  PASSWORD_VERIFY_FUNCTION     ora12c_verify_function  -- função padrão 19c de complexidade
  -- ---- Account Lock (proteção contra força bruta) ----
  FAILED_LOGIN_ATTEMPTS        3           -- bloqueia após 3 tentativas erradas
  PASSWORD_LOCK_TIME           1           -- fica bloqueado 1 dia (ou até DBA desbloquear)
  -- ---- Limites de sessão/recurso (proteção contra abuso) ----
  SESSIONS_PER_USER            3
  CONNECT_TIME                 480         -- 8h de sessão máxima
  IDLE_TIME                    30          -- desconecta após 30 min ocioso
  CPU_PER_SESSION              UNLIMITED
  LOGICAL_READS_PER_SESSION    UNLIMITED;
  
-- DBA_PROFILES: política de senha e limites de recurso aplicados
-- ------------------------------------------------------------------------------
COL profile for A20
COL resource_name for A30
SELECT profile, resource_name, limit
FROM   dba_profiles
WHERE  profile = 'PRF_EQUIPE_NOVA'
ORDER  BY resource_name;


-- ==============================================================================
-- 3. ROLES (agrupar privilégios por função - NUNCA conceder direto ao usuário)
-- ==============================================================================
CREATE ROLE ROLE_ANALISTA_DADOS;
CREATE ROLE ROLE_TECH_RECRUITER;
CREATE ROLE ROLE_DBA_JUNIOR;

-- DBA_ROLES: roles existentes (confirmar que as 3 novas foram criadas)
-- ------------------------------------------------------------------------------
COL role for A30
COL password_required for A20
COL authentication_type for A20
SELECT role, password_required, authentication_type
FROM   dba_roles
WHERE  role LIKE 'ROLE_%';


-- ------------------------------------------------------------------------------
-- 3.1 SYSTEM PRIVILEGES por role (mínimo necessário)
-- ------------------------------------------------------------------------------

-- Analista de Dados: só precisa conectar e criar sua própria sessão de trabalho
GRANT CREATE SESSION TO ROLE_ANALISTA_DADOS;

-- Tech Recruiter: só conecta, sem nenhum privilégio de criação de objeto
GRANT CREATE SESSION TO ROLE_TECH_RECRUITER;

-- DBA Junior: conecta + pode criar objetos próprios de apoio (sem privilégios
-- administrativos de alto risco como DROP ANY TABLE, ALTER SYSTEM, GRANT ANY...)
GRANT CREATE SESSION   TO ROLE_DBA_JUNIOR;
GRANT CREATE TABLE     TO ROLE_DBA_JUNIOR;
GRANT CREATE VIEW      TO ROLE_DBA_JUNIOR;
GRANT CREATE PROCEDURE TO ROLE_DBA_JUNIOR;
GRANT CREATE SEQUENCE  TO ROLE_DBA_JUNIOR;

-- Privilégio de leitura ampla ao dicionário/performance (apenas leitura,
-- sem poder de alteração) — ajuda no aprendizado de DBA Jr com segurança.
GRANT SELECT_CATALOG_ROLE TO ROLE_DBA_JUNIOR;



#4. USUÁRIOS
-- ==============================================================================
CREATE USER alberto IDENTIFIED BY "se$nha1PW"
  DEFAULT TABLESPACE TS_EQUIPE_NOVA
  TEMPORARY TABLESPACE TS_EQUIPE_NOVA_TEMP
  PROFILE PRF_EQUIPE_NOVA
  QUOTA 100M ON TS_EQUIPE_NOVA
  ACCOUNT UNLOCK;

CREATE USER clara IDENTIFIED BY "se$nha2PW"
  DEFAULT TABLESPACE TS_EQUIPE_NOVA
  TEMPORARY TABLESPACE TS_EQUIPE_NOVA_TEMP
  PROFILE PRF_EQUIPE_NOVA
  QUOTA 0M ON TS_EQUIPE_NOVA
  ACCOUNT UNLOCK;

CREATE USER marilia IDENTIFIED BY "se$nha3PW"
  DEFAULT TABLESPACE TS_EQUIPE_NOVA
  TEMPORARY TABLESPACE TS_EQUIPE_NOVA_TEMP
  PROFILE PRF_EQUIPE_NOVA
  QUOTA 100M ON TS_EQUIPE_NOVA
  ACCOUNT UNLOCK;
  
-- DBA_USERS: status da conta, profile, tablespace default, datas de expiração
COL username for A10
COL account_status for A15 
COL profile for A18
COL default_tablespace for A15
COL temporary_tablespace for A20
COL lock_date for A10
SELECT username, account_status, profile, default_tablespace,
temporary_tablespace, expiry_date, lock_date, created
FROM   dba_users
WHERE  username IN ('ALBERTO','CLARA','MARILIA','APP_DADOS')
ORDER  BY username;


-- Forçar troca de senha no primeiro login
ALTER USER alberto PASSWORD EXPIRE;
ALTER USER clara PASSWORD EXPIRE;
ALTER USER marilia PASSWORD EXPIRE;
 

-- ==============================================================================
-- 5. ATRIBUIÇÃO DE ROLES AOS USUÁRIOS
-- ==============================================================================
GRANT ROLE_ANALISTA_DADOS TO alberto;
GRANT ROLE_TECH_RECRUITER TO clara;
GRANT ROLE_DBA_JUNIOR TO marilia;

-- Tornar a role "default" (ativa automaticamente no login, sem precisar de SET ROLE)
ALTER USER alberto DEFAULT ROLE ROLE_ANALISTA_DADOS;
ALTER USER clara DEFAULT ROLE ROLE_TECH_RECRUITER;
ALTER USER marilia DEFAULT ROLE ROLE_DBA_JUNIOR;

-- DBA_SYS_PRIVS: privilégios de sistema concedidos a cada ROLE
-- (lembrando: o usuário não recebe privilégio direto, só via role)
-- ------------------------------------------------------------------------------
COL grantee for A25
COL privilege for A25
COL admin_option for A25
SELECT grantee, privilege, admin_option
FROM   dba_sys_privs
WHERE  grantee IN ('ROLE_ANALISTA_DADOS','ROLE_TECH_RECRUITER','ROLE_DBA_JUNIOR')
ORDER  BY grantee, privilege
;

-- DBA_TAB_PRIVS: privilégios de objeto (quem pode acessar o quê, e como)
-- ------------------------------------------------------------------------------
SELECT grantee, owner, table_name, privilege, grantable
FROM   dba_tab_privs
WHERE  grantee IN ('ALBERTO','CLARA','MARILIA')
ORDER  BY grantee, table_name;



-- DBA_ROLE_PRIVS: quais usuários têm quais roles, e se é a role default

COL grantee for A10
COL granted_role for A25
COL admin_option for A5
COL default_role for a15
SELECT grantee, granted_role, admin_option, default_role
FROM   dba_role_privs
WHERE  grantee IN ('ALBERTO','CLARA','MARILIA')
ORDER  BY grantee;



-- ==============================================================================
-- 6. SCHEMAS / TABELAS DE EXEMPLO PARA TESTAR OBJECT PRIVILEGES
-- ==============================================================================
-- Vamos simular dois domínios de dados: "negócio" (vendas) e "RH" (candidatos).
-- O Analista só deve enxergar o domínio de negócio; a Recruiter só o de RH.

-- Criar um schema "dono" dos dados (poderia ser um usuário de aplicação)
CREATE USER app_dados IDENTIFIED BY "se$nha4PW"
  DEFAULT TABLESPACE TS_EQUIPE_NOVA
  TEMPORARY TABLESPACE TS_EQUIPE_NOVA_TEMP
  PROFILE PRF_EQUIPE_NOVA
  QUOTA 200M ON TS_EQUIPE_NOVA
  ACCOUNT UNLOCK;
  
  -- DBA_USERS: status da conta, profile, tablespace default, datas de expiração
SELECT username, account_status, profile, default_tablespace,
       temporary_tablespace, expiry_date, lock_date, created
FROM   dba_users
WHERE  username = 'APP_DADOS'
ORDER  BY username;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW TO app_dados;

conn app_dados/se$nha4PW@orclpdb;


CREATE TABLE vendas (
  id_venda     NUMBER PRIMARY KEY,
  produto      VARCHAR2(50),
  valor        NUMBER(10,2),
  data_venda   DATE
);

INSERT INTO vendas (id_venda, produto, valor, data_venda)
VALUES (1, 'Notebook Dell Latitude', 5899.90, DATE '2026-06-10');

INSERT INTO vendas (id_venda, produto, valor, data_venda)
VALUES (2, 'Monitor LG 27 Polegadas', 1499.00, DATE '2026-06-12');

INSERT INTO vendas (id_venda, produto, valor, data_venda)
VALUES (3, 'Teclado Mecânico', 429.90, DATE '2026-06-15');

INSERT INTO vendas (id_venda, produto, valor, data_venda)
VALUES (4, 'Mouse Sem Fio', 189.90, DATE '2026-06-18');

INSERT INTO vendas (id_venda, produto, valor, data_venda)
VALUES (5, 'SSD NVMe 1TB', 649.90, DATE '2026-06-22');

COMMIT;

SELECT * FROM vendas;



CREATE TABLE candidatos (
  id_candidato NUMBER PRIMARY KEY,
  nome         VARCHAR2(100),
  vaga         VARCHAR2(50),
  status       VARCHAR2(20),
  cpf          VARCHAR2(14)   -- dado sensível: nenhum outro perfil deve ver isso direto
);

INSERT INTO candidatos (id_candidato, nome, vaga, status, cpf)
VALUES (1, 'Alexander Wagner', 'DBA Oracle Júnior', 'Em Análise', '111.111.111-11');

INSERT INTO candidatos (id_candidato, nome, vaga, status, cpf)
VALUES (2, 'Finn Herrmann', 'Analista de Banco de Dados', 'Aprovado', '222.222.222-22');

INSERT INTO candidatos (id_candidato, nome, vaga, status, cpf)
VALUES (3, 'Lina Zimmermann', 'Desenvolvedor PL/SQL', 'Entrevista', '333.333.333-33');

INSERT INTO candidatos (id_candidato, nome, vaga, status, cpf)
VALUES (4, 'Mia Hoffmann', 'DBA Oracle Júnior', 'Triagem', '444.444.444-44');

INSERT INTO candidatos (id_candidato, nome, vaga, status, cpf)
VALUES (5, 'Lukas Weber', 'Analista de Dados', 'Contratado', '555.555.555-55');

COMMIT;

col nome for A20
col vaga for A30
col status for A20

SELECT id_candidato, nome, vaga, status,
SUBSTR(cpf,1,4) || '***.***' || SUBSTR(cpf,-3) AS cpf
FROM candidatos;


-- View que expõe só o necessário para a recrutadora (sem CPF)
CREATE VIEW vw_candidatos_recrutamento AS
  SELECT id_candidato, nome, vaga, status FROM candidatos;

-- ==============================================================================
-- 7. OBJECT PRIVILEGES (granularidade fina: só o objeto/coluna necessária)
-- ==============================================================================

-- Alberto (Analista de Dados) -> só SELECT na tabela de vendas, nada de RH
GRANT SELECT ON app_dados.vendas TO alberto;
GRANT SELECT ON app_dados.candidatos TO alberto;
GRANT SELECT ON app_dados.vendas TO marilia;

-- Clara (Tech Recruiter) -> só SELECT na VIEW sem CPF, nunca na tabela bruta
GRANT SELECT ON app_dados.vw_candidatos_recrutamento TO clara;



/*
================================================================================
 02_testes_antes_depois.sql
 Objetivo: demonstrar FALHA de acesso (antes da correção) e SUCESSO
 (depois da correção), por usuário.
================================================================================
*/


-- ==============================================================================
  CENÁRIO "ANTES" — conectar como cada usuário e tentar acessar o que NÃO deveria
-- ==============================================================================

-- ---- ALBERTO (Analista de Dados) ----
conn alberto/se$nha1PW@orclpdb  

-- Esperado: FUNCIONA (privilégio concedido)
SELECT * FROM app_dados.vendas;


-- Esperado: ERRO ORA-00942 table or view does not exist
-- (Alberto não tem GRANT em candidatos nem na view de RH)
SELECT * FROM app_dados.candidatos;
SELECT * FROM app_dados.vw_candidatos_recrutamento;

-- Esperado: ERRO ORA-01031 insufficient privileges
-- (role só tem CREATE SESSION, não CREATE TABLE)
CREATE TABLE teste_alberto (id NUMBER);



-- ---- CLARA (Tech Recruiter) ----
conn clara/se$nha2PW@orclpdb

-- Esperado: FUNCIONA, mas SEM a coluna CPF (view filtra o dado sensível)
col nome for A20
col status for A15
col vaga for A30
SELECT * FROM app_dados.vw_candidatos_recrutamento;

-- Esperado: ERRO ORA-00942 (sem acesso à tabela bruta com CPF)
SELECT * FROM app_dados.candidatos;

-- Esperado: ERRO ORA-00942 (não enxerga dados de vendas)
SELECT * FROM app_dados.vendas;

-- Esperado: ERRO ORA-01031 (quota = 0, mesmo que tivesse privilégio de CREATE)
CREATE TABLE teste_clara (id NUMBER);





-- ---- MARILIA (DBA Junior) ----
conn marilia/se$nha3PW

-- Esperado: FUNCIONA (role de DBA jr permite criar objetos próprios)
CREATE TABLE log_estudo (id NUMBER, descricao VARCHAR2(100));
INSERT INTO log_estudo VALUES (1, 'teste de DBA junior');
COMMIT;

-- Esperado: FUNCIONA (SELECT_CATALOG_ROLE dá leitura ao dicionário)
SELECT username, account_status FROM dba_users WHERE username = 'MARILIA';

-- Esperado: ERRO ORA-01031 — privilégio administrativo de alto risco
-- NÃO foi concedido (princípio do menor privilégio em ação)
DROP TABLE app_dados.vendas;          -- não tem DROP ANY TABLE
ALTER SYSTEM SWITCH LOGFILE;          -- não tem ALTER SYSTEM
GRANT SELECT ANY TABLE TO PUBLIC;     -- não tem GRANT ANY PRIVILEGE



-- ==============================================================================
-- CENÁRIO "DEPOIS" — correção pontual de um caso real de necessidade legítima
-- ==============================================================================
-- Suponha que Alberto agora também precise enxergar status de candidatos
-- (sem CPF) para cruzar dados de contratação x vendas geradas pelo time novo.
-- A correção certa é dar acesso à VIEW (já filtrada), nunca à tabela base.

alter session set container=orclpdb;

GRANT SELECT ON app_dados.vw_candidatos_recrutamento TO alberto;

conn alberto/se$nha1PW@orclpdb

-- Agora funciona, mas ainda sem CPF, respeitando o menor privilégio
SELECT * FROM app_dados.vw_candidatos_recrutamento;




```
