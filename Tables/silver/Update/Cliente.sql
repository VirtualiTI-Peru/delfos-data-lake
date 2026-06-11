CREATE OR ALTER PROCEDURE silver.spCliente_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay nuevos datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()

	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @TableName as VARCHAR(100)
	DECLARE @dateFormat AS varchar(14) = FORMAT(getdate(),'yyyyMMddHHmmss')
	SET @TableName = CONCAT('cliente',@dateFormat)

	IF EXISTS ( SELECT 
					idSucursal
					,idCliente
					,anulado
					,idAliasVigente
					,idProvincia
					,desProvincia
					,desDepartamento
					,idLocalidad
					,desLocalidad
					,desFormaPago
				FROM 
					bronze.ECliente
				EXCEPT
				SELECT 
					idSucursal
					,idCliente
					,anulado
					,idAliasVigente
					,idProvincia
					,desProvincia
					,desDepartamento
					,idLocalidad
					,desLocalidad
					,desFormaPago
				FROM 
					gold.Cliente
	)
	BEGIN
		SET @Version = ISNULL(
							(SELECT
								MAX(result.filepath(1))
							FROM
								OPENROWSET(
									BULK 'chess/parquet_files/cliente/Ver=*/*/*.parquet',
									DATA_SOURCE='eds_delfos',
									FORMAT='PARQUET'
								) AS result )
							,0) + 1 
        
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
							+  CAST(@Version AS VARCHAR(10)) + ' AS Ver' + 
						' FROM bronze.ECliente T1
						WHERE 
							CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(T1.idSucursal,''|'',T1.idCliente,''|'',T1.anulado,''|'',T1.idAliasVigente,''|'',T1.idProvincia,''|'',T1.desProvincia,''|'',T1.desDepartamento,''|'',T1.idLocalidad,''|'',T1.desLocalidad,''|'',T1.desFormaPago), '''')), 2) NOT IN
							(
								SELECT
									CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(T2.idSucursal,''|'',T2.idCliente,''|'',T2.anulado,''|'',T2.idAliasVigente,''|'',T2.idProvincia,''|'',T2.desProvincia,''|'',T2.desDepartamento,''|'',T2.idLocalidad,''|'',T2.desLocalidad,''|'',T2.desFormaPago), '''')), 2)
								FROM
									gold.Cliente T2
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
		,'silver.spCliente_Update' AS ProcedureName
		,@ResultMessage AS LogMessage
END