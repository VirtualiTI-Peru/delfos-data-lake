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

	IF EXISTS ( SELECT 
					idArticulo
					,desArticulo
					,anulado
					,unidadesBulto
					,pesable
					,esAlcoholico
					,esComodatable
					,idPresentacionBulto
					,valorUnidadMedida
					,idArticuloEstadistico
				FROM 
					bronze.EArticulo
				EXCEPT
				SELECT 
					idArticulo
					,desArticulo
					,anulado
					,unidadesBulto
					,pesable
					,esAlcoholico
					,esComodatable
					,idPresentacionBulto
					,valorUnidadMedida
					,idArticuloEstadistico
				FROM 
					gold.Articulo
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
						WHERE 
							CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(T1.idArticulo,''|'',T1.desArticulo,''|'',T1.anulado,''|'',T1.unidadesBulto,''|'',T1.pesable,''|'',T1.esAlcoholico,''|'',T1.esComodatable,''|'',T1.idPresentacionBulto,''|'',T1.valorUnidadMedida,''|'',T1.idArticuloEstadistico), '''')), 2) NOT IN
							(
								SELECT
									CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(T2.idArticulo,''|'',T2.desArticulo,''|'',T2.anulado,''|'',T2.unidadesBulto,''|'',T2.pesable,''|'',T2.esAlcoholico,''|'',T2.esComodatable,''|'',T2.idPresentacionBulto,''|'',T2.valorUnidadMedida,''|'',T2.idArticuloEstadistico), '''')), 2)
								FROM
									gold.Articulo T2
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
		,GETDATE()
		,'silver.spArticulo_Update' AS ProcedureName
		,@ResultMessage AS LogMessage
END