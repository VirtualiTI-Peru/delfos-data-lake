DECLARE @Sql VARCHAR(MAX)
DECLARE @dateFormat VARCHAR(14) = '00000000000000'
DECLARE @folderName VARCHAR(150) = CONCAT('/chess/parquet_files/cuotacobertura/Ver=0/', @dateFormat, '/')

SET @SQL = '
	CREATE EXTERNAL TABLE CuotaCobertura#NA
	WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
	AS SELECT
		CAST(NULL AS int) AS idSucursal,
		CAST(NULL AS int) AS idPersonal,
		CAST(NULL AS nchar(7)) AS periodo,
		CAST(NULL AS decimal(18, 2)) AS cuota_calculada,
		CAST(NULL AS decimal(18, 2)) AS cuota,
		CAST(NULL AS int) AS [Year],
		CAST(NULL AS int) AS [Month],
		CAST(0 AS INT) AS Ver'
EXEC (@SQL)
DROP EXTERNAL TABLE CuotaCobertura#NA

IF NOT EXISTS (SELECT 1 FROM sys.external_tables WHERE object_id = OBJECT_ID('silver.CuotaCobertura'))
	CREATE EXTERNAL TABLE silver.CuotaCobertura (
		idSucursal int,
		idPersonal int,
		periodo nchar(7),
		cuota_calculada decimal(18, 2),
		cuota decimal(18, 2),
		[Year] int,
		[Month] int,
		Ver int)
	WITH (
		LOCATION = 'chess/parquet_files/cuotacobertura/Ver=*/*/*.parquet',
		DATA_SOURCE = eds_delfos,
		FILE_FORMAT = eff_delfos_parquet)
