DECLARE @Sql VARCHAR(MAX)
DECLARE @dateFormat VARCHAR(14) = '00000000000000'
DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/clientesruta/Ver=0/', @dateFormat, '/')

-- idRuta no viene en el CSV: se resuelve en Insert/Update contra bronze.ERutasVenta.
-- anulado no viene en el CSV: lo escribe Anular cuando la asignacion desaparece del snapshot.
SET @SQL = '
	CREATE EXTERNAL TABLE ClientesRuta#NA
	WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
	AS SELECT
		CAST(NULL AS int) AS idCliente,
		CAST(NULL AS nvarchar(100)) AS razonSocial,
		CAST(NULL AS int) AS intercalacionVisita,
		CAST(NULL AS int) AS intercalacionEntrega,
		CAST(NULL AS int) AS idRuta,
		CAST(NULL AS bit) AS anulado,
		CAST(0 AS INT) AS Ver'
EXEC (@SQL)
DROP EXTERNAL TABLE ClientesRuta#NA

IF NOT EXISTS (SELECT 1 FROM sys.external_tables WHERE object_id = OBJECT_ID('silver.ClientesRuta'))
	CREATE EXTERNAL TABLE silver.ClientesRuta (
		idCliente int,
		razonSocial nvarchar(100),
		intercalacionVisita int,
		intercalacionEntrega int,
		idRuta int,
		anulado bit,
		Ver INT)
	WITH (LOCATION = 'chess/parquet_files/clientesruta/Ver=*/*/*.parquet', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet)
