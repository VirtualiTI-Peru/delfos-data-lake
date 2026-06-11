CREATE OR ALTER PROCEDURE silver.spCanalesMkt_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @TableName VARCHAR(100)
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	SET @TableName = CONCAT('canalesmkt', @dateFormat)

	IF EXISTS (
		SELECT idCanalMkt, desCanalMkt, idSegmentoMkt, compania FROM bronze.CanalesMkt
		EXCEPT
		SELECT idCanalMkt, desCanalMkt, idSegmentoMkt, compania FROM gold.CanalesMkt
	)
	BEGIN
		SET @Version = ISNULL((SELECT MAX(result.filepath(1)) FROM OPENROWSET(
			BULK 'chess/parquet_files/canalesmkt/Ver=*/*/*.parquet', DATA_SOURCE = 'eds_delfos', FORMAT = 'PARQUET') AS result), 0) + 1
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/canalesmkt/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SET @SQL = 'CREATE EXTERNAL TABLE ' + @TableName + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
				SELECT T1.*, ' + CAST(@Version AS VARCHAR(10)) + ' AS Ver FROM bronze.CanalesMkt T1
				WHERE CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(T1.idCanalMkt,''|'',T1.desCanalMkt,''|'',T1.idSegmentoMkt,''|'',T1.compania), '''')), 2) NOT IN (
					SELECT CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(T2.idCanalMkt,''|'',T2.desCanalMkt,''|'',T2.idSegmentoMkt,''|'',T2.compania), '''')), 2) FROM gold.CanalesMkt T2)'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = 'Datos actualizados correctamente'
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END
	SELECT @StartDateProc, GETDATE(), 'silver.spCanalesMkt_Update' AS ProcedureName, @ResultMessage AS LogMessage
END
