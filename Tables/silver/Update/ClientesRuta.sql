CREATE OR ALTER PROCEDURE silver.spClientesRuta_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @TableName VARCHAR(100)
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	SET @TableName = CONCAT('clientesruta', @dateFormat)

	-- Clave idCliente + idRuta. La fila canonica es la misma que usa gold (intercalacion, razon social).
	-- anulado = 1 se reactiva; anulado 0 o NULL no es un cambio.
	IF EXISTS (
		SELECT TOP 1 1
		FROM (
			SELECT
				C.idCliente,
				C.razonSocial,
				C.intercalacionVisita,
				C.intercalacionEntrega,
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
		WHERE T1.rn = 1
		AND EXISTS (
			SELECT 1
			FROM gold.ClientesRuta T2
			WHERE T2.idCliente = T1.idCliente
			  AND T2.idRuta = T1.idRuta
			  AND (
					ISNULL(T1.razonSocial, '') <> ISNULL(T2.razonSocial, '')
					OR ISNULL(T1.intercalacionVisita, 0) <> ISNULL(T2.intercalacionVisita, 0)
					OR ISNULL(T1.intercalacionEntrega, 0) <> ISNULL(T2.intercalacionEntrega, 0)
					OR ISNULL(T2.anulado, 0) = 1
			  )
		)
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
					C.razonSocial,
					C.intercalacionVisita,
					C.intercalacionEntrega,
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
			WHERE T1.rn = 1
			AND EXISTS (
				SELECT 1
				FROM gold.ClientesRuta T2
				WHERE T2.idCliente = T1.idCliente
				  AND T2.idRuta = T1.idRuta
				  AND (
						ISNULL(T1.razonSocial, '') <> ISNULL(T2.razonSocial, '')
						OR ISNULL(T1.intercalacionVisita, 0) <> ISNULL(T2.intercalacionVisita, 0)
						OR ISNULL(T1.intercalacionEntrega, 0) <> ISNULL(T2.intercalacionEntrega, 0)
						OR ISNULL(T2.anulado, 0) = 1
				  )
			)

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
				WHERE T1.rn = 1
				AND EXISTS (
					SELECT 1
					FROM gold.ClientesRuta T2
					WHERE T2.idCliente = T1.idCliente
					  AND T2.idRuta = T1.idRuta
					  AND (
							ISNULL(T1.razonSocial, '''') <> ISNULL(T2.razonSocial, '''')
							OR ISNULL(T1.intercalacionVisita, 0) <> ISNULL(T2.intercalacionVisita, 0)
							OR ISNULL(T1.intercalacionEntrega, 0) <> ISNULL(T2.intercalacionEntrega, 0)
							OR ISNULL(T2.anulado, 0) = 1
					  )
				)'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Datos actualizados correctamente (', @RowsAffected, ' filas)')
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END
	SELECT @StartDateProc, GETDATE(), 'silver.spClientesRuta_Update' AS ProcedureName, @ResultMessage AS LogMessage
END
