CREATE OR ALTER PROCEDURE silver.spDsStock_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @TableName VARCHAR(100)
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	SET @TableName = CONCAT('dsstock', @dateFormat)

	IF EXISTS (
		SELECT TOP 1 1
		FROM bronze.DsStock T1
		INNER JOIN gold.DsStock T2
			ON T2.fecha = T1.fecha
			AND T2.idDeposito = T1.idDeposito
			AND T2.idAlmacen = T1.idAlmacen
			AND T2.idArticulo = T1.idArticulo
			AND ISNULL(T2.fecVtoLote, '1900-01-01') = ISNULL(T1.fecVtoLote, '1900-01-01')
		WHERE ISNULL(T1.cantBultos, 0) <> ISNULL(T2.cantBultos, 0)
		   OR ISNULL(T1.cantUnidades, 0) <> ISNULL(T2.cantUnidades, 0)
		   OR ISNULL(T1.dsArticulo, '') <> ISNULL(T2.dsArticulo, '')
	)
	BEGIN
		SET @Version = ISNULL(
			(SELECT MAX(result.filepath(1))
			 FROM OPENROWSET(
				BULK 'chess/parquet_files/dsstock/Ver=*/*/*.parquet',
				DATA_SOURCE = 'eds_delfos',
				FORMAT = 'PARQUET'
			 ) AS result), 0) + 1

		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/dsstock/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SET @SQL = '
				CREATE EXTERNAL TABLE ' + @TableName + '
				WITH (
					LOCATION = ''' + @folderName + ''',
					DATA_SOURCE = eds_delfos,
					FILE_FORMAT = eff_delfos_parquet
				)
				AS
				SELECT T1.*, ' + CAST(@Version AS VARCHAR(10)) + ' AS Ver
				FROM bronze.DsStock T1
				INNER JOIN gold.DsStock T2
					ON T2.fecha = T1.fecha
					AND T2.idDeposito = T1.idDeposito
					AND T2.idAlmacen = T1.idAlmacen
					AND T2.idArticulo = T1.idArticulo
					AND ISNULL(T2.fecVtoLote, ''1900-01-01'') = ISNULL(T1.fecVtoLote, ''1900-01-01'')
				WHERE ISNULL(T1.cantBultos, 0) <> ISNULL(T2.cantBultos, 0)
				   OR ISNULL(T1.cantUnidades, 0) <> ISNULL(T2.cantUnidades, 0)
				   OR ISNULL(T1.dsArticulo, '''') <> ISNULL(T2.dsArticulo, '''')'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = 'Datos actualizados correctamente'
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END

	SELECT @StartDateProc, GETDATE(), 'silver.spDsStock_Update' AS ProcedureName, @ResultMessage AS LogMessage
END
