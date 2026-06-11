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
		SELECT fecha, idDeposito, idAlmacen, idArticulo, fecVtoLote, cantBultos, cantUnidades
		FROM bronze.DsStock
		EXCEPT
		SELECT fecha, idDeposito, idAlmacen, idArticulo, fecVtoLote, cantBultos, cantUnidades
		FROM gold.DsStock
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
				WHERE CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(
					ISNULL(CONVERT(NVARCHAR(30), T1.fecha, 126), ''''),
					''|'', ISNULL(CAST(T1.idDeposito AS NVARCHAR(20)), ''''),
					''|'', ISNULL(CAST(T1.idAlmacen AS NVARCHAR(20)), ''''),
					''|'', ISNULL(CAST(T1.idArticulo AS NVARCHAR(20)), ''''),
					''|'', ISNULL(CONVERT(NVARCHAR(30), T1.fecVtoLote, 126), ''''),
					''|'', ISNULL(CAST(T1.cantBultos AS NVARCHAR(20)), ''''),
					''|'', ISNULL(CAST(T1.cantUnidades AS NVARCHAR(20)), '''')
				), '''')), 2) NOT IN (
					SELECT CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(
						ISNULL(CONVERT(NVARCHAR(30), T2.fecha, 126), ''''),
						''|'', ISNULL(CAST(T2.idDeposito AS NVARCHAR(20)), ''''),
						''|'', ISNULL(CAST(T2.idAlmacen AS NVARCHAR(20)), ''''),
						''|'', ISNULL(CAST(T2.idArticulo AS NVARCHAR(20)), ''''),
						''|'', ISNULL(CONVERT(NVARCHAR(30), T2.fecVtoLote, 126), ''''),
						''|'', ISNULL(CAST(T2.cantBultos AS NVARCHAR(20)), ''''),
						''|'', ISNULL(CAST(T2.cantUnidades AS NVARCHAR(20)), '''')
					), '''')), 2)
					FROM gold.DsStock T2
				)'
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
