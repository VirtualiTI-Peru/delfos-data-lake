CREATE OR ALTER PROCEDURE silver.spClifuerza_Anular
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay asignaciones para anular'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @TableName VARCHAR(100)
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	SET @TableName = CONCAT('clifuerzaAnular', @dateFormat)

	-- Solo anular si bronze tiene datos (un CSV vacio anularia todas las asignaciones)
	IF EXISTS (SELECT TOP 1 1 FROM bronze.EClifuerza)
	AND EXISTS (
		SELECT TOP 1 1
		FROM gold.Clifuerza G
		WHERE ISNULL(G.anulado, 0) = 0
		  AND NOT EXISTS (
				SELECT 1
				FROM bronze.EClifuerza B
				WHERE B.idSucursal = G.idSucursal
				  AND B.idCliente = G.idCliente
				  AND B.idFuerzaVentas = G.idFuerzaVentas
				  AND B.idRuta = G.idRuta
		  )
	)
	BEGIN
		SET @Version = ISNULL((SELECT MAX(CAST(result.filepath(1) AS INT)) FROM OPENROWSET(
			BULK 'chess/parquet_files/clifuerza/Ver=*/*/*.parquet', DATA_SOURCE = 'eds_delfos', FORMAT = 'PARQUET') AS result), 0) + 1
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/clifuerza/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SELECT @RowsAffected = COUNT(*)
			FROM gold.Clifuerza T1
			WHERE ISNULL(T1.anulado, 0) = 0
			  AND NOT EXISTS (
					SELECT 1
					FROM bronze.EClifuerza B
					WHERE B.idSucursal = T1.idSucursal
					  AND B.idCliente = T1.idCliente
					  AND B.idFuerzaVentas = T1.idFuerzaVentas
					  AND B.idRuta = T1.idRuta
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
							,T1.idCliente
							,T1.idFuerzaVentas
							,T1.desFuerzaVenta
							,T1.idModoAtencion
							,T1.desModoAtencion
							,CAST(T1.fechaInicioFuerza AS datetime) AS fechaInicioFuerza
							,CAST(T1.fechaFinFuerza AS datetime) AS fechaFinFuerza
							,T1.idRuta
							,CAST(T1.fechaRutaVenta AS datetime) AS fechaRutaVenta
							,CAST(1 AS bit) AS anulado
							,T1.periodicidadVisita
							,T1.semanaVisita
							,T1.diasVisita
							,T1.intercalacionVisita
							,T1.perioricidadEntrega
							,T1.semanaEntrega
							,T1.diasEntrega
							,T1.intercalacionEntrega
							,T1.Horarios
							,' + CAST(@Version AS VARCHAR(10)) + ' AS Ver
						FROM gold.Clifuerza T1
						WHERE ISNULL(T1.anulado, 0) = 0
						  AND NOT EXISTS (
								SELECT 1
								FROM bronze.EClifuerza B
								WHERE B.idSucursal = T1.idSucursal
								  AND B.idCliente = T1.idCliente
								  AND B.idFuerzaVentas = T1.idFuerzaVentas
								  AND B.idRuta = T1.idRuta
						  )'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Asignaciones marcadas como anuladas (ausentes en bronze) (', @RowsAffected, ' filas)')
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END
	SELECT @StartDateProc, GETDATE(), 'silver.spClifuerza_Anular' AS ProcedureName, @ResultMessage AS LogMessage
END
