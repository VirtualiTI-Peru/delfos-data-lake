CREATE OR ALTER PROCEDURE silver.spRutasVenta_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @TableName VARCHAR(100)
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	SET @TableName = CONCAT('rutasventa', @dateFormat)

	-- Clave idSucursal + idFuerzaVentas + idRuta + idPersonal. Una fila por clave.
	-- Un cambio de sucursal, fuerza o personal es otra clave (Insert + Anular), no un update.
	-- fechaDesde y fechaHasta llegan como nvarchar; se comparan y se escriben como datetime.
	-- IdRutaAuto se regenera en cada extraccion y no se compara.
	-- No usar #temp: serverless no lo admite en el mismo plan que una external table.
	IF EXISTS (
		SELECT TOP 1 1
		FROM (
			SELECT
				S.*,
				ROW_NUMBER() OVER (
					PARTITION BY S.idSucursal, S.idFuerzaVentas, S.idRuta, S.idPersonal
					ORDER BY ISNULL(S.anulado, 0)
				) AS rn
			FROM (
				SELECT
					B.idSucursal, B.desSucursal, B.idFuerzaVentas, B.desFuerzaVentas,
					B.idModoAtencion, B.desModoAtencion, B.idRuta, B.desRuta,
					COALESCE(
						TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaDesde)), ''), 103),
						TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaDesde, 10))), ''), 103),
						TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaDesde)), 'T', ' '), ''), 120)
					) AS fechaDesde,
					COALESCE(
						TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaHasta)), ''), 103),
						TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaHasta, 10))), ''), 103),
						TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaHasta)), 'T', ' '), ''), 120)
					) AS fechaHasta,
					B.anulado, B.idPersonal, B.desPersonal,
					B.periodicidadVisita, B.semanaVisita, B.diasVisita,
					B.periodicidadEntrega, B.semanaEntrega, B.diasEntrega, B.IdRutaAuto
				FROM bronze.ERutasVenta B
			) S
		) T1
		WHERE T1.rn = 1
		AND EXISTS (
			SELECT 1
			FROM gold.RutasVenta T2
			WHERE T2.idSucursal = T1.idSucursal
			  AND T2.idFuerzaVentas = T1.idFuerzaVentas
			  AND T2.idRuta = T1.idRuta
			  AND T2.idPersonal = T1.idPersonal
			  AND (
					ISNULL(T1.desSucursal, '') <> ISNULL(T2.desSucursal, '')
					OR ISNULL(T1.desFuerzaVentas, '') <> ISNULL(T2.desFuerzaVentas, '')
					OR ISNULL(T1.idModoAtencion, '') <> ISNULL(T2.idModoAtencion, '')
					OR ISNULL(T1.desModoAtencion, '') <> ISNULL(T2.desModoAtencion, '')
					OR ISNULL(T1.desRuta, '') <> ISNULL(T2.desRuta, '')
					OR NOT (
						T1.fechaDesde = T2.fechaDesde
						OR (T1.fechaDesde IS NULL AND T2.fechaDesde IS NULL)
					)
					OR NOT (
						T1.fechaHasta = T2.fechaHasta
						OR (T1.fechaHasta IS NULL AND T2.fechaHasta IS NULL)
					)
					OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
					OR ISNULL(T1.desPersonal, '') <> ISNULL(T2.desPersonal, '')
					OR ISNULL(T1.periodicidadVisita, 0) <> ISNULL(T2.periodicidadVisita, 0)
					OR ISNULL(T1.semanaVisita, 0) <> ISNULL(T2.semanaVisita, 0)
					OR ISNULL(T1.diasVisita, '') <> ISNULL(T2.diasVisita, '')
					OR ISNULL(T1.periodicidadEntrega, 0) <> ISNULL(T2.periodicidadEntrega, 0)
					OR ISNULL(T1.semanaEntrega, 0) <> ISNULL(T2.semanaEntrega, 0)
					OR ISNULL(T1.diasEntrega, '') <> ISNULL(T2.diasEntrega, '')
			  )
		)
	)
	BEGIN
		SET @Version = ISNULL((SELECT MAX(CAST(result.filepath(1) AS INT)) FROM OPENROWSET(
			BULK 'chess/parquet_files/rutasventa/Ver=*/*/*.parquet', DATA_SOURCE = 'eds_delfos', FORMAT = 'PARQUET') AS result), 0) + 1
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/rutasventa/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SELECT @RowsAffected = COUNT(*)
			FROM (
				SELECT
					S.*,
					ROW_NUMBER() OVER (
						PARTITION BY S.idSucursal, S.idFuerzaVentas, S.idRuta, S.idPersonal
						ORDER BY ISNULL(S.anulado, 0)
					) AS rn
				FROM (
					SELECT
						B.idSucursal, B.desSucursal, B.idFuerzaVentas, B.desFuerzaVentas,
						B.idModoAtencion, B.desModoAtencion, B.idRuta, B.desRuta,
						COALESCE(
							TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaDesde)), ''), 103),
							TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaDesde, 10))), ''), 103),
							TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaDesde)), 'T', ' '), ''), 120)
						) AS fechaDesde,
						COALESCE(
							TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaHasta)), ''), 103),
							TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaHasta, 10))), ''), 103),
							TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaHasta)), 'T', ' '), ''), 120)
						) AS fechaHasta,
						B.anulado, B.idPersonal, B.desPersonal,
						B.periodicidadVisita, B.semanaVisita, B.diasVisita,
						B.periodicidadEntrega, B.semanaEntrega, B.diasEntrega, B.IdRutaAuto
					FROM bronze.ERutasVenta B
				) S
			) T1
			WHERE T1.rn = 1
			AND EXISTS (
				SELECT 1
				FROM gold.RutasVenta T2
				WHERE T2.idSucursal = T1.idSucursal
				  AND T2.idFuerzaVentas = T1.idFuerzaVentas
				  AND T2.idRuta = T1.idRuta
				  AND T2.idPersonal = T1.idPersonal
				  AND (
						ISNULL(T1.desSucursal, '') <> ISNULL(T2.desSucursal, '')
						OR ISNULL(T1.desFuerzaVentas, '') <> ISNULL(T2.desFuerzaVentas, '')
						OR ISNULL(T1.idModoAtencion, '') <> ISNULL(T2.idModoAtencion, '')
						OR ISNULL(T1.desModoAtencion, '') <> ISNULL(T2.desModoAtencion, '')
						OR ISNULL(T1.desRuta, '') <> ISNULL(T2.desRuta, '')
						OR NOT (
							T1.fechaDesde = T2.fechaDesde
							OR (T1.fechaDesde IS NULL AND T2.fechaDesde IS NULL)
						)
						OR NOT (
							T1.fechaHasta = T2.fechaHasta
							OR (T1.fechaHasta IS NULL AND T2.fechaHasta IS NULL)
						)
						OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
						OR ISNULL(T1.desPersonal, '') <> ISNULL(T2.desPersonal, '')
						OR ISNULL(T1.periodicidadVisita, 0) <> ISNULL(T2.periodicidadVisita, 0)
						OR ISNULL(T1.semanaVisita, 0) <> ISNULL(T2.semanaVisita, 0)
						OR ISNULL(T1.diasVisita, '') <> ISNULL(T2.diasVisita, '')
						OR ISNULL(T1.periodicidadEntrega, 0) <> ISNULL(T2.periodicidadEntrega, 0)
						OR ISNULL(T1.semanaEntrega, 0) <> ISNULL(T2.semanaEntrega, 0)
						OR ISNULL(T1.diasEntrega, '') <> ISNULL(T2.diasEntrega, '')
				  )
			)

			SET @SQL = 'CREATE EXTERNAL TABLE ' + @TableName + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
				SELECT
					T1.idSucursal, T1.desSucursal, T1.idFuerzaVentas, T1.desFuerzaVentas,
					T1.idModoAtencion, T1.desModoAtencion, T1.idRuta, T1.desRuta,
					CAST(T1.fechaDesde AS datetime) AS fechaDesde,
					CAST(T1.fechaHasta AS datetime) AS fechaHasta,
					T1.anulado, T1.idPersonal, T1.desPersonal,
					T1.periodicidadVisita, T1.semanaVisita, T1.diasVisita,
					T1.periodicidadEntrega, T1.semanaEntrega, T1.diasEntrega, T1.IdRutaAuto,
					' + CAST(@Version AS VARCHAR(10)) + ' AS Ver
				FROM (
					SELECT
						S.idSucursal, S.desSucursal, S.idFuerzaVentas, S.desFuerzaVentas,
						S.idModoAtencion, S.desModoAtencion, S.idRuta, S.desRuta,
						S.fechaDesde, S.fechaHasta, S.anulado, S.idPersonal, S.desPersonal,
						S.periodicidadVisita, S.semanaVisita, S.diasVisita,
						S.periodicidadEntrega, S.semanaEntrega, S.diasEntrega, S.IdRutaAuto,
						ROW_NUMBER() OVER (
							PARTITION BY S.idSucursal, S.idFuerzaVentas, S.idRuta, S.idPersonal
							ORDER BY ISNULL(S.anulado, 0)
						) AS rn
					FROM (
						SELECT
							B.idSucursal, B.desSucursal, B.idFuerzaVentas, B.desFuerzaVentas,
							B.idModoAtencion, B.desModoAtencion, B.idRuta, B.desRuta,
							COALESCE(
								TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaDesde)), ''''), 103),
								TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaDesde, 10))), ''''), 103),
								TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaDesde)), ''T'', '' ''), ''''), 120)
							) AS fechaDesde,
							COALESCE(
								TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(B.fechaHasta)), ''''), 103),
								TRY_CONVERT(datetime, NULLIF(LTRIM(RTRIM(LEFT(B.fechaHasta, 10))), ''''), 103),
								TRY_CONVERT(datetime, NULLIF(REPLACE(LTRIM(RTRIM(B.fechaHasta)), ''T'', '' ''), ''''), 120)
							) AS fechaHasta,
							B.anulado, B.idPersonal, B.desPersonal,
							B.periodicidadVisita, B.semanaVisita, B.diasVisita,
							B.periodicidadEntrega, B.semanaEntrega, B.diasEntrega, B.IdRutaAuto
						FROM bronze.ERutasVenta B
					) S
				) T1
				WHERE T1.rn = 1
				AND EXISTS (
					SELECT 1
					FROM gold.RutasVenta T2
					WHERE T2.idSucursal = T1.idSucursal
					  AND T2.idFuerzaVentas = T1.idFuerzaVentas
					  AND T2.idRuta = T1.idRuta
					  AND T2.idPersonal = T1.idPersonal
					  AND (
							ISNULL(T1.desSucursal, '''') <> ISNULL(T2.desSucursal, '''')
							OR ISNULL(T1.desFuerzaVentas, '''') <> ISNULL(T2.desFuerzaVentas, '''')
							OR ISNULL(T1.idModoAtencion, '''') <> ISNULL(T2.idModoAtencion, '''')
							OR ISNULL(T1.desModoAtencion, '''') <> ISNULL(T2.desModoAtencion, '''')
							OR ISNULL(T1.desRuta, '''') <> ISNULL(T2.desRuta, '''')
							OR NOT (
								T1.fechaDesde = T2.fechaDesde
								OR (T1.fechaDesde IS NULL AND T2.fechaDesde IS NULL)
							)
							OR NOT (
								T1.fechaHasta = T2.fechaHasta
								OR (T1.fechaHasta IS NULL AND T2.fechaHasta IS NULL)
							)
							OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
							OR ISNULL(T1.desPersonal, '''') <> ISNULL(T2.desPersonal, '''')
							OR ISNULL(T1.periodicidadVisita, 0) <> ISNULL(T2.periodicidadVisita, 0)
							OR ISNULL(T1.semanaVisita, 0) <> ISNULL(T2.semanaVisita, 0)
							OR ISNULL(T1.diasVisita, '''') <> ISNULL(T2.diasVisita, '''')
							OR ISNULL(T1.periodicidadEntrega, 0) <> ISNULL(T2.periodicidadEntrega, 0)
							OR ISNULL(T1.semanaEntrega, 0) <> ISNULL(T2.semanaEntrega, 0)
							OR ISNULL(T1.diasEntrega, '''') <> ISNULL(T2.diasEntrega, '''')
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
	SELECT @StartDateProc, GETDATE(), 'silver.spRutasVenta_Update' AS ProcedureName, @ResultMessage AS LogMessage
END
