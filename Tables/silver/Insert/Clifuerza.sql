CREATE OR ALTER PROCEDURE silver.spClifuerza_Insert
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay nuevos datos para añadir'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	DECLARE @TableName VARCHAR(100) = CONCAT('Clifuerza', @dateFormat)

	-- Clave idSucursal + idCliente + idFuerzaVentas + idRuta.
	-- Si bronze repite la clave, queda una fila (prioriza anulado = 0).
	-- Las fechas de bronze son nvarchar (dd/mm/yyyy, con hora opcional, o yyyy-mm-dd);
	-- el CETAS las escribe como datetime. Un valor no reconocible queda NULL.
	-- No usar #temp: serverless no lo admite en el mismo plan que una external table.
	IF EXISTS (
		SELECT TOP 1 1
		FROM (
			SELECT
				B.idSucursal,
				B.idCliente,
				B.idFuerzaVentas,
				B.idRuta,
				ROW_NUMBER() OVER (
					PARTITION BY B.idSucursal, B.idCliente, B.idFuerzaVentas, B.idRuta
					ORDER BY ISNULL(B.anulado, 0),
						COALESCE(
							TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaInicioFuerza)), ''), 103),
							TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaInicioFuerza, 10))), ''), 103),
							TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaInicioFuerza)), 'T', ' '), ''), 120)
						) DESC
				) AS rn
			FROM bronze.EClifuerza B
		) T1
		LEFT JOIN gold.Clifuerza T2
			ON T2.idSucursal = T1.idSucursal
			AND T2.idCliente = T1.idCliente
			AND T2.idFuerzaVentas = T1.idFuerzaVentas
			AND T2.idRuta = T1.idRuta
		WHERE T1.rn = 1 AND T2.idCliente IS NULL
	)
	BEGIN
		SET @Version = ISNULL((SELECT MAX(CAST(result.filepath(1) AS INT)) FROM OPENROWSET(
			BULK 'chess/parquet_files/clifuerza/Ver=*/*/*.parquet', DATA_SOURCE = 'eds_delfos', FORMAT = 'PARQUET') AS result), 0) + 1
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/clifuerza/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SELECT @RowsAffected = COUNT(*)
			FROM (
				SELECT
					B.idSucursal,
					B.idCliente,
					B.idFuerzaVentas,
					B.idRuta,
					ROW_NUMBER() OVER (
						PARTITION BY B.idSucursal, B.idCliente, B.idFuerzaVentas, B.idRuta
						ORDER BY ISNULL(B.anulado, 0),
							COALESCE(
								TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaInicioFuerza)), ''), 103),
								TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaInicioFuerza, 10))), ''), 103),
								TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaInicioFuerza)), 'T', ' '), ''), 120)
							) DESC
					) AS rn
				FROM bronze.EClifuerza B
			) T1
			LEFT JOIN gold.Clifuerza T2
				ON T2.idSucursal = T1.idSucursal
				AND T2.idCliente = T1.idCliente
				AND T2.idFuerzaVentas = T1.idFuerzaVentas
				AND T2.idRuta = T1.idRuta
			WHERE T1.rn = 1 AND T2.idCliente IS NULL

			SET @SQL = 'CREATE EXTERNAL TABLE ' + @TableName + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
				SELECT
					T1.idSucursal, T1.idCliente, T1.idFuerzaVentas, T1.desFuerzaVenta,
					T1.idModoAtencion, T1.desModoAtencion,
					CAST(T1.fechaInicioFuerza AS datetime) AS fechaInicioFuerza,
					CAST(T1.fechaFinFuerza AS datetime) AS fechaFinFuerza,
					T1.idRuta,
					CAST(T1.fechaRutaVenta AS datetime) AS fechaRutaVenta,
					T1.anulado,
					T1.periodicidadVisita, T1.semanaVisita, T1.diasVisita, T1.intercalacionVisita,
					T1.perioricidadEntrega, T1.semanaEntrega, T1.diasEntrega, T1.intercalacionEntrega,
					T1.Horarios,
					' + CAST(@Version AS VARCHAR(10)) + ' AS Ver
				FROM (
					SELECT
						S.idSucursal, S.idCliente, S.idFuerzaVentas, S.desFuerzaVenta,
						S.idModoAtencion, S.desModoAtencion, S.fechaInicioFuerza, S.fechaFinFuerza,
						S.idRuta, S.fechaRutaVenta, S.anulado,
						S.periodicidadVisita, S.semanaVisita, S.diasVisita, S.intercalacionVisita,
						S.perioricidadEntrega, S.semanaEntrega, S.diasEntrega, S.intercalacionEntrega,
						S.Horarios,
						ROW_NUMBER() OVER (
							PARTITION BY S.idSucursal, S.idCliente, S.idFuerzaVentas, S.idRuta
							ORDER BY ISNULL(S.anulado, 0), S.fechaInicioFuerza DESC
						) AS rn
					FROM (
						SELECT
							B.idSucursal, B.idCliente, B.idFuerzaVentas, B.desFuerzaVenta,
							B.idModoAtencion, B.desModoAtencion,
							COALESCE(
								TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaInicioFuerza)), ''''), 103),
								TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaInicioFuerza, 10))), ''''), 103),
								TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaInicioFuerza)), ''T'', '' ''), ''''), 120)
							) AS fechaInicioFuerza,
							COALESCE(
								TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaFinFuerza)), ''''), 103),
								TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaFinFuerza, 10))), ''''), 103),
								TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaFinFuerza)), ''T'', '' ''), ''''), 120)
							) AS fechaFinFuerza,
							B.idRuta,
							COALESCE(
								TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaRutaVenta)), ''''), 103),
								TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaRutaVenta, 10))), ''''), 103),
								TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaRutaVenta)), ''T'', '' ''), ''''), 120)
							) AS fechaRutaVenta,
							B.anulado,
							B.periodicidadVisita, B.semanaVisita, B.diasVisita, B.intercalacionVisita,
							B.perioricidadEntrega, B.semanaEntrega, B.diasEntrega, B.intercalacionEntrega,
							B.Horarios
						FROM bronze.EClifuerza B
					) S
				) T1
				LEFT JOIN gold.Clifuerza T2
					ON T2.idSucursal = T1.idSucursal
					AND T2.idCliente = T1.idCliente
					AND T2.idFuerzaVentas = T1.idFuerzaVentas
					AND T2.idRuta = T1.idRuta
				WHERE T1.rn = 1 AND T2.idCliente IS NULL'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Datos insertados correctamente (', @RowsAffected, ' filas)')
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END
	SELECT @StartDateProc, GETDATE(), 'silver.spClifuerza_Insert' AS ProcedureName, @ResultMessage AS LogMessage
END
