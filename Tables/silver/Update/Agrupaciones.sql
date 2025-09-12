CREATE OR ALTER PROCEDURE silver.spAgrupacion_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()

	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @TableName as VARCHAR(100)
	DECLARE @dateFormat AS varchar(14) = FORMAT(getdate(),'yyyyMMddhhmmss')
	SET @TableName = CONCAT('agrupacion',@dateFormat)

	IF EXISTS ( SELECT 
					[idFormaAgrupar]
					,[desFormaAgrupar]
					,[idArticulo]
					,[idAgrupacion]
					,[desAgrupacion]
				FROM 
					bronze.EAgrupacione
				EXCEPT
				SELECT 
					[idFormaAgrupar]
					,[desFormaAgrupar]
					,[idArticulo]
					,[idAgrupacion]
					,[desAgrupacion]
				FROM 
					gold.Agrupacion
	)
	BEGIN
		SET @Version = ISNULL(
							(SELECT
								MAX(result.filepath(1))
							FROM
								OPENROWSET(
									BULK 'chess/parquet_files/agrupacion/Ver=*/*/*.parquet',
									DATA_SOURCE='eds_delfos',
									FORMAT='PARQUET'
								) AS result )
							,0) + 1 
        
		DECLARE @folderName as VARCHAR(100) = CONCAT('/chess/parquet_files/agrupacion/Ver=',@Version,'/',@dateFormat,'/')
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
							*,' 
							+  CAST(@Version AS VARCHAR(10)) + ' AS Ver' + 
						' FROM bronze.EAgrupacione
						WHERE 
							CHECKSUM(CONCAT(idFormaAgrupar,desFormaAgrupar,idArticulo,idAgrupacion,desAgrupacion)) NOT IN
							(
								SELECT
									CHECKSUM(CONCAT(idFormaAgrupar,desFormaAgrupar,idArticulo,idAgrupacion,desAgrupacion))
								FROM
									gold.Agrupacion
							)
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
		, GETDATE()
		,'silver.spAgrupacion_Update' AS ProcedureName
		,@ResultMessage AS LogMessage
END