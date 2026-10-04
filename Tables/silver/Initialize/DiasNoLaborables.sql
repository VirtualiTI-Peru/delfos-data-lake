DECLARE @Sql VARCHAR(MAX)
DECLARE @dateFormat VARCHAR(14) = '00000000000000'
DECLARE @folderName VARCHAR(150) = CONCAT('/chess/parquet_files/diasnolaborables/Ver=0/', @dateFormat, '/')

SET @SQL = '
	CREATE EXTERNAL TABLE DiasNoLaborables#NA
	WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
	AS SELECT
		CAST(NULL AS nchar(10)) AS fecha,
		CAST(NULL AS nvarchar(20)) AS tipo,
		CAST(NULL AS nvarchar(200)) AS descripcion,
		CAST(NULL AS int) AS [Year],
		CAST(NULL AS int) AS [Month],
		CAST(NULL AS bit) AS anulado,
		CAST(0 AS INT) AS Ver'
EXEC (@SQL)
DROP EXTERNAL TABLE DiasNoLaborables#NA

IF NOT EXISTS (SELECT 1 FROM sys.external_tables WHERE object_id = OBJECT_ID('silver.DiasNoLaborables'))
	CREATE EXTERNAL TABLE silver.DiasNoLaborables (
		fecha nchar(10),
		tipo nvarchar(20),
		descripcion nvarchar(200),
		[Year] int,
		[Month] int,
		anulado bit,
		Ver int)
	WITH (
		LOCATION = 'chess/parquet_files/diasnolaborables/Ver=*/*/*.parquet',
		DATA_SOURCE = eds_delfos,
		FILE_FORMAT = eff_delfos_parquet)
