CREATE OR ALTER PROCEDURE silver.spClientesRuta_Anular
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay asignaciones para anular'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @TableName VARCHAR(100)
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	SET @TableName = CONCAT('clientesrutaAnular', @dateFormat)

	-- Solo anular si ambos CSV tienen datos (el idRuta sale del join y un archivo vacio anularia todo)
	IF EXISTS (SELECT TOP 1 1 FROM bronze.EClientesRuta)
	AND EXISTS (SELECT TOP 1 1 FROM bronze.ERutasVenta)
	AND EXISTS (
		SELECT TOP 1 1
		FROM gold.ClientesRuta G
		WHERE ISNULL(G.anulado, 0) = 0
		  AND NOT EXISTS (
				SELECT 1
				FROM bronze.EClientesRuta B
				INNER JOIN bronze.ERutasVenta R ON R.IdRutaAuto = B.IdRutaAuto
				WHERE B.idCliente = G.idCliente
				  AND R.idRuta = G.idRuta
		  )
	)
	BEGIN
		SET @Version = ISNULL((SELECT MAX(result.filepath(1)) FROM OPENROWSET(
			BULK 'chess/parquet_files/clientesruta/Ver=*/*/*.parquet', DATA_SOURCE = 'eds_delfos', FORMAT = 'PARQUET') AS result), 0) + 1
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/clientesruta/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SELECT @RowsAffected = COUNT(*)
			FROM gold.ClientesRuta T1
			WHERE ISNULL(T1.anulado, 0) = 0
			  AND NOT EXISTS (
					SELECT 1
					FROM bronze.EClientesRuta B
					INNER JOIN bronze.ERutasVenta R ON R.IdRutaAuto = B.IdRutaAuto
					WHERE B.idCliente = T1.idCliente
					  AND R.idRuta = T1.idRuta
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
							T1.idCliente
							,T1.razonSocial
							,T1.intercalacionVisita
							,T1.intercalacionEntrega
							,T1.idRuta
							,CAST(1 AS bit) AS anulado
							,' + CAST(@Version AS VARCHAR(10)) + ' AS Ver
						FROM gold.ClientesRuta T1
						WHERE ISNULL(T1.anulado, 0) = 0
						  AND NOT EXISTS (
								SELECT 1
								FROM bronze.EClientesRuta B
								INNER JOIN bronze.ERutasVenta R ON R.IdRutaAuto = B.IdRutaAuto
								WHERE B.idCliente = T1.idCliente
								  AND R.idRuta = T1.idRuta
						  )'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Asignaciones marcadas como anuladas (ausentes en bronze) (', @RowsAffected, ' filas)')
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END
	SELECT @StartDateProc, GETDATE(), 'silver.spClientesRuta_Anular' AS ProcedureName, @ResultMessage AS LogMessage
END
