CREATE OR ALTER PROCEDURE silver.spDsStock_Insert
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay nuevos datos para añadir'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	DECLARE @TableName VARCHAR(100) = CONCAT('DsStock', @dateFormat)

	IF EXISTS (
		SELECT TOP 1 1
		FROM bronze.DsStock T1
		LEFT JOIN gold.DsStock T2
			ON T2.fecha = T1.fecha
			AND T2.idDeposito = T1.idDeposito
			AND T2.idAlmacen = T1.idAlmacen
			AND T2.idArticulo = T1.idArticulo
			AND ISNULL(T2.fecVtoLote, '1900-01-01') = ISNULL(T1.fecVtoLote, '1900-01-01')
		WHERE T2.fecha IS NULL
	)
	BEGIN
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
				LEFT JOIN gold.DsStock T2
					ON T2.fecha = T1.fecha
					AND T2.idDeposito = T1.idDeposito
					AND T2.idAlmacen = T1.idAlmacen
					AND T2.idArticulo = T1.idArticulo
					AND ISNULL(T2.fecVtoLote, ''1900-01-01'') = ISNULL(T1.fecVtoLote, ''1900-01-01'')
				WHERE T2.fecha IS NULL'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = 'Datos insertados correctamente'
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END

	SELECT @StartDateProc, GETDATE(), 'silver.spDsStock_Insert' AS ProcedureName, @ResultMessage AS LogMessage
END
