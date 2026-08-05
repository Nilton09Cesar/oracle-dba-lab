
-- 1. Tablespace SEM Autoextend (Tamanho fixo de 200MB)
CREATE TABLESPACE tbs_fixa DATAFILE SIZE 200M AUTOEXTEND OFF;

-- 2. Tablespace COM Autoextend (Começa com 40MB, cresce de 20MB em 20MB até 200MB)
CREATE TABLESPACE tbs_auto DATAFILE SIZE 40M 
AUTOEXTEND ON NEXT 20M MAXSIZE 200M;

$ vim tablespace_report.sql

SET SQLBLANKLINES ON;
SET LINESIZE 200;
SET PAGESIZE 100;

WITH datafiles AS (
    SELECT
        tablespace_name,
        SUM(bytes) AS bytes_alloc,
        SUM(
            CASE
                WHEN autoextensible = 'YES'
                 AND maxbytes > bytes
                THEN maxbytes
                ELSE bytes
            END
        ) AS bytes_capacity,
        CASE
            WHEN MIN(autoextensible) = 'YES'
             AND MAX(autoextensible) = 'YES'
            THEN 'YES'
            WHEN MIN(autoextensible) = 'NO'
             AND MAX(autoextensible) = 'NO'
            THEN 'NO'
            ELSE 'MIXED'
        END AS autoext
    FROM dba_data_files
    GROUP BY tablespace_name
),
free_space AS (
    SELECT
        tablespace_name,
        SUM(bytes) AS bytes_free
    FROM dba_free_space
    GROUP BY tablespace_name
)
SELECT
    df.tablespace_name AS tablespace,
    df.autoext AS autoext,
    ROUND(df.bytes_alloc / POWER(1024,2),2) AS alloc_mb,
    ROUND(df.bytes_capacity / POWER(1024,2),2) AS max_mb,
    ROUND(
        (df.bytes_alloc - NVL(fs.bytes_free,0))
        / POWER(1024,2),
        2
    ) AS used_mb,
    ROUND(
        NVL(fs.bytes_free,0)
        / POWER(1024,2),
        2
    ) AS free_mb,
    ROUND(
        (df.bytes_alloc - NVL(fs.bytes_free,0))
        * 100
        / NULLIF(df.bytes_alloc,0),
        2
    ) AS %ALLOC,
    ROUND(
        (df.bytes_alloc - NVL(fs.bytes_free,0))
        * 100
        / NULLIF(df.bytes_capacity,0),
        2
    ) AS %MAX,
    ROUND(
        (
            df.bytes_capacity
            - (df.bytes_alloc - NVL(fs.bytes_free,0))
        )
        / POWER(1024,2),
        2
    ) AS disp_mb
FROM datafiles df
LEFT JOIN free_space fs
       ON df.tablespace_name = fs.tablespace_name
ORDER BY %MAX DESC;


SQL > @tablespace_report.sql
