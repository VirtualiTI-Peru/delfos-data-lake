CREATE OR ALTER PROCEDURE silver.spDiasNoLaborables_Anular
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay dias no laborables para anular'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql NVARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @dateFormat VARCHAR(20) = FORMAT(SYSDATETIME(), 'yyyyMMddHHmmssfff')
	DECLARE @TableName VARCHAR(100) = CONCAT('DiasNoLaborablesA', @dateFormat)
	DECLARE @folderName VARCHAR(150)

	BEGIN TRY
		IF EXISTS (SELECT TOP 1 1 FROM bronze.DiasNoLaborables)
		AND EXISTS (
			SELECT TOP 1 1
			FROM gold.DiasNoLaborables g
			WHERE ISNULL(g.anulado, 0) = 0
			  AND NOT EXISTS (
					SELECT 1
					FROM bronze.DiasNoLaborables b
					WHERE b.fecha = g.fecha
			  )
		)
		BEGIN
			SELECT @RowsAffected = COUNT(*)
			FROM gold.DiasNoLaborables g
			WHERE ISNULL(g.anulado, 0) = 0
			  AND NOT EXISTS (
					SELECT 1
					FROM bronze.DiasNoLaborables b
					WHERE b.fecha = g.fecha
			  )

			SET @Version = ISNULL((SELECT MAX(result.filepath(1)) FROM OPENROWSET(
				BULK 'chess/parquet_files/diasnolaborables/Ver=*/*/*.parquet',
				DATA_SOURCE = 'eds_delfos',
				FORMAT = 'PARQUET') AS result), 0) + 1
			SET @folderName = CONCAT('/chess/parquet_files/diasnolaborables/Ver=', @Version, '/', @dateFormat, 'A/')
			SET @Sql = 'CREATE EXTERNAL TABLE ' + @TableName + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
				SELECT
					g.fecha,
					g.tipo,
					g.descripcion,
					g.[Year],
					g.[Month],
					CAST(1 AS bit) AS anulado,
					' + CAST(@Version AS VARCHAR(10)) + ' AS Ver
				FROM gold.DiasNoLaborables g
				WHERE ISNULL(g.anulado, 0) = 0
				  AND NOT EXISTS (
						SELECT 1
						FROM bronze.DiasNoLaborables b
						WHERE b.fecha = g.fecha
				  )'
			EXEC (@Sql)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Dias no laborables marcados como anulados (ausentes en bronze) (', @RowsAffected, ' filas)')
		END
	END TRY
	BEGIN CATCH
		SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
	END CATCH

	SELECT @StartDateProc, GETDATE(), 'silver.spDiasNoLaborables_Anular' AS ProcedureName, @ResultMessage AS LogMessage
END
