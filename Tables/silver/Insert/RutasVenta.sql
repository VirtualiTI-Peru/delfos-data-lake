CREATE OR ALTER PROCEDURE silver.spRutasVenta_Insert
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay nuevos datos para añadir'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	DECLARE @TableName VARCHAR(100) = CONCAT('RutasVenta', @dateFormat)

	-- Clave idSucursal + idFuerzaVentas + idRuta + idPersonal.
	-- Si bronze repite la clave, queda una fila (prioriza anulado = 0).
	-- fechaDesde y fechaHasta llegan como nvarchar (dd/mm/yyyy, con hora opcional, o yyyy-mm-dd);
	-- el CETAS las escribe como datetime. Un valor no reconocible queda NULL.
	-- IdRutaAuto se regenera en cada extraccion y no forma parte de la clave.
	-- No usar #temp: serverless no lo admite en el mismo plan que una external table.
	IF EXISTS (
		SELECT TOP 1 1
		FROM (
			SELECT
				B.idSucursal,
				B.idFuerzaVentas,
				B.idRuta,
				B.idPersonal,
				ROW_NUMBER() OVER (
					PARTITION BY B.idSucursal, B.idFuerzaVentas, B.idRuta, B.idPersonal
					ORDER BY ISNULL(B.anulado, 0)
				) AS rn
			FROM bronze.ERutasVenta B
		) T1
		LEFT JOIN gold.RutasVenta T2
			ON T2.idSucursal = T1.idSucursal
			AND T2.idFuerzaVentas = T1.idFuerzaVentas
			AND T2.idRuta = T1.idRuta
			AND T2.idPersonal = T1.idPersonal
		WHERE T1.rn = 1 AND T2.idRuta IS NULL
	)
	BEGIN
		SET @Version = ISNULL((SELECT MAX(CAST(result.filepath(1) AS INT)) FROM OPENROWSET(
			BULK 'chess/parquet_files/rutasventa/Ver=*/*/*.parquet', DATA_SOURCE = 'eds_delfos', FORMAT = 'PARQUET') AS result), 0) + 1
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/rutasventa/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SELECT @RowsAffected = COUNT(*)
			FROM (
				SELECT
					B.idSucursal,
					B.idFuerzaVentas,
					B.idRuta,
					B.idPersonal,
					ROW_NUMBER() OVER (
						PARTITION BY B.idSucursal, B.idFuerzaVentas, B.idRuta, B.idPersonal
						ORDER BY ISNULL(B.anulado, 0)
					) AS rn
				FROM bronze.ERutasVenta B
			) T1
			LEFT JOIN gold.RutasVenta T2
				ON T2.idSucursal = T1.idSucursal
				AND T2.idFuerzaVentas = T1.idFuerzaVentas
				AND T2.idRuta = T1.idRuta
				AND T2.idPersonal = T1.idPersonal
			WHERE T1.rn = 1 AND T2.idRuta IS NULL

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
				LEFT JOIN gold.RutasVenta T2
					ON T2.idSucursal = T1.idSucursal
					AND T2.idFuerzaVentas = T1.idFuerzaVentas
					AND T2.idRuta = T1.idRuta
					AND T2.idPersonal = T1.idPersonal
				WHERE T1.rn = 1 AND T2.idRuta IS NULL'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Datos insertados correctamente (', @RowsAffected, ' filas)')
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END
	SELECT @StartDateProc, GETDATE(), 'silver.spRutasVenta_Insert' AS ProcedureName, @ResultMessage AS LogMessage
END
