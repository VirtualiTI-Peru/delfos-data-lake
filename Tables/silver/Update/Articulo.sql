CREATE OR ALTER PROCEDURE silver.spArticulo_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay nuevos datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()

	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @TableName as VARCHAR(100)
	DECLARE @dateFormat AS varchar(14) = FORMAT(getdate(),'yyyyMMddHHmmss')
	SET @TableName = CONCAT('articulo',@dateFormat)

	IF EXISTS (
		SELECT TOP 1 1
		FROM bronze.EArticulo T1
		INNER JOIN gold.Articulo T2 ON T2.idArticulo = T1.idArticulo
		WHERE ISNULL(T1.desArticulo, '') <> ISNULL(T2.desArticulo, '')
		   OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
		   OR ISNULL(T1.unidadesBulto, 0) <> ISNULL(T2.unidadesBulto, 0)
		   OR ISNULL(T1.pesable, 0) <> ISNULL(T2.pesable, 0)
		   OR ISNULL(T1.esAlcoholico, 0) <> ISNULL(T2.esAlcoholico, 0)
		   OR ISNULL(T1.esComodatable, 0) <> ISNULL(T2.esComodatable, 0)
		   OR ISNULL(T1.idPresentacionBulto, '') <> ISNULL(T2.idPresentacionBulto, '')
		   OR ISNULL(T1.valorUnidadMedida, 0) <> ISNULL(T2.valorUnidadMedida, 0)
		   OR ISNULL(T1.idArticuloEstadistico, 0) <> ISNULL(T2.idArticuloEstadistico, 0)
	)
	BEGIN
		SET @Version = ISNULL(
							(SELECT
								MAX(result.filepath(1))
							FROM
								OPENROWSET(
									BULK 'chess/parquet_files/articulo/Ver=*/*/*.parquet',
									DATA_SOURCE='eds_delfos',
									FORMAT='PARQUET'
								) AS result )
							,0) + 1 
        
		DECLARE @folderName as VARCHAR(100) = CONCAT('/chess/parquet_files/articulo/Ver=',@Version,'/',@dateFormat,'/')

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
						' FROM bronze.EArticulo T1
						INNER JOIN gold.Articulo T2 ON T2.idArticulo = T1.idArticulo
						WHERE ISNULL(T1.desArticulo, '''') <> ISNULL(T2.desArticulo, '''')
						   OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
						   OR ISNULL(T1.unidadesBulto, 0) <> ISNULL(T2.unidadesBulto, 0)
						   OR ISNULL(T1.pesable, 0) <> ISNULL(T2.pesable, 0)
						   OR ISNULL(T1.esAlcoholico, 0) <> ISNULL(T2.esAlcoholico, 0)
						   OR ISNULL(T1.esComodatable, 0) <> ISNULL(T2.esComodatable, 0)
						   OR ISNULL(T1.idPresentacionBulto, '''') <> ISNULL(T2.idPresentacionBulto, '''')
						   OR ISNULL(T1.valorUnidadMedida, 0) <> ISNULL(T2.valorUnidadMedida, 0)
						   OR ISNULL(T1.idArticuloEstadistico, 0) <> ISNULL(T2.idArticuloEstadistico, 0)
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
		,GETDATE()
		,'silver.spArticulo_Update' AS ProcedureName
		,@ResultMessage AS LogMessage
END
