DECLARE @Sql VARCHAR(MAX)
DECLARE @dateFormat VARCHAR(14) = '00000000000000'
DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/canalesmkt/Ver=0/', @dateFormat, '/')

SET @SQL = '
	CREATE EXTERNAL TABLE CanalesMkt#NA
	WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
	AS SELECT CAST(NULL AS int) AS idCanalMkt, CAST(NULL AS nvarchar(100)) AS desCanalMkt,
	CAST(NULL AS int) AS idSegmentoMkt, CAST(NULL AS bit) AS compania, CAST(0 AS INT) AS Ver'
EXEC (@SQL)
DROP EXTERNAL TABLE CanalesMkt#NA

IF NOT EXISTS (SELECT 1 FROM sys.external_tables WHERE object_id = OBJECT_ID('silver.CanalesMkt'))
	CREATE EXTERNAL TABLE silver.CanalesMkt (
		idCanalMkt int, desCanalMkt nvarchar(100), idSegmentoMkt int, compania bit, Ver INT)
	WITH (LOCATION = 'chess/parquet_files/canalesmkt/Ver=*/*/*.parquet', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
