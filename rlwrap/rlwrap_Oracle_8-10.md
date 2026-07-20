# RLWRAP no Oracle Linux 8.10

## 📖 Visão Geral

Este guia demonstra como instalar e configurar o **RLWRAP** no **Oracle Linux 8.10**, habilitando o repositório **Oracle EPEL** quando necessário.

O **RLWRAP** adiciona funcionalidades importantes aos utilitários de linha de comando do Oracle Database, como:

- Histórico de comandos
- Navegação utilizando as teclas direcionais
- Edição de comandos
- Autocomplete básico
- Maior produtividade durante atividades administrativas

É uma ferramenta amplamente utilizada por DBAs Oracle em ambientes Linux.

---

# 🎯 Objetivo

Disponibilizar o **RLWRAP** para utilização com ferramentas Oracle como:

- SQL*Plus
- RMAN
- ASMCMD

---

# 🖥️ Ambiente

| Item | Versão |
|-------|---------|
| Sistema Operacional | Oracle Linux 8.10 |
| Banco de Dados | Oracle Database 19c |
| Gerenciador de Pacotes | DNF |

---

# 📋 Pré-requisitos

- Oracle Linux 8.10
- Usuário com privilégios de root
- Acesso aos repositórios Oracle Linux

---

# 📦 Instalação

## 1. Instalar o repositório Oracle EPEL

```bash
dnf install oracle-epel-release-el8 -y
```

---

## 2. Habilitar o repositório EPEL

```bash
dnf config-manager --set-enabled ol8_developer_EPEL
```

---

## 3. Atualizar o cache do DNF

```bash
dnf makecache
```

---

## 4. Instalar o RLWRAP

```bash
dnf install rlwrap -y
```

---

## 5. Validar a instalação

```bash
rlwrap -v
```

Exemplo de saída:

```text
rlwrap 0.46.x
```

---

# 🔧 Caso o comando `dnf config-manager` não exista

Instale o pacote responsável pelos plugins do DNF.

```bash
dnf install dnf-plugins-core -y
```

Depois execute novamente:

```bash
dnf config-manager --set-enabled ol8_developer_EPEL
```

---

# 🔍 Validando os repositórios

Confira se o repositório foi habilitado corretamente.

```bash
dnf repolist
```

Resultado esperado:

```text
ol8_developer_EPEL
```

---

# 🚀 Utilização

## SQL*Plus

```bash
rlwrap sqlplus / as sysdba
```

---

## RMAN

```bash
rlwrap rman target /
```

---

## ASMCMD

```bash
rlwrap asmcmd
```

---

# ✅ Benefícios

Após a instalação do RLWRAP, os utilitários Oracle passam a oferecer recursos semelhantes aos shells modernos.

- Histórico persistente de comandos
- Navegação com ↑ e ↓
- Edição de comandos utilizando ← e →
- Pesquisa rápida no histórico
- Autocomplete básico
- Melhor experiência de administração em terminal

---

# 📁 Estrutura do Projeto

```
rlwrap-oracle-linux/
│
├── README.md
└── prints/
    ├── instalacao.png
    ├── repolist.png
    └── rlwrap-version.png
```

---

# 📸 Evidências

Adicione capturas de tela como:

- Erro inicial informando que o pacote não foi encontrado
- Instalação do repositório Oracle EPEL
- Instalação do RLWRAP
- Resultado do comando `rlwrap -v`
- Execução do SQL*Plus utilizando RLWRAP

Exemplo:

```markdown
![Instalação](prints/instalacao.png)

![Versão](prints/rlwrap-version.png)
```

---

# 💡 Boas práticas

- Atualizar periodicamente os metadados do DNF.
- Utilizar apenas repositórios oficiais Oracle.
- Validar os repositórios antes da instalação.
- Documentar dependências em ambientes de produção.
- Manter scripts de instalação versionados no GitHub.

---

# 📚 Tecnologias Utilizadas

- Oracle Linux 8.10
- Oracle Database 19c
- DNF
- Oracle EPEL Repository
- RLWRAP
- Bash

---

# 🎓 Conhecimentos Demonstrados

- Administração de Oracle Linux
- Gerenciamento de repositórios DNF
- Resolução de dependências
- Instalação de pacotes em ambientes Oracle
- Configuração de utilitários para Oracle Database
- Boas práticas para ambientes Linux corporativos

---

# 📖 Referências

- Oracle Linux
- Oracle Database Documentation
- DNF Package Manager
- RLWRAP Project

---

# 👤 Autor

**Nilton Cesar**

Oracle Database Administrator | Oracle Database 19c | Oracle Linux | Backup & Recovery | Performance Tuning | RMAN | Shell Script | SQL | GitHub Portfolio

---

## ⭐ Objetivo deste projeto

Este projeto faz parte do meu laboratório de estudos em **Oracle Database Administration**, documentando procedimentos reais utilizados por DBAs em ambientes Linux para facilitar a administração do Oracle Database.
