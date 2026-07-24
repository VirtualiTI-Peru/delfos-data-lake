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
	DECLARE @RowsAffected INT = 0
	DECLARE @DayRows INT = 0
	DECLARE @HadError BIT = 0
	DECLARE @ErrorDetail VARCHAR(MAX) = ''

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

			-- Solo filas cuya clave YA existe en gold y cambio anulado/fecha
			IF EXISTS (
				SELECT TOP 1 1
				FROM bronze.VentasResumen T1
				INNER JOIN gold.VentasResumen T2
					ON ISNULL(T2.Letra, '') = ISNULL(T1.letra, '')
					AND T2.IdDocumento = T1.iddocumento
					AND T2.IdEmpresa = T1.idempresa
					AND T2.idSucursal = T1.idSucursal
					AND T2.NroDoc = T1.nrodoc
					AND T2.Serie = T1.serie
					AND T2.idLinea = T1.idLinea
					AND T2.idArticulo = T1.idArticulo
				WHERE CONVERT(datetime2, T1.fechaComprobate, 103) = @Date
					AND (
						CASE WHEN UPPER(LTRIM(RTRIM(T1.anulado))) = N'SI' THEN 1 ELSE 0 END <> ISNULL(T2.anulado, 0)
						OR ISNULL(CONVERT(NVARCHAR(30), T1.fechaComprobate, 126), '')
							<> ISNULL(CONVERT(NVARCHAR(30), T2.fechaComprobate, 126), '')
					)
			)
			BEGIN
				-- Serverless throws 13807 when Ver=* path does not exist yet; treat as first version.
				SET @Version = 1
				BEGIN TRY
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
				END TRY
				BEGIN CATCH
					SET @Version = 1
				END CATCH

				BEGIN TRY
					SELECT @DayRows = COUNT(*)
					FROM bronze.VentasResumen T1
					INNER JOIN gold.VentasResumen T2
						ON ISNULL(T2.Letra, '') = ISNULL(T1.letra, '')
						AND T2.IdDocumento = T1.iddocumento
						AND T2.IdEmpresa = T1.idempresa
						AND T2.idSucursal = T1.idSucursal
						AND T2.NroDoc = T1.nrodoc
						AND T2.Serie = T1.serie
						AND T2.idLinea = T1.idLinea
						AND T2.idArticulo = T1.idArticulo
					WHERE CONVERT(datetime2, T1.fechaComprobate, 103) = @Date
						AND (
							CASE WHEN UPPER(LTRIM(RTRIM(T1.anulado))) = N'SI' THEN 1 ELSE 0 END <> ISNULL(T2.anulado, 0)
							OR ISNULL(CONVERT(NVARCHAR(30), T1.fechaComprobate, 126), '')
								<> ISNULL(CONVERT(NVARCHAR(30), T2.fechaComprobate, 126), '')
						)

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
						INNER JOIN gold.VentasResumen T2
							ON ISNULL(T2.Letra, '''') = ISNULL(T1.letra, '''')
							AND T2.IdDocumento = T1.iddocumento
							AND T2.IdEmpresa = T1.idempresa
							AND T2.idSucursal = T1.idSucursal
							AND T2.NroDoc = T1.nrodoc
							AND T2.Serie = T1.serie
							AND T2.idLinea = T1.idLinea
							AND T2.idArticulo = T1.idArticulo
						WHERE CONVERT(datetime2, T1.fechaComprobate, 103) = CONVERT(datetime2, ''' + CAST(@Date AS VARCHAR(10)) + ''')
							AND (
								CASE WHEN UPPER(LTRIM(RTRIM(T1.anulado))) = N''SI'' THEN 1 ELSE 0 END <> ISNULL(T2.anulado, 0)
								OR ISNULL(CONVERT(NVARCHAR(30), T1.fechaComprobate, 126), '''')
									<> ISNULL(CONVERT(NVARCHAR(30), T2.fechaComprobate, 126), '''')
							)'

					EXEC (@SQL)
					EXEC helpers.DropExternalTable @TableName
					SET @RowsAffected = @RowsAffected + @DayRows
				END TRY
				BEGIN CATCH
					SET @HadError = 1
					SET @ErrorDetail = CONCAT(
						@ErrorDetail,
						'; Error No: ', ERROR_NUMBER(),
						' Message: ', ERROR_MESSAGE(),
						' (fecha=', CONVERT(VARCHAR(10), @Date, 23), ')'
					)
				END CATCH
			END

			SET @Date = DATEADD(day, 1, @Date)
		END
	END TRY
	BEGIN CATCH
		SET @HadError = 1
		SET @ErrorDetail = CONCAT(@ErrorDetail, '; Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())
	END CATCH

	IF @HadError = 1
		SET @ResultMessage = CONCAT(
			CASE WHEN @RowsAffected > 0 THEN CONCAT('Parcial (', @RowsAffected, ' filas).') ELSE 'Error.' END,
			@ErrorDetail
		)
	ELSE IF @RowsAffected > 0
		SET @ResultMessage = CONCAT('Datos actualizados correctamente (', @RowsAffected, ' filas)')

	SELECT @StartDateProc, GETDATE(), 'silver.spVentasResumen_Update' AS ProcedureName, @ResultMessage AS LogMessage
END
