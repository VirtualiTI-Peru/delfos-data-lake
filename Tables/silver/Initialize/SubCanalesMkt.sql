DECLARE @Sql VARCHAR(MAX)
DECLARE @dateFormat VARCHAR(14) = '00000000000000'
DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/subcanalesmkt/Ver=0/', @dateFormat, '/')

SET @SQL = '
	CREATE EXTERNAL TABLE SubCanalesMkt#NA
	WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
	AS SELECT CAST(NULL AS int) AS idSubcanalMkt, CAST(NULL AS nvarchar(100)) AS desSubcanalMkt,
	CAST(NULL AS int) AS idCanalMkt, CAST(NULL AS bit) AS compania, CAST(0 AS INT) AS Ver'
EXEC (@SQL)
DROP EXTERNAL TABLE SubCanalesMkt#NA

IF NOT EXISTS (SELECT 1 FROM sys.external_tables WHERE object_id = OBJECT_ID('silver.SubCanalesMkt'))
	CREATE EXTERNAL TABLE silver.SubCanalesMkt (
		idSubcanalMkt int, desSubcanalMkt nvarchar(100), idCanalMkt int, compania bit, Ver INT)
	WITH (LOCATION = 'chess/parquet_files/subcanalesmkt/Ver=*/*/*.parquet', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
