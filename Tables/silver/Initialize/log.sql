DECLARE @Sql VARCHAR(MAX)
DECLARE @Version INT = 0
DECLARE @dateFormat AS varchar(14) = '00000000000000'
DECLARE @folderName as VARCHAR(100) = CONCAT('/chess/parquet_files/log/',@dateFormat,'/')

SET @SQL = '
			CREATE EXTERNAL TABLE Log#NA
			WITH (
				LOCATION = '''+ @folderName + ''',
				DATA_SOURCE = eds_delfos,  
				FILE_FORMAT = eff_delfos_parquet
			)
			AS
			SELECT
				CAST(NULL AS DateTime) as LogDate
				,CAST(NULL AS UNIQUEIDENTIFIER) as JobId
				,CAST( NULL AS nvarchar(128)) AS ProcedureName
				,CAST( NULL AS nvarchar(1024)) AS LogMessage
				,CAST(0 as int) as LogType
			'
EXEC (@SQL)

DROP EXTERNAL TABLE Log#NA

CREATE EXTERNAL TABLE [logs].[Log]
(
	LogDate DATETIME
	,JobId UNIQUEIDENTIFIER
	,ProcedureName VARCHAR(128)
	,LogMessage VARCHAR(1024)
	,LogType INT
)
WITH (
    LOCATION = 'chess/parquet_files/log/*/*.parquet',
    DATA_SOURCE = eds_delfos,  
    FILE_FORMAT = eff_delfos_parquet
)