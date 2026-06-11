CREATE OR ALTER PROCEDURE silver.spAgrupacion_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()

	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @TableName as VARCHAR(100)
	DECLARE @dateFormat AS varchar(14) = FORMAT(getdate(),'yyyyMMddHHmmss')
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
							T1.*,' 
							+  CAST(@Version AS VARCHAR(10)) + ' AS Ver' + 
						' FROM bronze.EAgrupacione T1
						WHERE 
							CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(T1.idFormaAgrupar,''|'',T1.desFormaAgrupar,''|'',T1.idArticulo,''|'',T1.idAgrupacion,''|'',T1.desAgrupacion), '''')), 2) NOT IN
							(
								SELECT
									CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(T2.idFormaAgrupar,''|'',T2.desFormaAgrupar,''|'',T2.idArticulo,''|'',T2.idAgrupacion,''|'',T2.desAgrupacion), '''')), 2)
								FROM
									gold.Agrupacion T2
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