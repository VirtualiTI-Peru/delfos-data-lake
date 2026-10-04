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

	-- Clave idRuta. Una sola fila por clave: el JOIN contra gold repetido multiplicaba filas.
	-- IdRutaAuto se regenera en cada extraccion y no se compara.
	IF EXISTS (
		SELECT TOP 1 1
		FROM (
			SELECT
				B.*,
				ROW_NUMBER() OVER (PARTITION BY B.idRuta ORDER BY ISNULL(B.anulado, 0), B.idSucursal, B.idPersonal) AS rn
			FROM bronze.ERutasVenta B
		) T1
		WHERE T1.rn = 1
		AND EXISTS (
			SELECT 1
			FROM gold.RutasVenta T2
			WHERE T2.idRuta = T1.idRuta
			AND (
				ISNULL(T1.idSucursal, 0) <> ISNULL(T2.idSucursal, 0)
		   OR ISNULL(T1.desSucursal, '') <> ISNULL(T2.desSucursal, '')
		   OR ISNULL(T1.idFuerzaVentas, 0) <> ISNULL(T2.idFuerzaVentas, 0)
		   OR ISNULL(T1.desFuerzaVentas, '') <> ISNULL(T2.desFuerzaVentas, '')
		   OR ISNULL(T1.idModoAtencion, '') <> ISNULL(T2.idModoAtencion, '')
		   OR ISNULL(T1.desModoAtencion, '') <> ISNULL(T2.desModoAtencion, '')
		   OR ISNULL(T1.desRuta, '') <> ISNULL(T2.desRuta, '')
		   OR ISNULL(T1.fechaDesde, '') <> ISNULL(T2.fechaDesde, '')
		   OR ISNULL(T1.fechaHasta, '') <> ISNULL(T2.fechaHasta, '')
		   OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
		   OR ISNULL(T1.idPersonal, 0) <> ISNULL(T2.idPersonal, 0)
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
					B.*,
					ROW_NUMBER() OVER (PARTITION BY B.idRuta ORDER BY ISNULL(B.anulado, 0), B.idSucursal, B.idPersonal) AS rn
				FROM bronze.ERutasVenta B
			) T1
			WHERE T1.rn = 1
			AND EXISTS (
				SELECT 1
				FROM gold.RutasVenta T2
				WHERE T2.idRuta = T1.idRuta
				AND (
					ISNULL(T1.idSucursal, 0) <> ISNULL(T2.idSucursal, 0)
			   OR ISNULL(T1.desSucursal, '') <> ISNULL(T2.desSucursal, '')
			   OR ISNULL(T1.idFuerzaVentas, 0) <> ISNULL(T2.idFuerzaVentas, 0)
			   OR ISNULL(T1.desFuerzaVentas, '') <> ISNULL(T2.desFuerzaVentas, '')
			   OR ISNULL(T1.idModoAtencion, '') <> ISNULL(T2.idModoAtencion, '')
			   OR ISNULL(T1.desModoAtencion, '') <> ISNULL(T2.desModoAtencion, '')
			   OR ISNULL(T1.desRuta, '') <> ISNULL(T2.desRuta, '')
			   OR ISNULL(T1.fechaDesde, '') <> ISNULL(T2.fechaDesde, '')
			   OR ISNULL(T1.fechaHasta, '') <> ISNULL(T2.fechaHasta, '')
			   OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
			   OR ISNULL(T1.idPersonal, 0) <> ISNULL(T2.idPersonal, 0)
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
					T1.fechaDesde, T1.fechaHasta, T1.anulado, T1.idPersonal, T1.desPersonal,
					T1.periodicidadVisita, T1.semanaVisita, T1.diasVisita,
					T1.periodicidadEntrega, T1.semanaEntrega, T1.diasEntrega, T1.IdRutaAuto,
					' + CAST(@Version AS VARCHAR(10)) + ' AS Ver
				FROM (
					SELECT
						B.*,
						ROW_NUMBER() OVER (PARTITION BY B.idRuta ORDER BY ISNULL(B.anulado, 0), B.idSucursal, B.idPersonal) AS rn
					FROM bronze.ERutasVenta B
				) T1
				WHERE T1.rn = 1
				AND EXISTS (
					SELECT 1
					FROM gold.RutasVenta T2
					WHERE T2.idRuta = T1.idRuta
					AND (
						ISNULL(T1.idSucursal, 0) <> ISNULL(T2.idSucursal, 0)
						OR ISNULL(T1.desSucursal, '''') <> ISNULL(T2.desSucursal, '''')
						OR ISNULL(T1.idFuerzaVentas, 0) <> ISNULL(T2.idFuerzaVentas, 0)
						OR ISNULL(T1.desFuerzaVentas, '''') <> ISNULL(T2.desFuerzaVentas, '''')
						OR ISNULL(T1.idModoAtencion, '''') <> ISNULL(T2.idModoAtencion, '''')
						OR ISNULL(T1.desModoAtencion, '''') <> ISNULL(T2.desModoAtencion, '''')
						OR ISNULL(T1.desRuta, '''') <> ISNULL(T2.desRuta, '''')
						OR ISNULL(T1.fechaDesde, '''') <> ISNULL(T2.fechaDesde, '''')
						OR ISNULL(T1.fechaHasta, '''') <> ISNULL(T2.fechaHasta, '''')
						OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
						OR ISNULL(T1.idPersonal, 0) <> ISNULL(T2.idPersonal, 0)
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
