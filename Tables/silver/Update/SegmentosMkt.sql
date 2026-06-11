CREATE OR ALTER PROCEDURE silver.spSegmentosMkt_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @TableName VARCHAR(100)
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	SET @TableName = CONCAT('segmentosmkt', @dateFormat)

	IF EXISTS (
		SELECT idSegmentoMkt, desSegmentoMkt, compania FROM bronze.SegmentosMkt
		EXCEPT
		SELECT idSegmentoMkt, desSegmentoMkt, compania FROM gold.SegmentosMkt
	)
	BEGIN
		SET @Version = ISNULL((SELECT MAX(result.filepath(1)) FROM OPENROWSET(
			BULK 'chess/parquet_files/segmentosmkt/Ver=*/*/*.parquet', DATA_SOURCE = 'eds_delfos', FORMAT = 'PARQUET') AS result), 0) + 1
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/segmentosmkt/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SET @SQL = 'CREATE EXTERNAL TABLE ' + @TableName + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
				SELECT T1.*, ' + CAST(@Version AS VARCHAR(10)) + ' AS Ver FROM bronze.SegmentosMkt T1
				WHERE CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(T1.idSegmentoMkt,''|'',T1.desSegmentoMkt,''|'',T1.compania), '''')), 2) NOT IN (
					SELECT CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(T2.idSegmentoMkt,''|'',T2.desSegmentoMkt,''|'',T2.compania), '''')), 2) FROM gold.SegmentosMkt T2)'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = 'Datos actualizados correctamente'
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END
	SELECT @StartDateProc, GETDATE(), 'silver.spSegmentosMkt_Update' AS ProcedureName, @ResultMessage AS LogMessage
END
