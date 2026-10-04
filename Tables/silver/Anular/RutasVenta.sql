CREATE OR ALTER PROCEDURE silver.spRutasVenta_Anular
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay rutas para anular'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @TableName VARCHAR(100)
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	SET @TableName = CONCAT('rutasventaAnular', @dateFormat)

	-- Solo anular si bronze tiene datos (evita marcar todo como anulado ante una ingesta vacia/fallida)
	IF EXISTS (SELECT TOP 1 1 FROM bronze.ERutasVenta)
	AND EXISTS (
		SELECT TOP 1 1
		FROM gold.RutasVenta G
		WHERE ISNULL(G.anulado, 0) = 0
		  AND NOT EXISTS (
				SELECT 1
				FROM bronze.ERutasVenta B
				WHERE B.idRuta = G.idRuta
		  )
	)
	BEGIN
		SET @Version = ISNULL((SELECT MAX(CAST(result.filepath(1) AS INT)) FROM OPENROWSET(
			BULK 'chess/parquet_files/rutasventa/Ver=*/*/*.parquet', DATA_SOURCE = 'eds_delfos', FORMAT = 'PARQUET') AS result), 0) + 1
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/rutasventa/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SELECT @RowsAffected = COUNT(*)
			FROM gold.RutasVenta T1
			WHERE ISNULL(T1.anulado, 0) = 0
			  AND NOT EXISTS (
					SELECT 1
					FROM bronze.ERutasVenta B
					WHERE B.idRuta = T1.idRuta
			  )

			SET @SQL =
				'CREATE EXTERNAL TABLE ' + @TableName +
				' WITH (
						LOCATION = ''' + @folderName + ''',
						DATA_SOURCE = eds_delfos,
						FILE_FORMAT = eff_delfos_parquet
					)
					AS
						SELECT
							T1.idSucursal
							,T1.desSucursal
							,T1.idFuerzaVentas
							,T1.desFuerzaVentas
							,T1.idModoAtencion
							,T1.desModoAtencion
							,T1.idRuta
							,T1.desRuta
							,T1.fechaDesde
							,T1.fechaHasta
							,CAST(1 AS bit) AS anulado
							,T1.idPersonal
							,T1.desPersonal
							,T1.periodicidadVisita
							,T1.semanaVisita
							,T1.diasVisita
							,T1.periodicidadEntrega
							,T1.semanaEntrega
							,T1.diasEntrega
							,T1.IdRutaAuto
							,' + CAST(@Version AS VARCHAR(10)) + ' AS Ver
						FROM gold.RutasVenta T1
						WHERE ISNULL(T1.anulado, 0) = 0
						  AND NOT EXISTS (
								SELECT 1
								FROM bronze.ERutasVenta B
								WHERE B.idRuta = T1.idRuta
						  )'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Rutas marcadas como anuladas (ausentes en bronze) (', @RowsAffected, ' filas)')
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END
	SELECT @StartDateProc, GETDATE(), 'silver.spRutasVenta_Anular' AS ProcedureName, @ResultMessage AS LogMessage
END
