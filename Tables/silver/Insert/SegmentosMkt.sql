CREATE OR ALTER PROCEDURE silver.spSegmentosMkt_Insert
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay nuevos datos para añadir'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	DECLARE @TableName VARCHAR(100) = CONCAT('SegmentosMkt', @dateFormat)

	IF EXISTS (SELECT TOP 1 1 FROM bronze.SegmentosMkt T1 LEFT JOIN gold.SegmentosMkt T2 ON T2.idSegmentoMkt = T1.idSegmentoMkt WHERE T2.idSegmentoMkt IS NULL)
	BEGIN
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/segmentosmkt/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SET @SQL = 'CREATE EXTERNAL TABLE ' + @TableName + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
				SELECT T1.*, ' + CAST(@Version AS VARCHAR(10)) + ' AS Ver FROM bronze.SegmentosMkt T1
				LEFT JOIN gold.SegmentosMkt T2 ON T2.idSegmentoMkt = T1.idSegmentoMkt WHERE T2.idSegmentoMkt IS NULL'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = 'Datos insertados correctamente'
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END
	SELECT @StartDateProc, GETDATE(), 'silver.spSegmentosMkt_Insert' AS ProcedureName, @ResultMessage AS LogMessage
END
