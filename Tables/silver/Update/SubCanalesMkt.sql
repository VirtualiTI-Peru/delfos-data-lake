CREATE OR ALTER PROCEDURE silver.spSubCanalesMkt_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @TableName VARCHAR(100)
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	SET @TableName = CONCAT('subcanalesmkt', @dateFormat)

	IF EXISTS (
		SELECT idSubcanalMkt, desSubcanalMkt, idCanalMkt, compania FROM bronze.SubCanalesMkt
		EXCEPT
		SELECT idSubcanalMkt, desSubcanalMkt, idCanalMkt, compania FROM gold.SubCanalesMkt
	)
	BEGIN
		SET @Version = ISNULL((SELECT MAX(result.filepath(1)) FROM OPENROWSET(
			BULK 'chess/parquet_files/subcanalesmkt/Ver=*/*/*.parquet', DATA_SOURCE = 'eds_delfos', FORMAT = 'PARQUET') AS result), 0) + 1
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/subcanalesmkt/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SET @SQL = 'CREATE EXTERNAL TABLE ' + @TableName + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
				SELECT T1.*, ' + CAST(@Version AS VARCHAR(10)) + ' AS Ver FROM bronze.SubCanalesMkt T1
				WHERE CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(T1.idSubcanalMkt,''|'',T1.desSubcanalMkt,''|'',T1.idCanalMkt,''|'',T1.compania), '''')), 2) NOT IN (
					SELECT CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(T2.idSubcanalMkt,''|'',T2.desSubcanalMkt,''|'',T2.idCanalMkt,''|'',T2.compania), '''')), 2) FROM gold.SubCanalesMkt T2)'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = 'Datos actualizados correctamente'
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END
	SELECT @StartDateProc, GETDATE(), 'silver.spSubCanalesMkt_Update' AS ProcedureName, @ResultMessage AS LogMessage
END
