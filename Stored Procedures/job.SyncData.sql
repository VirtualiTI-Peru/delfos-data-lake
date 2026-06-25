CREATE OR ALTER PROCEDURE job.spSyncData
AS
BEGIN
	DECLARE @JobId AS uniqueidentifier = NEWID()
	DECLARE @Sql VARCHAR(MAX)
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	DECLARE @folderName VARCHAR(100) = CONCAT('/chess/parquet_files/log/', @dateFormat, '/')

	CREATE TABLE #TempTable (
		StartDate DateTime,
		EndDate DateTime,
		ProcedureName VARCHAR(128),
		LogMessage VARCHAR(MAX)
	)

	INSERT INTO #TempTable EXEC silver.spAgrupacion_Insert
	INSERT INTO #TempTable EXEC silver.spAgrupacion_Update
	INSERT INTO #TempTable EXEC silver.spArticulo_Insert
	INSERT INTO #TempTable EXEC silver.spArticulo_Update
	INSERT INTO #TempTable EXEC silver.spCliente_Insert
	INSERT INTO #TempTable EXEC silver.spCliente_Update
	INSERT INTO #TempTable EXEC silver.spVentasResumen_Insert
	INSERT INTO #TempTable EXEC silver.spVentasResumen_Update
	INSERT INTO #TempTable EXEC silver.spDsStock_Insert
	INSERT INTO #TempTable EXEC silver.spDsStock_Update
	INSERT INTO #TempTable EXEC silver.spCanalesMkt_Insert
	INSERT INTO #TempTable EXEC silver.spCanalesMkt_Update
	INSERT INTO #TempTable EXEC silver.spSegmentosMkt_Insert
	INSERT INTO #TempTable EXEC silver.spSegmentosMkt_Update
	INSERT INTO #TempTable EXEC silver.spSubCanalesMkt_Insert
	INSERT INTO #TempTable EXEC silver.spSubCanalesMkt_Update

	DECLARE @LogStartDate DATETIME
	DECLARE @LogProcedureName VARCHAR(128)
	DECLARE @LogMessageText VARCHAR(MAX)
	DECLARE @LogTableName VARCHAR(100)
	DECLARE @LogRowNum INT = 0
	DECLARE @LogMaxRowNum INT
	DECLARE @LogPersistFailed BIT = 0

	-- Synapse dedicated pool does not support @@FETCH_STATUS / cursors; use row-number iteration.
	SELECT
		ROW_NUMBER() OVER (ORDER BY StartDate, ProcedureName) AS RowNum,
		StartDate,
		ProcedureName,
		LogMessage
	INTO #LogRows
	FROM #TempTable

	SET @LogMaxRowNum = (SELECT MAX(RowNum) FROM #LogRows)

	WHILE @LogRowNum < @LogMaxRowNum
	BEGIN
		SET @LogRowNum = @LogRowNum + 1

		SELECT
			@LogStartDate = StartDate,
			@LogProcedureName = ProcedureName,
			@LogMessageText = LogMessage
		FROM #LogRows
		WHERE RowNum = @LogRowNum

		SET @LogTableName = CONCAT('Log', @dateFormat, '_', @LogRowNum)
		SET @LogMessageText = LEFT(REPLACE(REPLACE(REPLACE(@LogMessageText, '''', ''''''), CHAR(13), ''), CHAR(10), ''), 1024)

		SET @SQL =
			'CREATE EXTERNAL TABLE ' + @LogTableName +
			' WITH (
				LOCATION = ''' + @folderName + ''',
				DATA_SOURCE = eds_delfos,
				FILE_FORMAT = eff_delfos_parquet
			)
			AS
			SELECT '
			+ 'CAST(''' + CONVERT(VARCHAR(30), @LogStartDate, 126) + ''' AS DATETIME) AS LogDate, '
			+ 'CAST(''' + CAST(@JobId AS VARCHAR(36)) + ''' AS UNIQUEIDENTIFIER) AS JobId, '
			+ 'CAST(''' + REPLACE(@LogProcedureName, '''', '''''') + ''' AS VARCHAR(128)) AS ProcedureName, '
			+ 'CAST(''' + @LogMessageText + ''' AS VARCHAR(1024)) AS LogMessage, '
			+ 'CAST(' + CASE WHEN @LogMessageText LIKE 'Error%' THEN '1' ELSE '0' END + ' AS INT) AS LogType'

		BEGIN TRY
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @LogTableName
		END TRY
		BEGIN CATCH
			SET @LogPersistFailed = 1
		END CATCH
	END

	DROP TABLE #LogRows

	IF @LogPersistFailed = 1
	BEGIN
		INSERT INTO #TempTable (StartDate, EndDate, ProcedureName, LogMessage)
		VALUES (GETDATE(), GETDATE(), 'job.spSyncData', 'Advertencia: no se pudo persistir parte del log en ADLS (el job ETL finalizo correctamente).')
	END

	SELECT
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum,
		@JobId AS JobId,
		StartDate,
		EndDate,
		ProcedureName,
		LogMessage
	FROM #TempTable

	DROP TABLE #TempTable
END
