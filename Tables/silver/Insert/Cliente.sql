CREATE OR ALTER PROCEDURE silver.spCliente_Insert
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay nuevos datos para añadir'
	DECLARE @StartDateProc DateTime = GETDATE()

	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @dateFormat AS varchar(14) = FORMAT(getdate(),'yyyyMMddHHmmss')
	DECLARE @TableName as VARCHAR(100)
	SET @TableName = CONCAT('Clientes',@dateFormat)

	IF EXISTS ( SELECT TOP 1 1
				FROM
					bronze.ECliente T1
				LEFT JOIN gold.Cliente T2 ON T2.idCliente = T1.idCliente
				WHERE T2.idCliente IS NULL
	)
	BEGIN
		DECLARE @folderName as VARCHAR(100) = CONCAT('/chess/parquet_files/cliente/Ver=',@Version,'/',@dateFormat,'/')
		BEGIN TRY
			SET @SQL = 
				'CREATE EXTERNAL TABLE '+ @TableName +   
				' WITH (
						LOCATION = ''' + @folderName +''',
						DATA_SOURCE = eds_delfos,  
						FILE_FORMAT = eff_delfos_parquet
					)  
					AS
						SELECT 
							T1.*,' 
							+  CAST(@Version AS VARCHAR(10)) + ' AS Ver' + ' FROM bronze.ECliente  T1
						LEFT JOIN gold.Cliente T2 ON		T2.idCliente = T1.idCliente
						WHERE T2.idCliente IS NULL
				'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName;
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT(
				'Error No: ', ERROR_NUMBER()
				,'Message: ',ERROR_MESSAGE()
			)
		END CATCH
	END
	SELECT 
		@StartDateProc
		,GETDATE()
		,'silver.spCliente_Insert' AS ProcedureName
		,@ResultMessage AS LogMessage
END