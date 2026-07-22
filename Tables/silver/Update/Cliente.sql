CREATE OR ALTER PROCEDURE silver.spCliente_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay nuevos datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()

	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @TableName as VARCHAR(100)
	DECLARE @dateFormat AS varchar(14) = FORMAT(getdate(),'yyyyMMddHHmmss')
	SET @TableName = CONCAT('cliente',@dateFormat)

	-- Solo claves que YA existen en gold y cambiaron atributos monitoreados
	IF EXISTS (
		SELECT TOP 1 1
		FROM bronze.ECliente T1
		INNER JOIN gold.Cliente T2 ON T2.idCliente = T1.idCliente
		WHERE ISNULL(T1.idSucursal, 0) <> ISNULL(T2.idSucursal, 0)
		   OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
		   OR ISNULL(T1.idAliasVigente, 0) <> ISNULL(T2.idAliasVigente, 0)
		   OR ISNULL(T1.idProvincia, '') <> ISNULL(T2.idProvincia, '')
		   OR ISNULL(T1.desProvincia, '') <> ISNULL(T2.desProvincia, '')
		   OR ISNULL(T1.desDepartamento, '') <> ISNULL(T2.desDepartamento, '')
		   OR ISNULL(T1.idLocalidad, 0) <> ISNULL(T2.idLocalidad, 0)
		   OR ISNULL(T1.desLocalidad, '') <> ISNULL(T2.desLocalidad, '')
		   OR ISNULL(T1.desFormaPago, '') <> ISNULL(T2.desFormaPago, '')
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
			SELECT @RowsAffected = COUNT(*)
			FROM bronze.ECliente T1
			INNER JOIN gold.Cliente T2 ON T2.idCliente = T1.idCliente
			WHERE ISNULL(T1.idSucursal, 0) <> ISNULL(T2.idSucursal, 0)
			   OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
			   OR ISNULL(T1.idAliasVigente, 0) <> ISNULL(T2.idAliasVigente, 0)
			   OR ISNULL(T1.idProvincia, '') <> ISNULL(T2.idProvincia, '')
			   OR ISNULL(T1.desProvincia, '') <> ISNULL(T2.desProvincia, '')
			   OR ISNULL(T1.desDepartamento, '') <> ISNULL(T2.desDepartamento, '')
			   OR ISNULL(T1.idLocalidad, 0) <> ISNULL(T2.idLocalidad, 0)
			   OR ISNULL(T1.desLocalidad, '') <> ISNULL(T2.desLocalidad, '')
			   OR ISNULL(T1.desFormaPago, '') <> ISNULL(T2.desFormaPago, '')

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
						INNER JOIN gold.Cliente T2 ON T2.idCliente = T1.idCliente
						WHERE ISNULL(T1.idSucursal, 0) <> ISNULL(T2.idSucursal, 0)
						   OR ISNULL(T1.anulado, 0) <> ISNULL(T2.anulado, 0)
						   OR ISNULL(T1.idAliasVigente, 0) <> ISNULL(T2.idAliasVigente, 0)
						   OR ISNULL(T1.idProvincia, '''') <> ISNULL(T2.idProvincia, '''')
						   OR ISNULL(T1.desProvincia, '''') <> ISNULL(T2.desProvincia, '''')
						   OR ISNULL(T1.desDepartamento, '''') <> ISNULL(T2.desDepartamento, '''')
						   OR ISNULL(T1.idLocalidad, 0) <> ISNULL(T2.idLocalidad, 0)
						   OR ISNULL(T1.desLocalidad, '''') <> ISNULL(T2.desLocalidad, '''')
						   OR ISNULL(T1.desFormaPago, '''') <> ISNULL(T2.desFormaPago, '''')
				'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName;
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
		,'silver.spCliente_Update' AS ProcedureName
		,@ResultMessage AS LogMessage
END
