DECLARE @Sql VARCHAR(MAX)
DECLARE @dateFormat VARCHAR(14) = '00000000000000'
DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/clifuerza/Ver=0/', @dateFormat, '/')

-- Clave idSucursal + idCliente + idFuerzaVentas + idRuta.
-- perioricidadEntrega conserva el nombre que envia Chess.
SET @SQL = '
	CREATE EXTERNAL TABLE Clifuerza#NA
	WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
	AS SELECT
		CAST(NULL AS int) AS idSucursal,
		CAST(NULL AS int) AS idCliente,
		CAST(NULL AS int) AS idFuerzaVentas,
		CAST(NULL AS nvarchar(100)) AS desFuerzaVenta,
		CAST(NULL AS nvarchar(100)) AS idModoAtencion,
		CAST(NULL AS nvarchar(100)) AS desModoAtencion,
		CAST(NULL AS datetime) AS fechaInicioFuerza,
		CAST(NULL AS datetime) AS fechaFinFuerza,
		CAST(NULL AS int) AS idRuta,
		CAST(NULL AS datetime) AS fechaRutaVenta,
		CAST(NULL AS bit) AS anulado,
		CAST(NULL AS int) AS periodicidadVisita,
		CAST(NULL AS int) AS semanaVisita,
		CAST(NULL AS nvarchar(100)) AS diasVisita,
		CAST(NULL AS int) AS intercalacionVisita,
		CAST(NULL AS int) AS perioricidadEntrega,
		CAST(NULL AS int) AS semanaEntrega,
		CAST(NULL AS nvarchar(100)) AS diasEntrega,
		CAST(NULL AS int) AS intercalacionEntrega,
		CAST(NULL AS nvarchar(100)) AS Horarios,
		CAST(0 AS INT) AS Ver'
EXEC (@SQL)
DROP EXTERNAL TABLE Clifuerza#NA

IF NOT EXISTS (SELECT 1 FROM sys.external_tables WHERE object_id = OBJECT_ID('silver.Clifuerza'))
	CREATE EXTERNAL TABLE silver.Clifuerza (
		idSucursal int,
		idCliente int,
		idFuerzaVentas int,
		desFuerzaVenta nvarchar(100),
		idModoAtencion nvarchar(100),
		desModoAtencion nvarchar(100),
		fechaInicioFuerza datetime,
		fechaFinFuerza datetime,
		idRuta int,
		fechaRutaVenta datetime,
		anulado bit,
		periodicidadVisita int,
		semanaVisita int,
		diasVisita nvarchar(100),
		intercalacionVisita int,
		perioricidadEntrega int,
		semanaEntrega int,
		diasEntrega nvarchar(100),
		intercalacionEntrega int,
		Horarios nvarchar(100),
		Ver INT)
	WITH (LOCATION = 'chess/parquet_files/clifuerza/Ver=*/*/*.parquet', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
