CREATE OR ALTER PROCEDURE silver.spVentasResumen_Insert
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay nuevos datos para aùadir'
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
				SELECT TOP 1 1
				FROM bronze.VentasResumen T1
				LEFT JOIN gold.VentasResumen T2
					ON ISNULL(T2.Letra, '') = ISNULL(T1.letra, '')
					AND T2.IdDocumento = T1.iddocumento
					AND T2.IdEmpresa = T1.idempresa
					AND T2.idSucursal = T1.idSucursal
					AND T2.NroDoc = T1.nrodoc
					AND T2.Serie = T1.serie
					AND T2.idLinea = T1.idLinea
					AND T2.idArticulo = T1.idArticulo
				WHERE CONVERT(datetime2, T1.fechaComprobate, 103) = @Date
					AND T2.fechaComprobate IS NULL
			)
			BEGIN
				SET @Version = 1
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
					LEFT JOIN gold.VentasResumen T2
						ON ISNULL(T2.Letra, '''') = ISNULL(T1.letra, '''')
						AND T2.IdDocumento = T1.iddocumento
						AND T2.IdEmpresa = T1.idempresa
						AND T2.idSucursal = T1.idSucursal
						AND T2.NroDoc = T1.nrodoc
						AND T2.Serie = T1.serie
						AND T2.idLinea = T1.idLinea
						AND T2.idArticulo = T1.idArticulo
					WHERE CONVERT(datetime2, T1.fechaComprobate, 103) = CONVERT(datetime2, ''' + CAST(@Date AS VARCHAR(10)) + ''')
						AND T2.fechaComprobate IS NULL'

				EXEC (@SQL)
				EXEC helpers.DropExternalTable @TableName
				SET @ResultMessage = 'Datos insertados correctamente'
			END

			SET @Date = DATEADD(day, 1, @Date)
		END
	END TRY
	BEGIN CATCH
		SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
	END CATCH

	SELECT @StartDateProc, GETDATE(), 'silver.spVentasResumen_Insert' AS ProcedureName, @ResultMessage AS LogMessage
END
