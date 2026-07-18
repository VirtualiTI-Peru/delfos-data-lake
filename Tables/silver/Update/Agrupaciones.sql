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

	-- Solo filas cuya clave YA existe en gold y cambio algun atributo.
	-- Evita que Update re-escriba altas (eso es responsabilidad de Insert).
	IF EXISTS (
		SELECT TOP 1 1
		FROM bronze.EAgrupacione T1
		INNER JOIN gold.Agrupacion T2
			ON T2.idArticulo = T1.idArticulo
			AND T2.idFormaAgrupar = T1.idFormaAgrupar
			AND T2.idAgrupacion = T1.idAgrupacion
		WHERE ISNULL(T1.desFormaAgrupar, '') <> ISNULL(T2.desFormaAgrupar, '')
		   OR ISNULL(T1.desAgrupacion, '') <> ISNULL(T2.desAgrupacion, '')
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
						INNER JOIN gold.Agrupacion T2
							ON T2.idArticulo = T1.idArticulo
							AND T2.idFormaAgrupar = T1.idFormaAgrupar
							AND T2.idAgrupacion = T1.idAgrupacion
						WHERE ISNULL(T1.desFormaAgrupar, '''') <> ISNULL(T2.desFormaAgrupar, '''')
						   OR ISNULL(T1.desAgrupacion, '''') <> ISNULL(T2.desAgrupacion, '''')
				'
	
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName;
			SET @ResultMessage = 'Ok'
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
