CREATE OR ALTER PROCEDURE silver.spAgrupacion_Insert
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay nuevos datos para añadir'
	DECLARE @StartDateProc DateTime = GETDATE()
	
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @dateFormat AS varchar(14) = FORMAT(getdate(),'yyyyMMddHHmmss')
	DECLARE @TableName as VARCHAR(100)

	SET @TableName = CONCAT('Agrupaciones',@dateFormat)

	-- Clave de negocio alineada con gold.Agrupacion (sin desFormaAgrupar)
	IF EXISTS ( SELECT TOP 1 1
				FROM
					bronze.EAgrupacione T1
				LEFT JOIN gold.Agrupacion T2 ON		T2.IdArticulo = T1.IdArticulo
												AND T2.idFormaAgrupar = T1.idFormaAgrupar
												AND T2.idAgrupacion = T1.idAgrupacion
				WHERE T2.IdArticulo IS NULL
	)
	BEGIN
		-- Misma logica de version que Update: nunca reutilizar Ver=1 si ya hay datos
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
			SELECT @RowsAffected = COUNT(*)
			FROM bronze.EAgrupacione T1
			LEFT JOIN gold.Agrupacion T2 ON T2.IdArticulo = T1.IdArticulo
				AND T2.idFormaAgrupar = T1.idFormaAgrupar
				AND T2.idAgrupacion = T1.idAgrupacion
			WHERE T2.IdArticulo IS NULL

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
							+  CAST(@Version AS VARCHAR(10)) + ' AS Ver' + ' FROM bronze.EAgrupacione  T1
						LEFT JOIN gold.Agrupacion T2 ON		T2.IdArticulo = T1.IdArticulo
														AND T2.idFormaAgrupar = T1.idFormaAgrupar
														AND T2.idAgrupacion = T1.idAgrupacion
						WHERE T2.IdArticulo IS NULL
				'
		
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Ok (', @RowsAffected, ' filas)')
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
		,'silver.spAgrupacion_Insert' AS ProcedureName
		,@ResultMessage AS LogMessage
END
