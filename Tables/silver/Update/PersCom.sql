CREATE OR ALTER PROCEDURE silver.spPersCom_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @TableName VARCHAR(100)
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	SET @TableName = CONCAT('perscom', @dateFormat)

	-- Clave idSucursal + idPersonal. idSucursal no se compara como atributo.
	IF EXISTS (
		SELECT TOP 1 1
		FROM bronze.EPersCom T1
		INNER JOIN gold.PersCom T2 ON T2.idSucursal = T1.idSucursal AND T2.idPersonal = T1.idPersonal
		WHERE ISNULL(T1.desSucursal, '') <> ISNULL(T2.desSucursal, '')
		   OR ISNULL(T1.desPersonal, '') <> ISNULL(T2.desPersonal, '')
		   OR ISNULL(T1.idFuerzaVentas, 0) <> ISNULL(T2.idFuerzaVentas, 0)
		   OR ISNULL(T1.desFuerzaVentas, '') <> ISNULL(T2.desFuerzaVentas, '')
		   OR ISNULL(T1.cargo, '') <> ISNULL(T2.cargo, '')
		   OR ISNULL(T1.tipoVenta, '') <> ISNULL(T2.tipoVenta, '')
		   OR ISNULL(T1.idPersonalSuperior, 0) <> ISNULL(T2.idPersonalSuperior, 0)
		   OR ISNULL(T1.desPersonalSuperior, '') <> ISNULL(T2.desPersonalSuperior, '')
		   OR ISNULL(T1.domicilio, '') <> ISNULL(T2.domicilio, '')
		   OR ISNULL(T1.telefono, '') <> ISNULL(T2.telefono, '')
		   OR ISNULL(T1.fechaNacimiento, '19000101') <> ISNULL(T2.fechaNacimiento, '19000101')
		   OR ISNULL(T1.usuarioSistema, '') <> ISNULL(T2.usuarioSistema, '')
		   OR ISNULL(T1.idTipoSegmento, 0) <> ISNULL(T2.idTipoSegmento, 0)
		   OR ISNULL(T1.desTipoSegmento, '') <> ISNULL(T2.desTipoSegmento, '')
	)
	BEGIN
		SET @Version = ISNULL((SELECT MAX(result.filepath(1)) FROM OPENROWSET(
			BULK 'chess/parquet_files/perscom/Ver=*/*/*.parquet', DATA_SOURCE = 'eds_delfos', FORMAT = 'PARQUET') AS result), 0) + 1
		DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/perscom/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SELECT @RowsAffected = COUNT(*)
			FROM bronze.EPersCom T1
			INNER JOIN gold.PersCom T2 ON T2.idSucursal = T1.idSucursal AND T2.idPersonal = T1.idPersonal
			WHERE ISNULL(T1.desSucursal, '') <> ISNULL(T2.desSucursal, '')
			   OR ISNULL(T1.desPersonal, '') <> ISNULL(T2.desPersonal, '')
			   OR ISNULL(T1.idFuerzaVentas, 0) <> ISNULL(T2.idFuerzaVentas, 0)
			   OR ISNULL(T1.desFuerzaVentas, '') <> ISNULL(T2.desFuerzaVentas, '')
			   OR ISNULL(T1.cargo, '') <> ISNULL(T2.cargo, '')
			   OR ISNULL(T1.tipoVenta, '') <> ISNULL(T2.tipoVenta, '')
			   OR ISNULL(T1.idPersonalSuperior, 0) <> ISNULL(T2.idPersonalSuperior, 0)
			   OR ISNULL(T1.desPersonalSuperior, '') <> ISNULL(T2.desPersonalSuperior, '')
			   OR ISNULL(T1.domicilio, '') <> ISNULL(T2.domicilio, '')
			   OR ISNULL(T1.telefono, '') <> ISNULL(T2.telefono, '')
			   OR ISNULL(T1.fechaNacimiento, '19000101') <> ISNULL(T2.fechaNacimiento, '19000101')
			   OR ISNULL(T1.usuarioSistema, '') <> ISNULL(T2.usuarioSistema, '')
			   OR ISNULL(T1.idTipoSegmento, 0) <> ISNULL(T2.idTipoSegmento, 0)
			   OR ISNULL(T1.desTipoSegmento, '') <> ISNULL(T2.desTipoSegmento, '')

			SET @SQL = 'CREATE EXTERNAL TABLE ' + @TableName + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
				SELECT T1.*, ' + CAST(@Version AS VARCHAR(10)) + ' AS Ver FROM bronze.EPersCom T1
				INNER JOIN gold.PersCom T2 ON T2.idSucursal = T1.idSucursal AND T2.idPersonal = T1.idPersonal
				WHERE ISNULL(T1.desSucursal, '''') <> ISNULL(T2.desSucursal, '''')
				   OR ISNULL(T1.desPersonal, '''') <> ISNULL(T2.desPersonal, '''')
				   OR ISNULL(T1.idFuerzaVentas, 0) <> ISNULL(T2.idFuerzaVentas, 0)
				   OR ISNULL(T1.desFuerzaVentas, '''') <> ISNULL(T2.desFuerzaVentas, '''')
				   OR ISNULL(T1.cargo, '''') <> ISNULL(T2.cargo, '''')
				   OR ISNULL(T1.tipoVenta, '''') <> ISNULL(T2.tipoVenta, '''')
				   OR ISNULL(T1.idPersonalSuperior, 0) <> ISNULL(T2.idPersonalSuperior, 0)
				   OR ISNULL(T1.desPersonalSuperior, '''') <> ISNULL(T2.desPersonalSuperior, '''')
				   OR ISNULL(T1.domicilio, '''') <> ISNULL(T2.domicilio, '''')
				   OR ISNULL(T1.telefono, '''') <> ISNULL(T2.telefono, '''')
				   OR ISNULL(T1.fechaNacimiento, ''19000101'') <> ISNULL(T2.fechaNacimiento, ''19000101'')
				   OR ISNULL(T1.usuarioSistema, '''') <> ISNULL(T2.usuarioSistema, '''')
				   OR ISNULL(T1.idTipoSegmento, 0) <> ISNULL(T2.idTipoSegmento, 0)
				   OR ISNULL(T1.desTipoSegmento, '''') <> ISNULL(T2.desTipoSegmento, '''')'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Datos actualizados correctamente (', @RowsAffected, ' filas)')
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
		END CATCH
	END
	SELECT @StartDateProc, GETDATE(), 'silver.spPersCom_Update' AS ProcedureName, @ResultMessage AS LogMessage
END
