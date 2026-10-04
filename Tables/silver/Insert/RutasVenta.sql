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

	-- Clave idRuta. Si bronze repite la clave, queda una fila (prioriza anulado = 0).
	IF EXISTS (
		SELECT TOP 1 1
		FROM (
			SELECT
				B.idRuta,
				ROW_NUMBER() OVER (PARTITION BY B.idRuta ORDER BY ISNULL(B.anulado, 0), B.idSucursal, B.idPersonal) AS rn
			FROM bronze.ERutasVenta B
		) T1
		LEFT JOIN gold.RutasVenta T2 ON T2.idRuta = T1.idRuta
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
					B.idRuta,
					ROW_NUMBER() OVER (PARTITION BY B.idRuta ORDER BY ISNULL(B.anulado, 0), B.idSucursal, B.idPersonal) AS rn
				FROM bronze.ERutasVenta B
			) T1
			LEFT JOIN gold.RutasVenta T2 ON T2.idRuta = T1.idRuta
			WHERE T1.rn = 1 AND T2.idRuta IS NULL

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
				LEFT JOIN gold.RutasVenta T2 ON T2.idRuta = T1.idRuta
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
