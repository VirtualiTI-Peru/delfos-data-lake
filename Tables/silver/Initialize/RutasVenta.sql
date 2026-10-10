DECLARE @Sql VARCHAR(MAX)
DECLARE @dateFormat VARCHAR(14) = '00000000000000'
DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/rutasventa/Ver=0/', @dateFormat, '/')

SET @SQL = '
	CREATE EXTERNAL TABLE RutasVenta#NA
	WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
	AS SELECT
		CAST(NULL AS int) AS idSucursal,
		CAST(NULL AS nvarchar(100)) AS desSucursal,
		CAST(NULL AS int) AS idFuerzaVentas,
		CAST(NULL AS nvarchar(100)) AS desFuerzaVentas,
		CAST(NULL AS nvarchar(50)) AS idModoAtencion,
		CAST(NULL AS nvarchar(100)) AS desModoAtencion,
		CAST(NULL AS int) AS idRuta,
		CAST(NULL AS nvarchar(100)) AS desRuta,
		CAST(NULL AS datetime) AS fechaDesde,
		CAST(NULL AS datetime) AS fechaHasta,
		CAST(NULL AS bit) AS anulado,
		CAST(NULL AS int) AS idPersonal,
		CAST(NULL AS nvarchar(100)) AS desPersonal,
		CAST(NULL AS int) AS periodicidadVisita,
		CAST(NULL AS int) AS semanaVisita,
		CAST(NULL AS nvarchar(50)) AS diasVisita,
		CAST(NULL AS int) AS periodicidadEntrega,
		CAST(NULL AS int) AS semanaEntrega,
		CAST(NULL AS nvarchar(50)) AS diasEntrega,
		CAST(NULL AS uniqueidentifier) AS IdRutaAuto,
		CAST(0 AS INT) AS Ver'
EXEC (@SQL)
DROP EXTERNAL TABLE RutasVenta#NA

IF NOT EXISTS (SELECT 1 FROM sys.external_tables WHERE object_id = OBJECT_ID('silver.RutasVenta'))
	CREATE EXTERNAL TABLE silver.RutasVenta (
		idSucursal int,
		desSucursal nvarchar(100),
		idFuerzaVentas int,
		desFuerzaVentas nvarchar(100),
		idModoAtencion nvarchar(50),
		desModoAtencion nvarchar(100),
		idRuta int,
		desRuta nvarchar(100),
		fechaDesde datetime,
		fechaHasta datetime,
		anulado bit,
		idPersonal int,
		desPersonal nvarchar(100),
		periodicidadVisita int,
		semanaVisita int,
		diasVisita nvarchar(50),
		periodicidadEntrega int,
		semanaEntrega int,
		diasEntrega nvarchar(50),
		IdRutaAuto uniqueidentifier,
		Ver INT)
	WITH (LOCATION = 'chess/parquet_files/rutasventa/Ver=*/*/*.parquet', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
