# 🔐 Oracle Database 19c | Gerenciamento de Usuários, Roles e Privilégios

Projeto desenvolvido para simular um cenário corporativo de **onboarding de colaboradores**, aplicando o princípio de **Least Privilege (Menor Privilégio)** no Oracle Database 19c.

O objetivo é demonstrar boas práticas de administração de usuários, segurança e controle de acesso em ambientes Oracle.

---

# 🎯 Objetivos

- Criar uma estrutura de segurança para novos colaboradores.
- Aplicar o princípio de **Least Privilege**.
- Utilizar **Roles**, **Profiles**, **Tablespaces** e **Quotas**.
- Controlar privilégios de sistema e de objetos.
- Demonstrar testes de acesso antes e depois das permissões.

---

# 🏗️ Ambiente

| Item | Tecnologia |
|------|------------|
| Banco de Dados | Oracle Database 19c |
| Sistema Operacional | Oracle Linux 7.9 |
| Storage | Oracle Managed Files (OMF) |
| Linguagem | SQL |

---

# 👥 Cenário

A empresa contratou três novos colaboradores:

| Usuário | Cargo | Objetivo |
|---------|--------|----------|
| Alberto | Analista de Dados | Consulta dados de negócio |
| Clara | Tech Recruiter | Consulta somente dados de recrutamento |
| Marília | DBA Júnior | Administração básica do banco |

Cada usuário recebe apenas os privilégios necessários para executar suas atividades.

---

# 🔐 Recursos implementados

- Tablespaces dedicadas
- Temporary Tablespace
- Profiles
- Password Policy
- Bloqueio após tentativas de login
- Limites de sessão
- Roles
- System Privileges
- Object Privileges
- Quotas
- Usuários
- Views para mascaramento de dados
- Testes de segurança

---

# 📂 Estrutura do Projeto

```text
.
├── README.md
├── 01_onboarding.sql
└── 02_testes.sql
```

---

# 📌 Fluxo do Projeto

1. Criação das Tablespaces
2. Criação do Profile
3. Criação das Roles
4. Criação dos Usuários
5. Definição das Quotas
6. Associação das Roles
7. Criação do Schema da aplicação
8. Criação das tabelas
9. Inserção de dados fictícios
10. Criação da View protegida
11. Concessão dos privilégios
12. Testes de acesso

---

# 🔍 Cenários Testados

## Analista de Dados

✅ Consulta tabela de vendas

❌ Não cria tabelas

❌ Não acessa informações protegidas de RH

---

## Tech Recruiter

✅ Consulta apenas a View de recrutamento

❌ Não visualiza CPF

❌ Não consulta vendas

❌ Não cria objetos

---

## DBA Júnior

✅ Cria objetos próprios

✅ Consulta dicionário de dados

❌ Não executa ALTER SYSTEM

❌ Não possui DROP ANY TABLE

❌ Não possui privilégios administrativos perigosos

---

# 📚 Conceitos Oracle Utilizados

- CREATE USER
- ALTER USER
- PROFILE
- ROLE
- CREATE SESSION
- CREATE TABLE
- CREATE VIEW
- CREATE PROCEDURE
- CREATE SEQUENCE
- SELECT_CATALOG_ROLE
- GRANT
- QUOTA
- TABLESPACE
- TEMPORARY TABLESPACE
- PASSWORD POLICY
- Views
- Object Privileges
- System Privileges
- Least Privilege

---

# 💼 Competências Demonstradas

- Administração de Usuários Oracle
- Segurança em Banco de Dados
- Controle de Acesso
- Gestão de Roles
- Gestão de Profiles
- Administração de Tablespaces
- Administração de Quotas
- SQL
- Oracle Database 19c

---

# ▶️ Como Executar

1. Conecte-se como SYSDBA.
2. Execute o script de criação do ambiente.
3. Execute os testes utilizando cada usuário.
4. Valide os privilégios concedidos.

---



# ⭐ Aprendizados

Este projeto demonstra como implementar um modelo de segurança baseado no princípio do menor privilégio em um ambiente Oracle, utilizando recursos nativos para fornecer acesso apenas ao necessário para cada função.

---

> Projeto desenvolvido para fins de estudo e portfólio utilizando Oracle Database 19c.
