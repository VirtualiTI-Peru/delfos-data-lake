CREATE OR ALTER PROCEDURE silver.spCuotaVentas_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql NVARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @dateFormat VARCHAR(20) = FORMAT(SYSDATETIME(), 'yyyyMMddHHmmssfff')
	DECLARE @TableName VARCHAR(100) = CONCAT('CuotaVentasU', @dateFormat)
	DECLARE @folderName VARCHAR(150)

	BEGIN TRY
		SELECT @RowsAffected = COUNT(*)
		FROM bronze.CuotaVentas q
		INNER JOIN gold.CuotaVentas g
			ON g.idSucursal = q.idSucursal
		   AND g.idPersonal = q.idPersonal
		   AND g.periodo = q.periodo
		   AND g.idAgrupacion = q.idAgrupacion
		WHERE ISNULL(q.cuota, 0) <> ISNULL(g.cuota, 0)

		IF @RowsAffected > 0
		BEGIN
			SET @Version = ISNULL((SELECT MAX(result.filepath(1)) FROM OPENROWSET(
				BULK 'chess/parquet_files/cuotaventas/Ver=*/*/*.parquet',
				DATA_SOURCE = 'eds_delfos',
				FORMAT = 'PARQUET') AS result), 0) + 1
			SET @folderName = CONCAT('/chess/parquet_files/cuotaventas/Ver=', @Version, '/', @dateFormat, 'U/')
			SET @Sql = 'CREATE EXTERNAL TABLE ' + @TableName + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
				SELECT
					q.idSucursal,
					q.idPersonal,
					q.periodo,
					q.idAgrupacion,
					q.cuota,
					CAST(LEFT(q.periodo, 4) AS int) AS [Year],
					CAST(SUBSTRING(q.periodo, 6, 2) AS int) AS [Month],
					' + CAST(@Version AS VARCHAR(10)) + ' AS Ver
				FROM bronze.CuotaVentas q
				INNER JOIN gold.CuotaVentas g
					ON g.idSucursal = q.idSucursal
				   AND g.idPersonal = q.idPersonal
				   AND g.periodo = q.periodo
				   AND g.idAgrupacion = q.idAgrupacion
				WHERE ISNULL(q.cuota, 0) <> ISNULL(g.cuota, 0)'
			EXEC (@Sql)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Datos actualizados correctamente (', @RowsAffected, ' filas)')
		END
	END TRY
	BEGIN CATCH
		SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
	END CATCH

	SELECT @StartDateProc, GETDATE(), 'silver.spCuotaVentas_Update' AS ProcedureName, @ResultMessage AS LogMessage
END
