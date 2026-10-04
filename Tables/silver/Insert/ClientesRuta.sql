CREATE OR ALTER PROCEDURE silver.spClientesRuta_Insert
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay nuevos datos para añadir'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	DECLARE @TableName VARCHAR(100) = CONCAT('ClientesRuta', @dateFormat)

	-- Clave idCliente + idRuta. Una fila por clave. idRuta sale de bronze.ERutasVenta
	-- por IdRutaAuto de la misma extraccion (ese GUID no es estable).
	IF EXISTS (
		SELECT TOP 1 1
		FROM (
			SELECT
				C.idCliente,
				R.idRuta,
				ROW_NUMBER() OVER (
					PARTITION BY C.idCliente, R.idRuta
					ORDER BY ISNULL(C.intercalacionVisita, 0), ISNULL(C.intercalacionEntrega, 0), ISNULL(C.razonSocial, '')
				) AS rn
			FROM bronze.EClientesRuta C
			INNER JOIN (
				SELECT
					IdRutaAuto,
					idRuta,
					ROW_NUMBER() OVER (PARTITION BY IdRutaAuto ORDER BY ISNULL(anulado, 0), idSucursal, idPersonal) AS rn
				FROM bronze.ERutasVenta
			) R ON R.IdRutaAuto = C.IdRutaAuto AND R.rn = 1
		) T1
		LEFT JOIN gold.ClientesRuta T2 ON T2.idCliente = T1.idCliente AND T2.idRuta = T1.idRuta
		WHERE T1.rn = 1 AND T2.idCliente IS NULL
	)
	BEGIN
		SET @Version = ISNULL((SELECT MAX(CAST(result.filepath(1) AS INT)) FROM OPENROWSET(
			BULK 'chess/parquet_files/clientesruta/Ver=*/*/*.parquet', DATA_SOURCE = 'eds_delfos', FORMAT = 'PARQUET') AS result), 0) + 1
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/clientesruta/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SELECT @RowsAffected = COUNT(*)
			FROM (
				SELECT
					C.idCliente,
					R.idRuta,
					ROW_NUMBER() OVER (
						PARTITION BY C.idCliente, R.idRuta
						ORDER BY ISNULL(C.intercalacionVisita, 0), ISNULL(C.intercalacionEntrega, 0), ISNULL(C.razonSocial, '')
					) AS rn
				FROM bronze.EClientesRuta C
				INNER JOIN (
					SELECT
						IdRutaAuto,
						idRuta,
						ROW_NUMBER() OVER (PARTITION BY IdRutaAuto ORDER BY ISNULL(anulado, 0), idSucursal, idPersonal) AS rn
					FROM bronze.ERutasVenta
				) R ON R.IdRutaAuto = C.IdRutaAuto AND R.rn = 1
			) T1
			LEFT JOIN gold.ClientesRuta T2 ON T2.idCliente = T1.idCliente AND T2.idRuta = T1.idRuta
			WHERE T1.rn = 1 AND T2.idCliente IS NULL

			SET @SQL = 'CREATE EXTERNAL TABLE ' + @TableName + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
				SELECT
					CAST(T1.idCliente AS int) AS idCliente,
					CAST(T1.razonSocial AS nvarchar(100)) AS razonSocial,
					CAST(T1.intercalacionVisita AS int) AS intercalacionVisita,
					CAST(T1.intercalacionEntrega AS int) AS intercalacionEntrega,
					CAST(T1.idRuta AS int) AS idRuta,
					CAST(0 AS bit) AS anulado,
					CAST(' + CAST(@Version AS VARCHAR(10)) + ' AS int) AS Ver
				FROM (
					SELECT
						C.idCliente,
						C.razonSocial,
						C.intercalacionVisita,
						C.intercalacionEntrega,
						R.idRuta,
						ROW_NUMBER() OVER (
							PARTITION BY C.idCliente, R.idRuta
							ORDER BY ISNULL(C.intercalacionVisita, 0), ISNULL(C.intercalacionEntrega, 0), ISNULL(C.razonSocial, '''')
						) AS rn
					FROM bronze.EClientesRuta C
					INNER JOIN (
						SELECT
							IdRutaAuto,
							idRuta,
							ROW_NUMBER() OVER (PARTITION BY IdRutaAuto ORDER BY ISNULL(anulado, 0), idSucursal, idPersonal) AS rn
						FROM bronze.ERutasVenta
					) R ON R.IdRutaAuto = C.IdRutaAuto AND R.rn = 1
				) T1
				LEFT JOIN gold.ClientesRuta T2 ON T2.idCliente = T1.idCliente AND T2.idRuta = T1.idRuta
				WHERE T1.rn = 1 AND T2.idCliente IS NULL'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Datos insertados correctamente (', @RowsAffected, ' filas)')
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END
	SELECT @StartDateProc, GETDATE(), 'silver.spClientesRuta_Insert' AS ProcedureName, @ResultMessage AS LogMessage
END
