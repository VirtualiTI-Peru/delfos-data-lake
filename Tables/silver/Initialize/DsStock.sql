DECLARE @Sql VARCHAR(MAX)
DECLARE @Version INT = 0
DECLARE @dateFormat VARCHAR(14) = '00000000000000'
DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/dsstock/Ver=0/', @dateFormat, '/')

SET @SQL = '
	CREATE EXTERNAL TABLE DsStock#NA
	WITH (
		LOCATION = ''' + @folderName + ''',
		DATA_SOURCE = eds_delfos,
		FILE_FORMAT = eff_delfos_parquet
	)
	AS
	SELECT
		CAST(NULL AS datetime) AS fecha,
		CAST(NULL AS int) AS idDeposito,
		CAST(NULL AS int) AS idAlmacen,
		CAST(NULL AS int) AS idArticulo,
		CAST(NULL AS nvarchar(100)) AS dsArticulo,
		CAST(NULL AS datetime) AS fecVtoLote,
		CAST(NULL AS int) AS cantBultos,
		CAST(NULL AS int) AS cantUnidades,
		CAST(0 AS INT) AS Ver'
EXEC (@SQL)

DROP EXTERNAL TABLE DsStock#NA

IF NOT EXISTS (SELECT 1 FROM sys.external_tables WHERE object_id = OBJECT_ID('silver.DsStock'))
BEGIN
	CREATE EXTERNAL TABLE silver.DsStock (
		fecha datetime,
		idDeposito int,
		idAlmacen int,
		idArticulo int,
		dsArticulo nvarchar(100),
		fecVtoLote datetime,
		cantBultos int,
		cantUnidades int,
		Ver INT)
	WITH (
		LOCATION = 'chess/parquet_files/dsstock/Ver=*/*/*.parquet',
		DATA_SOURCE = eds_delfos,
		FILE_FORMAT = eff_delfos_parquet
	)
END
