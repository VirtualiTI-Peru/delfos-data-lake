CREATE OR ALTER PROCEDURE silver.spSubCanalesMkt_Insert
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay nuevos datos para añadir'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	DECLARE @TableName VARCHAR(100) = CONCAT('SubCanalesMkt', @dateFormat)

	IF EXISTS (SELECT TOP 1 1 FROM bronze.SubCanalesMkt T1 LEFT JOIN gold.SubCanalesMkt T2 ON T2.idSubcanalMkt = T1.idSubcanalMkt WHERE T2.idSubcanalMkt IS NULL)
	BEGIN
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/subcanalesmkt/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SET @SQL = 'CREATE EXTERNAL TABLE ' + @TableName + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
				SELECT T1.*, ' + CAST(@Version AS VARCHAR(10)) + ' AS Ver FROM bronze.SubCanalesMkt T1
				LEFT JOIN gold.SubCanalesMkt T2 ON T2.idSubcanalMkt = T1.idSubcanalMkt WHERE T2.idSubcanalMkt IS NULL'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = 'Datos insertados correctamente'
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END
	SELECT @StartDateProc, GETDATE(), 'silver.spSubCanalesMkt_Insert' AS ProcedureName, @ResultMessage AS LogMessage
END
