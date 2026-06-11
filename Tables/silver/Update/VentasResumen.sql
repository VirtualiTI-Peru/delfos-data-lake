CREATE OR ALTER PROCEDURE silver.spVentasResumen_Update
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay datos para actualizar'
	DECLARE @StartDateProc DateTime = GETDATE()

	DECLARE @StartDate DATE
	DECLARE @EndDate DATE
	DECLARE @Date DATE
	DECLARE @Year INT
	DECLARE @Month INT
	DECLARE @Day INT
	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @Version INT
	DECLARE @TableName VARCHAR(100)
	DECLARE @dateFormat VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	DECLARE @folderName VARCHAR(100)
	DECLARE @ColumnSelect NVARCHAR(MAX)
	DECLARE @VerStr VARCHAR(10)

	SET @TableName = CONCAT('VentasResumen', @dateFormat)

	SET @StartDate = (SELECT MIN(CONVERT(date, m.fechaComprobate, 103)) FROM bronze.VentasResumen m)
	SET @EndDate = (SELECT MAX(CONVERT(date, m.fechaComprobate, 103)) FROM bronze.VentasResumen m)
	SET @Date = @StartDate

	BEGIN TRY
		WHILE @Date <= @EndDate
		BEGIN
			SET @Year = YEAR(@Date)
			SET @Month = MONTH(@Date)
			SET @Day = DAY(@Date)

			IF EXISTS (
				SELECT
					T1.letra, T1.iddocumento, T1.idempresa, T1.idSucursal,
					T1.nrodoc, T1.serie, T1.idLinea, T1.idArticulo,
					T1.fechaComprobate, T1.anulado
				FROM bronze.VentasResumen T1
				WHERE CONVERT(datetime2, T1.fechaComprobate, 103) = @Date
				EXCEPT
				SELECT
					T2.letra, T2.iddocumento, T2.idempresa, T2.idSucursal,
					T2.nrodoc, T2.serie, T2.idLinea, T2.idArticulo,
					T2.fechaComprobate, T2.anulado
				FROM gold.VentasResumen T2
				WHERE CONVERT(datetime2, T2.fechaComprobate, 103) = @Date
			)
			BEGIN
				SET @SQL = '
					SELECT @Version = ISNULL(
						(SELECT MAX(result.filepath(1))
						 FROM OPENROWSET(
							BULK ''chess/parquet_files/ventasresumen/Year=' + CAST(@Year AS VARCHAR(4)) +
							'/Month=' + CAST(@Month AS VARCHAR(2)) + '/Day=' + CAST(@Day AS VARCHAR(2)) +
							'/Ver=*/*/*.parquet'',
							DATA_SOURCE=''eds_delfos'',
							FORMAT=''PARQUET''
						 ) AS result), 0) + 1'
				EXEC sp_executesql @SQL, N'@Version int OUTPUT', @Version OUTPUT

				SET @folderName = CONCAT('/chess/parquet_files/ventasresumen/Year=', CAST(@Year AS VARCHAR(4)),
					'/Month=', CAST(@Month AS VARCHAR(2)), '/Day=', CAST(@Day AS VARCHAR(2)),
					'/Ver=', CAST(@Version AS VARCHAR(10)), '/', @dateFormat, '/')
				SET @VerStr = CAST(@Version AS VARCHAR(10))
				EXEC helpers.spVentasResumen_BronzeSelect @TableAlias = 'T1', @VerExpression = @VerStr, @ColumnSelect = @ColumnSelect OUTPUT

				SET @SQL = '
					CREATE EXTERNAL TABLE ' + @TableName + '
					WITH (
						LOCATION = ''' + @folderName + ''',
						DATA_SOURCE = eds_delfos,
						FILE_FORMAT = eff_delfos_parquet
					)
					AS
					SELECT ' + @ColumnSelect + '
					FROM bronze.VentasResumen T1
					WHERE CONVERT(datetime2, T1.fechaComprobate, 103) = CONVERT(datetime2, ''' + CAST(@Date AS VARCHAR(10)) + ''')
						AND CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(
							ISNULL(CAST(T1.letra AS NVARCHAR(10)), ''''),
							''|'', ISNULL(CAST(T1.iddocumento AS NVARCHAR(20)), ''''),
							''|'', ISNULL(CAST(T1.idempresa AS NVARCHAR(20)), ''''),
							''|'', ISNULL(CAST(T1.idSucursal AS NVARCHAR(20)), ''''),
							''|'', ISNULL(CAST(T1.nrodoc AS NVARCHAR(20)), ''''),
							''|'', ISNULL(CAST(T1.serie AS NVARCHAR(20)), ''''),
							''|'', ISNULL(CAST(T1.idLinea AS NVARCHAR(20)), ''''),
							''|'', ISNULL(CAST(T1.idArticulo AS NVARCHAR(20)), ''''),
							''|'', ISNULL(CONVERT(NVARCHAR(30), T1.fechaComprobate, 126), ''''),
							''|'', ISNULL(CAST(T1.anulado AS NVARCHAR(10)), '''')
						), '''')), 2) NOT IN (
							SELECT CONVERT(VARCHAR(64), HASHBYTES(''SHA2_256'', ISNULL(CONCAT(
								ISNULL(CAST(T2.letra AS NVARCHAR(10)), ''''),
								''|'', ISNULL(CAST(T2.iddocumento AS NVARCHAR(20)), ''''),
								''|'', ISNULL(CAST(T2.idempresa AS NVARCHAR(20)), ''''),
								''|'', ISNULL(CAST(T2.idSucursal AS NVARCHAR(20)), ''''),
								''|'', ISNULL(CAST(T2.nrodoc AS NVARCHAR(20)), ''''),
								''|'', ISNULL(CAST(T2.serie AS NVARCHAR(20)), ''''),
								''|'', ISNULL(CAST(T2.idLinea AS NVARCHAR(20)), ''''),
								''|'', ISNULL(CAST(T2.idArticulo AS NVARCHAR(20)), ''''),
								''|'', ISNULL(CONVERT(NVARCHAR(30), T2.fechaComprobate, 126), ''''),
								''|'', ISNULL(CAST(T2.anulado AS NVARCHAR(10)), '''')
							), '''')), 2)
							FROM gold.VentasResumen T2
							WHERE CONVERT(datetime2, T2.fechaComprobate, 103) = CONVERT(datetime2, ''' + CAST(@Date AS VARCHAR(10)) + ''')
						)'

				EXEC (@SQL)
				EXEC helpers.DropExternalTable @TableName
				SET @ResultMessage = 'Datos actualizados correctamente'
			END

			SET @Date = DATEADD(day, 1, @Date)
		END
	END TRY
	BEGIN CATCH
		SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
	END CATCH

	SELECT @StartDateProc, GETDATE(), 'silver.spVentasResumen_Update' AS ProcedureName, @ResultMessage AS LogMessage
END
