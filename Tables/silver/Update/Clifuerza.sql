CREATE OR ALTER PROCEDURE silver.spClifuerza_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @TableName VARCHAR(100)
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	SET @TableName = CONCAT('clifuerza', @dateFormat)

	-- Clave idSucursal + idCliente + idFuerzaVentas + idRuta. Una fila por clave.
	-- Las fechas de bronze son nvarchar; se comparan y se escriben como datetime.
	-- No usar #temp: serverless no lo admite en el mismo plan que una external table.
	IF EXISTS (
		SELECT TOP 1 1
		FROM (
			SELECT
				S.*,
				ROW_NUMBER() OVER (
					PARTITION BY S.idSucursal, S.idCliente, S.idFuerzaVentas, S.idRuta
					ORDER BY ISNULL(S.anulado, 0), S.fechaInicioFuerza DESC
				) AS rn
			FROM (
				SELECT
					B.idSucursal, B.idCliente, B.idFuerzaVentas, B.desFuerzaVenta,
					B.idModoAtencion, B.desModoAtencion,
					COALESCE(
						TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaInicioFuerza)), ''), 103),
						TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaInicioFuerza, 10))), ''), 103),
						TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaInicioFuerza)), 'T', ' '), ''), 120)
					) AS fechaInicioFuerza,
					COALESCE(
						TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaFinFuerza)), ''), 103),
						TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaFinFuerza, 10))), ''), 103),
						TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaFinFuerza)), 'T', ' '), ''), 120)
					) AS fechaFinFuerza,
					B.idRuta,
					COALESCE(
						TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaRutaVenta)), ''), 103),
						TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaRutaVenta, 10))), ''), 103),
						TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaRutaVenta)), 'T', ' '), ''), 120)
					) AS fechaRutaVenta,
					B.anulado,
					B.periodicidadVisita, B.semanaVisita, B.diasVisita, B.intercalacionVisita,
					B.perioricidadEntrega, B.semanaEntrega, B.diasEntrega, B.intercalacionEntrega,
					B.Horarios
				FROM bronze.EClifuerza B
			) S
		) T1
		WHERE T1.rn = 1
		AND EXISTS (
			SELECT 1
			FROM gold.Clifuerza T2
			WHERE T2.idSucursal = T1.idSucursal
			  AND T2.idCliente = T1.idCliente
			  AND T2.idFuerzaVentas = T1.idFuerzaVentas
			  AND T2.idRuta = T1.idRuta
			  AND (
					ISNULL(T1.desFuerzaVenta, '') <> ISNULL(T2.desFuerzaVenta, '')
					OR ISNULL(T1.idModoAtencion, '') <> ISNULL(T2.idModoAtencion, '')
					OR ISNULL(T1.desModoAtencion, '') <> ISNULL(T2.desModoAtencion, '')
					OR NOT (
						T1.fechaInicioFuerza = T2.fechaInicioFuerza
						OR (T1.fechaInicioFuerza IS NULL AND T2.fechaInicioFuerza IS NULL)
					)
					OR NOT (
						T1.fechaFinFuerza = T2.fechaFinFuerza
						OR (T1.fechaFinFuerza IS NULL AND T2.fechaFinFuerza IS NULL)
					)
					OR NOT (
						T1.fechaRutaVenta = T2.fechaRutaVenta
						OR (T1.fechaRutaVenta IS NULL AND T2.fechaRutaVenta IS NULL)
					)
					OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
					OR ISNULL(T1.periodicidadVisita, 0) <> ISNULL(T2.periodicidadVisita, 0)
					OR ISNULL(T1.semanaVisita, 0) <> ISNULL(T2.semanaVisita, 0)
					OR ISNULL(T1.diasVisita, '') <> ISNULL(T2.diasVisita, '')
					OR ISNULL(T1.intercalacionVisita, 0) <> ISNULL(T2.intercalacionVisita, 0)
					OR ISNULL(T1.perioricidadEntrega, 0) <> ISNULL(T2.perioricidadEntrega, 0)
					OR ISNULL(T1.semanaEntrega, 0) <> ISNULL(T2.semanaEntrega, 0)
					OR ISNULL(T1.diasEntrega, '') <> ISNULL(T2.diasEntrega, '')
					OR ISNULL(T1.intercalacionEntrega, 0) <> ISNULL(T2.intercalacionEntrega, 0)
					OR ISNULL(T1.Horarios, '') <> ISNULL(T2.Horarios, '')
			  )
		)
	)
	BEGIN
		SET @Version = ISNULL((SELECT MAX(CAST(result.filepath(1) AS INT)) FROM OPENROWSET(
			BULK 'chess/parquet_files/clifuerza/Ver=*/*/*.parquet', DATA_SOURCE = 'eds_delfos', FORMAT = 'PARQUET') AS result), 0) + 1
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/clifuerza/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SELECT @RowsAffected = COUNT(*)
			FROM (
				SELECT
					S.*,
					ROW_NUMBER() OVER (
						PARTITION BY S.idSucursal, S.idCliente, S.idFuerzaVentas, S.idRuta
						ORDER BY ISNULL(S.anulado, 0), S.fechaInicioFuerza DESC
					) AS rn
				FROM (
					SELECT
						B.idSucursal, B.idCliente, B.idFuerzaVentas, B.desFuerzaVenta,
						B.idModoAtencion, B.desModoAtencion,
						COALESCE(
							TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaInicioFuerza)), ''), 103),
							TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaInicioFuerza, 10))), ''), 103),
							TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaInicioFuerza)), 'T', ' '), ''), 120)
						) AS fechaInicioFuerza,
						COALESCE(
							TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaFinFuerza)), ''), 103),
							TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaFinFuerza, 10))), ''), 103),
							TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaFinFuerza)), 'T', ' '), ''), 120)
						) AS fechaFinFuerza,
						B.idRuta,
						COALESCE(
							TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaRutaVenta)), ''), 103),
							TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaRutaVenta, 10))), ''), 103),
							TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaRutaVenta)), 'T', ' '), ''), 120)
						) AS fechaRutaVenta,
						B.anulado,
						B.periodicidadVisita, B.semanaVisita, B.diasVisita, B.intercalacionVisita,
						B.perioricidadEntrega, B.semanaEntrega, B.diasEntrega, B.intercalacionEntrega,
						B.Horarios
					FROM bronze.EClifuerza B
				) S
			) T1
			WHERE T1.rn = 1
			AND EXISTS (
				SELECT 1
				FROM gold.Clifuerza T2
				WHERE T2.idSucursal = T1.idSucursal
				  AND T2.idCliente = T1.idCliente
				  AND T2.idFuerzaVentas = T1.idFuerzaVentas
				  AND T2.idRuta = T1.idRuta
				  AND (
						ISNULL(T1.desFuerzaVenta, '') <> ISNULL(T2.desFuerzaVenta, '')
						OR ISNULL(T1.idModoAtencion, '') <> ISNULL(T2.idModoAtencion, '')
						OR ISNULL(T1.desModoAtencion, '') <> ISNULL(T2.desModoAtencion, '')
						OR NOT (
							T1.fechaInicioFuerza = T2.fechaInicioFuerza
							OR (T1.fechaInicioFuerza IS NULL AND T2.fechaInicioFuerza IS NULL)
						)
						OR NOT (
							T1.fechaFinFuerza = T2.fechaFinFuerza
							OR (T1.fechaFinFuerza IS NULL AND T2.fechaFinFuerza IS NULL)
						)
						OR NOT (
							T1.fechaRutaVenta = T2.fechaRutaVenta
							OR (T1.fechaRutaVenta IS NULL AND T2.fechaRutaVenta IS NULL)
						)
						OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
						OR ISNULL(T1.periodicidadVisita, 0) <> ISNULL(T2.periodicidadVisita, 0)
						OR ISNULL(T1.semanaVisita, 0) <> ISNULL(T2.semanaVisita, 0)
						OR ISNULL(T1.diasVisita, '') <> ISNULL(T2.diasVisita, '')
						OR ISNULL(T1.intercalacionVisita, 0) <> ISNULL(T2.intercalacionVisita, 0)
						OR ISNULL(T1.perioricidadEntrega, 0) <> ISNULL(T2.perioricidadEntrega, 0)
						OR ISNULL(T1.semanaEntrega, 0) <> ISNULL(T2.semanaEntrega, 0)
						OR ISNULL(T1.diasEntrega, '') <> ISNULL(T2.diasEntrega, '')
						OR ISNULL(T1.intercalacionEntrega, 0) <> ISNULL(T2.intercalacionEntrega, 0)
						OR ISNULL(T1.Horarios, '') <> ISNULL(T2.Horarios, '')
				  )
			)

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
				WHERE T1.rn = 1
				AND EXISTS (
					SELECT 1
					FROM gold.Clifuerza T2
					WHERE T2.idSucursal = T1.idSucursal
					  AND T2.idCliente = T1.idCliente
					  AND T2.idFuerzaVentas = T1.idFuerzaVentas
					  AND T2.idRuta = T1.idRuta
					  AND (
							ISNULL(T1.desFuerzaVenta, '''') <> ISNULL(T2.desFuerzaVenta, '''')
							OR ISNULL(T1.idModoAtencion, '''') <> ISNULL(T2.idModoAtencion, '''')
							OR ISNULL(T1.desModoAtencion, '''') <> ISNULL(T2.desModoAtencion, '''')
							OR NOT (
								T1.fechaInicioFuerza = T2.fechaInicioFuerza
								OR (T1.fechaInicioFuerza IS NULL AND T2.fechaInicioFuerza IS NULL)
							)
							OR NOT (
								T1.fechaFinFuerza = T2.fechaFinFuerza
								OR (T1.fechaFinFuerza IS NULL AND T2.fechaFinFuerza IS NULL)
							)
							OR NOT (
								T1.fechaRutaVenta = T2.fechaRutaVenta
								OR (T1.fechaRutaVenta IS NULL AND T2.fechaRutaVenta IS NULL)
							)
							OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
							OR ISNULL(T1.periodicidadVisita, 0) <> ISNULL(T2.periodicidadVisita, 0)
							OR ISNULL(T1.semanaVisita, 0) <> ISNULL(T2.semanaVisita, 0)
							OR ISNULL(T1.diasVisita, '''') <> ISNULL(T2.diasVisita, '''')
							OR ISNULL(T1.intercalacionVisita, 0) <> ISNULL(T2.intercalacionVisita, 0)
							OR ISNULL(T1.perioricidadEntrega, 0) <> ISNULL(T2.perioricidadEntrega, 0)
							OR ISNULL(T1.semanaEntrega, 0) <> ISNULL(T2.semanaEntrega, 0)
							OR ISNULL(T1.diasEntrega, '''') <> ISNULL(T2.diasEntrega, '''')
							OR ISNULL(T1.intercalacionEntrega, 0) <> ISNULL(T2.intercalacionEntrega, 0)
							OR ISNULL(T1.Horarios, '''') <> ISNULL(T2.Horarios, '''')
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
	SELECT @StartDateProc, GETDATE(), 'silver.spClifuerza_Update' AS ProcedureName, @ResultMessage AS LogMessage
END
