CREATE OR ALTER PROCEDURE job.spSyncData
AS
BEGIN
	DECLARE @JobId AS uniqueidentifier 
	DECLARE @DbName as VARCHAR(128)
	DECLARE @ProcName as VARCHAR(128)
	DECLARE @Sql VARCHAR(MAX)
	SET @JobId = NEWID()
	SET @ProcName = 'job.spSyncData'
	
	CREATE TABLE #TempTable (
		StartDate DateTime
		,EndDate DateTime
		,ProcedureName VARCHAR(128)
		,LogMessage VARCHAR(MAX)
	)

	INSERT INTO #TempTable (StartDate, EndDate, ProcedureName, LogMessage)
	EXEC silver.spAgrupacion_Insert

	INSERT INTO #TempTable (StartDate, EndDate, ProcedureName ,LogMessage)
	EXEC silver.spAgrupacion_Update

	INSERT INTO #TempTable (StartDate, EndDate, ProcedureName ,LogMessage)
	EXEC silver.spArticulo_Insert
	
	INSERT INTO #TempTable (StartDate, EndDate, ProcedureName ,LogMessage)
	EXEC silver.spArticulo_Update

	INSERT INTO #TempTable (StartDate, EndDate, ProcedureName ,LogMessage)
	EXEC silver.spCliente_Insert

	INSERT INTO #TempTable (StartDate, EndDate, ProcedureName ,LogMessage)
	EXEC silver.spCliente_Update

	INSERT INTO #TempTable (StartDate, EndDate, ProcedureName ,LogMessage)
	EXEC silver.spVentasResumen_Insert

	INSERT INTO #TempTable (StartDate, EndDate, ProcedureName ,LogMessage)
	EXEC silver.spVentasResumen_Update
	
	DECLARE @dateFormat AS varchar(14) = FORMAT(getdate(),'yyyyMMddHHmmss')
	DECLARE @TableName as VARCHAR(100)

	SET @TableName = CONCAT('Log',@dateFormat)
	DECLARE @folderName as VARCHAR(100) = CONCAT('/chess/parquet_files/log/',@dateFormat,'/')

	--SET @SQL = 
	--	'CREATE EXTERNAL TABLE '+ @TableName +   
	--	' WITH (
	--			LOCATION = ''' + @folderName +''',
	--			DATA_SOURCE = eds_delfos,  
	--			FILE_FORMAT = eff_delfos_parquet
	--		)  
	--		AS
	--			SELECT '''
	--				+ CAST(@JobId  AS VARCHAR(36)) + '''
	--				AS JobId,T1.StartDate
	--				,EndDate
	--				,ProcedureName 
	--				,LogMessage  
	--			FROM #TempTable  T1'
	--	print @sql
	--EXEC (@SQL)
	--EXEC helpers.DropExternalTable @TableName

	SELECT 
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
		,@JobId 
		,StartDate
		,EndDate
		,ProcedureName 
		,LogMessage
	FROM  #TempTable
	DROP TABLE #TempTable
END