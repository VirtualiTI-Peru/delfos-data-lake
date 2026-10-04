CREATE OR ALTER PROCEDURE silver.spDiasNoLaborables_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql NVARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @dateFormat VARCHAR(20) = FORMAT(SYSDATETIME(), 'yyyyMMddHHmmssfff')
	DECLARE @TableName VARCHAR(100) = CONCAT('DiasNoLaborablesU', @dateFormat)
	DECLARE @folderName VARCHAR(150)

	BEGIN TRY
		SELECT @RowsAffected = COUNT(*)
		FROM bronze.DiasNoLaborables q
		INNER JOIN gold.DiasNoLaborables g
			ON g.fecha = q.fecha
		WHERE ISNULL(q.tipo, '') <> ISNULL(g.tipo, '')
		   OR ISNULL(q.descripcion, '') <> ISNULL(g.descripcion, '')
		   OR ISNULL(g.anulado, 0) = 1

		IF @RowsAffected > 0
		BEGIN
			SET @Version = ISNULL((SELECT MAX(result.filepath(1)) FROM OPENROWSET(
				BULK 'chess/parquet_files/diasnolaborables/Ver=*/*/*.parquet',
				DATA_SOURCE = 'eds_delfos',
				FORMAT = 'PARQUET') AS result), 0) + 1
			SET @folderName = CONCAT('/chess/parquet_files/diasnolaborables/Ver=', @Version, '/', @dateFormat, 'U/')
			SET @Sql = 'CREATE EXTERNAL TABLE ' + @TableName + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
				SELECT
					q.fecha,
					q.tipo,
					q.descripcion,
					CAST(LEFT(q.fecha, 4) AS int) AS [Year],
					CAST(SUBSTRING(q.fecha, 6, 2) AS int) AS [Month],
					CAST(0 AS bit) AS anulado,
					' + CAST(@Version AS VARCHAR(10)) + ' AS Ver
				FROM bronze.DiasNoLaborables q
				INNER JOIN gold.DiasNoLaborables g
					ON g.fecha = q.fecha
				WHERE ISNULL(q.tipo, '''') <> ISNULL(g.tipo, '''')
				   OR ISNULL(q.descripcion, '''') <> ISNULL(g.descripcion, '''')
				   OR ISNULL(g.anulado, 0) = 1'
			EXEC (@Sql)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Datos actualizados correctamente (', @RowsAffected, ' filas)')
		END
	END TRY
	BEGIN CATCH
		SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
	END CATCH

	SELECT @StartDateProc, GETDATE(), 'silver.spDiasNoLaborables_Update' AS ProcedureName, @ResultMessage AS LogMessage
END
