
https://www.linkedin.com/in/niltoncesar07/

-- Downloads Necessários
Virtual Box - https://www.virtualbox.org/wiki/Downloads 
MobaXTerm - https://mobaxterm.mobatek.net/download.html 
Oracle Database 19c - https://www.oracle.com/br/database/technologies/oracle19c-linux-downloads.html 
ISO Oracle Linux - https://edelivery.oracle.com/

Configurando IP de maneira Manual

    IPv4
    Method: Manual
      Address
      192.168.***.***
      
      Netmask
        255.255.255.0
      
      gateway 
        192.168.0.1
      
      DNS Server 
        8.8.8.8,8.8.4.4

      Search domains:
        localdomain


-- Adicionar registro no arquivo /etc/hosts:
****'Modo Manual'****
# vi /etc/hosts
[SEU IP] 			[HOSTNAME] 			[ALIAS]
192.168.***.***	ol7-dba.localdomain		ol7-dba

****'Modo Direto'****
# cat /etc/hosts
# echo "$(hostname -I | awk '{print $1}') $(hostname | cut -d'.' -f1) $(hostname)" >> /etc/hosts
# cat /etc/hosts


'Virtual Box'
# vi /etc/sysconfig/network-scripts/ifcfg-enp0s3 
BOOTPROTO="static"
IPADDR= hostname

'VMWare'
# vi /etc/sysconfig/network-scripts/ifcfg-ens33 (VMware)
BOOTPROTO="static"
IPADDR= hostname

# yum -y install oracle-epel-release-el7.x86_64
# yum -y install rlwrap

reboot



# yum search preinstall
# yum -y install oracle-database-preinstall-19c
# yum install oracle-database-preinstall-19c -y

-Colocar senha
# passwd oracle


-- abrir mais uma sessão oracle e colocar o arquivo ZIP
$ /home/oracle



--- Desabilitar SELINUX

-- 1° Modo
# sestatus | grep -i mode
# grep -E '^SELINUX=(disabled|enforcing)$' /etc/selinux/config

# sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

# grep -E '^SELINUX=(disabled|enforcing)$' /etc/selinux/config

-- 2° Modo
# vi /etc/selinux/config
selinux=disabled


-- Parando e desabilitando Firewall
# systemctl stop firewalld
# systemctl disable firewalld


# mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1
# mkdir -p /u02/oradata
# mkdir -p /u03/DATA
# mkdir -p /u04/FRA

Alterar o owner dos diretórios e as permissões:
# chown -R oracle:oinstall /u01 /u02 /u03 /u04
# chmod -R 775 /u01 /u02 /u03 /u04



************************** ORACLE ****************************

$ cd /u01/app/oracle/product/19.0.0/dbhome_1
$ unzip -o /home/oracle/LINUX.x64_193000_db_home.zip

--Modo Quiet
$ unzip -q /home/oracle/LINUX.x64_193000_db_home.zip 

$ ./runInstaller


“Create and configure a single instance database”

Selecionamos “Desktop class”


Datafile file location:
/u02/oradata





-- Para validar se o banco de dados está rodando usamos:
$ ps aux | grep smon

-- Para acessar o banco de dados via sqlplus:
$ . oraenv
orcl

-- Editar o arquivo listener.ora e o LISTENER_ORCL por LISTENER:
$ vi $ORACLE_HOME/network/admin/listener.ora


-- Adicionar o registro do ORCLPDB e trocar o LISTENER_ORCL para LISTENER
$ vi $ORACLE_HOME/network/admin/tnsnames.ora


$ sqlplus / as sysdba
-- Executar a primeira query no banco:
SELECT INSTANCE_NAME, STARTUP_TIME, STATUS FROM V$INSTANCE;

show parameter local_listener
ALTER SYSTEM SET LOCAL_LISTENER='LISTENER';
show parameter local_listener


shutdown immediate
exit

-- Reiniciar o listener:
$ lsnrctl stop
$ lsnrctl start


-- Logado como usuário oracle, setamos as variáveis e vamos até o seguinte caminho:
$ . oraenv
orcl

$ cd $ORACLE_HOME/demo/schema/human_resources

-- Neste caminho executamos o sqlplus e fazemos o unlock da conta do usuário HR, dentro do pdb:

sqlplus/ as sysdba
startup

alter session set container = orclpdb;

alter pluggable database orclpdb open;

-- Salvando o estado do PDB
alter pluggable database orclpdb save state 

alter user hr account unlock;

@hr_main.sql
hr
users
temp
/home/oracle

$ sqlplus hr/hr@orclpdb
> conn hr/hr@orclpdb

# criar os diretorios para o OMF

sqlplus / as sysdba
-- Configurando o OMF
show parameter db_create_file_dest
alter system set db_create_file_dest = '/home/oracle' SCOPE=BOTH;
show parameter db_create_file_dest

show parameter db_create_online_log_dest
alter system set db_create_online_log_dest_1 = '/u02/oradata' SCOPE=BOTH;
show parameter db_create_online_log_dest
alter system set db_create_online_log_dest_2 = '/u03/DATA' SCOPE=BOTH;
show parameter db_create_online_log_dest


Para setar o DB_RECOVERY_FILE_DEST devemos primeiro setar um tamanho com o parâmetro DB_RECOVERY_FILE_DEST_SIZE.

show parameter DB_RECOVERY_FILE_DEST_SIZE
alter system set db_recovery_file_dest_size = 10G SCOPE=BOTH;
alter system set db_recovery_file_dest = '/u04/FRA' SCOPE=BOTH;

-- Ativar ARCHIVELOG
SQL> SHUTDOWN IMMEDIATE;
SQL> STARTUP MOUNT;
SQL> ALTER DATABASE ARCHIVELOG;
SQL> ALTER DATABASE OPEN;



