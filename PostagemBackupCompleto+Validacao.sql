
# =============================================================
#  RMAN - Backup Completo + Validação
#  Executar como: rman target /
# =============================================================


--------------------------------------------------
# ETAPA 1 — Configurações da sessão
--------------------------------------------------

# Paralelismo (ajuste conforme CPUs disponíveis)
	CONFIGURE DEVICE TYPE DISK PARALLELISM 2 BACKUP TYPE TO COMPRESSED BACKUPSET;

# Ativar compressão
	CONFIGURE COMPRESSION ALGORITHM 'BASIC';

# Retenção: manter backups dos últimos 7 dias
	CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;  

-------------------------------------------------
# ETAPA 2 — Backup completo com archivelogs
-------------------------------------------------

	BACKUP AS COMPRESSED BACKUPSET TAG 'FULL_BKP' DATABASE PLUS ARCHIVELOG DELETE INPUT; -- Remove archivelogs já copiados, liberando espaço

 ------------------------------------------------
 # ETAPA 3 — Backup do SPFILE e Controlfile
 # (segurança extra — essenciais para recovery)
 ------------------------------------------------

	BACKUP CURRENT CONTROLFILE TAG 'CTL_BKP';
	BACKUP SPFILE TAG 'SPFILE_BKP';
  

-------------------------------------------------
# ETAPA 4 — Simula restore completo (dry run)
# Não restaura nada - apenas confirma que funcionaria
-------------------------------------------------

	RESTORE DATABASE VALIDATE;

-------------------------------------------------
# ETAPA 5 — Relatório final
-------------------------------------------------

	LIST BACKUP SUMMARY;
