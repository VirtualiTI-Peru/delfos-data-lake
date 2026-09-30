DECLARE @Sql VARCHAR(MAX)
DECLARE @dateFormat VARCHAR(14) = '00000000000000'
DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/perscom/Ver=0/', @dateFormat, '/')

SET @SQL = '
	CREATE EXTERNAL TABLE PersCom#NA
	WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
	AS SELECT
		CAST(NULL AS int) AS idSucursal,
		CAST(NULL AS nvarchar(100)) AS desSucursal,
		CAST(NULL AS int) AS idPersonal,
		CAST(NULL AS nvarchar(100)) AS desPersonal,
		CAST(NULL AS int) AS idFuerzaVentas,
		CAST(NULL AS nvarchar(100)) AS desFuerzaVentas,
		CAST(NULL AS nvarchar(100)) AS cargo,
		CAST(NULL AS nvarchar(100)) AS tipoVenta,
		CAST(NULL AS int) AS idPersonalSuperior,
		CAST(NULL AS nvarchar(100)) AS desPersonalSuperior,
		CAST(NULL AS nvarchar(100)) AS domicilio,
		CAST(NULL AS nvarchar(50)) AS telefono,
		CAST(NULL AS datetime) AS fechaNacimiento,
		CAST(NULL AS nvarchar(100)) AS usuarioSistema,
		CAST(NULL AS int) AS idTipoSegmento,
		CAST(NULL AS nvarchar(100)) AS desTipoSegmento,
		CAST(0 AS INT) AS Ver'
EXEC (@SQL)
DROP EXTERNAL TABLE PersCom#NA

IF NOT EXISTS (SELECT 1 FROM sys.external_tables WHERE object_id = OBJECT_ID('silver.PersCom'))
	CREATE EXTERNAL TABLE silver.PersCom (
		idSucursal int,
		desSucursal nvarchar(100),
		idPersonal int,
		desPersonal nvarchar(100),
		idFuerzaVentas int,
		desFuerzaVentas nvarchar(100),
		cargo nvarchar(100),
		tipoVenta nvarchar(100),
		idPersonalSuperior int,
		desPersonalSuperior nvarchar(100),
		domicilio nvarchar(100),
		telefono nvarchar(50),
		fechaNacimiento datetime,
		usuarioSistema nvarchar(100),
		idTipoSegmento int,
		desTipoSegmento nvarchar(100),
		Ver INT)
	WITH (LOCATION = 'chess/parquet_files/perscom/Ver=*/*/*.parquet', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
