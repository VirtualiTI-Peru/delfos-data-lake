CREATE OR ALTER PROCEDURE agg.spVentasVendedorDiario_Refresh
	@Full BIT = 0
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay meses para refrescar'
	DECLARE @StartDateProc DateTime = GETDATE()
	DECLARE @Sql NVARCHAR(MAX)
	DECLARE @dateFormat VARCHAR(20) = FORMAT(SYSDATETIME(), 'yyyyMMddHHmmssfff')
	DECLARE @fechaActualizacion VARCHAR(30) = CONVERT(VARCHAR(30), SYSDATETIME(), 126)
	DECLARE @Year INT
	DECLARE @Month INT
	DECLARE @MonthKey CHAR(6)
	DECLARE @folderName VARCHAR(200)
	DECLARE @MonthIndex INT = 0
	DECLARE @MonthCount INT = 0
	DECLARE @MonthList VARCHAR(MAX)
	DECLARE @ExistingList VARCHAR(MAX)
	DECLARE @ExistingIndex INT = 0
	DECLARE @ExistingCount INT = 0
	DECLARE @OldTableName VARCHAR(100)
	DECLARE @BuildTable VARCHAR(100) = 'VentasVendedorDiarioBuild'
	DECLARE @Columns NVARCHAR(MAX) = N'fecha, [Year], [Month],
		idEmpresa, dsEmpresa, idSucursal, dsSucursal,
		idSupervisor, dsSupervisor, idVendedor, dsVendedor,
		nroComprobantes, nroClientes,
		subtotalBruto, subtotalBonificado, subtotalNeto,
		iva21, iva27, per3337, iva2, percepcion212, percepcioniibb, internos,
		subtotalFinal, fechaActualizacion'

	BEGIN TRY
		-- Same as silver.VentasResumen: CETAS is temporary. One external table reads every
		-- month through Year=*/Month=*/*.parquet. A new generation folder keeps the previous
		-- snapshot readable until the table is repointed.
		IF OBJECT_ID(N'agg.VentasVendedorDiario') IS NULL
			SET @Full = 1

		-- Serverless temp tables cannot be used in queries that read files: keep the month list
		-- as a comma-separated string of yyyyMM keys.
		IF @Full = 1
			SET @MonthList = (
				SELECT STRING_AGG(CAST(q.MonthKey AS VARCHAR(MAX)), ',')
				FROM (
					SELECT DISTINCT CAST(r.filepath(1) AS INT) * 100 + CAST(r.filepath(2) AS INT) AS MonthKey
					FROM OPENROWSET(
						BULK 'chess/parquet_files/ventasresumen/Year=*/Month=*/Day=*/Ver=*/*/*.parquet',
						DATA_SOURCE = 'eds_delfos',
						FORMAT = 'PARQUET') AS r
				) q)
		ELSE
		BEGIN
			SET @MonthList = (
				SELECT STRING_AGG(CAST(q.MonthKey AS VARCHAR(MAX)), ',')
				FROM (
					SELECT DISTINCT YEAR(fechaComprobate) * 100 + MONTH(fechaComprobate) AS MonthKey
					FROM bronze.VentasResumen
					WHERE fechaComprobate IS NOT NULL
				) q)

			SET @ExistingList = (
				SELECT STRING_AGG(CAST(q.MonthKey AS VARCHAR(MAX)), ',')
				FROM (
					SELECT DISTINCT [Year] * 100 + [Month] AS MonthKey
					FROM agg.VentasVendedorDiario
				) q)
		END

		SET @MonthCount = ISNULL((LEN(@MonthList) + 1) / 7, 0)
		SET @ExistingCount = ISNULL((LEN(@ExistingList) + 1) / 7, 0)

		WHILE @MonthIndex < @MonthCount
		BEGIN
			SET @MonthIndex = @MonthIndex + 1
			SET @MonthKey = SUBSTRING(@MonthList, (@MonthIndex - 1) * 7 + 1, 6)
			SET @Year = CAST(LEFT(@MonthKey, 4) AS INT)
			SET @Month = CAST(RIGHT(@MonthKey, 2) AS INT)
			SET @folderName = CONCAT('/chess/parquet_files/agg/ventasvendedordiario/', @dateFormat,
				'/Year=', CAST(@Year AS VARCHAR(4)), '/Month=', CAST(@Month AS VARCHAR(2)), '/')

			EXEC helpers.DropExternalTable @BuildTable

			-- Reads only this month's silver folders. Safe because an invoice never changes date,
			-- so all its versions live in the same Year/Month/Day folder.
			SET @Sql = 'CREATE EXTERNAL TABLE ' + @BuildTable + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
				SELECT
					CONVERT(date, v.fechaComprobate) AS fecha,
					' + CAST(@Year AS VARCHAR(4)) + ' AS [Year],
					' + CAST(@Month AS VARCHAR(2)) + ' AS [Month],
					v.idEmpresa,
					MAX(v.dsEmpresa) AS dsEmpresa,
					v.idSucursal,
					MAX(v.dsSucursal) AS dsSucursal,
					v.idSupervisor,
					MAX(v.dsSupervisor) AS dsSupervisor,
					v.idVendedor,
					MAX(v.dsVendedor) AS dsVendedor,
					COUNT(DISTINCT CONCAT(
						CAST(v.letra AS nvarchar(10)), N''|'',
						CAST(v.serie AS nvarchar(20)), N''|'',
						CAST(v.nrodoc AS nvarchar(20)), N''|'',
						CAST(v.idDocumento AS nvarchar(20)), N''|'',
						CAST(v.idSucursal AS nvarchar(20)), N''|'',
						CAST(v.idEmpresa AS nvarchar(20)))) AS nroComprobantes,
					COUNT(DISTINCT v.idCliente) AS nroClientes,
					CAST(SUM(ISNULL(v.subtotalBruto, 0)) AS decimal(18, 4)) AS subtotalBruto,
					CAST(SUM(ISNULL(v.subtotalBonificado, 0)) AS decimal(18, 4)) AS subtotalBonificado,
					CAST(SUM(ISNULL(v.subtotalNeto, 0)) AS decimal(18, 4)) AS subtotalNeto,
					CAST(SUM(ISNULL(v.iva21, 0)) AS decimal(18, 4)) AS iva21,
					CAST(SUM(ISNULL(v.iva27, 0)) AS decimal(18, 4)) AS iva27,
					CAST(SUM(ISNULL(v.per3337, 0)) AS decimal(18, 4)) AS per3337,
					CAST(SUM(ISNULL(v.iva2, 0)) AS decimal(18, 4)) AS iva2,
					CAST(SUM(ISNULL(v.percepcion212, 0)) AS decimal(18, 4)) AS percepcion212,
					CAST(SUM(ISNULL(v.percepcioniibb, 0)) AS decimal(18, 4)) AS percepcioniibb,
					CAST(SUM(ISNULL(v.internos, 0)) AS decimal(18, 4)) AS internos,
					CAST(SUM(ISNULL(v.subtotalFinal, 0)) AS decimal(18, 4)) AS subtotalFinal,
					CAST(''' + @fechaActualizacion + ''' AS datetime2) AS fechaActualizacion
				FROM (
					SELECT
						r.*,
						ROW_NUMBER() OVER (
							PARTITION BY r.letra, r.serie, r.nrodoc, r.idDocumento, r.idSucursal, r.idEmpresa, r.idLinea, r.idArticulo
							ORDER BY r.Ver DESC) AS rn
					FROM OPENROWSET(
						BULK ''chess/parquet_files/ventasresumen/Year=' + CAST(@Year AS VARCHAR(4)) + '/Month=' + CAST(@Month AS VARCHAR(2)) + '/Day=*/Ver=*/*/*.parquet'',
						DATA_SOURCE = ''eds_delfos'',
						FORMAT = ''PARQUET'')
					WITH (
						idEmpresa int,
						dsEmpresa nvarchar(100),
						idDocumento nvarchar(10),
						letra nvarchar(2),
						serie int,
						nrodoc int,
						anulado bit,
						fechaComprobate datetime,
						idSucursal int,
						dsSucursal nvarchar(100),
						idVendedor int,
						dsVendedor nvarchar(100),
						idSupervisor int,
						dsSupervisor nvarchar(100),
						idCliente int,
						idLinea int,
						idArticulo int,
						subtotalBruto decimal(14, 4),
						subtotalBonificado decimal(14, 4),
						subtotalNeto decimal(14, 4),
						iva21 decimal(14, 4),
						iva27 decimal(14, 4),
						per3337 decimal(14, 4),
						iva2 decimal(14, 4),
						percepcion212 decimal(14, 4),
						percepcioniibb decimal(14, 4),
						internos decimal(14, 4),
						subtotalFinal decimal(14, 4),
						Ver int) AS r
					WHERE r.Ver <> 0
				) v
				WHERE v.rn = 1
				  AND ISNULL(v.anulado, 0) = 0
				GROUP BY
					CONVERT(date, v.fechaComprobate),
					v.idEmpresa,
					v.idSucursal,
					v.idSupervisor,
					v.idVendedor'
			EXEC (@Sql)
			EXEC helpers.DropExternalTable @BuildTable
		END

		WHILE @ExistingIndex < @ExistingCount
		BEGIN
			SET @ExistingIndex = @ExistingIndex + 1
			SET @MonthKey = SUBSTRING(@ExistingList, (@ExistingIndex - 1) * 7 + 1, 6)

			IF CHARINDEX(CONCAT(',', @MonthKey, ','), CONCAT(',', @MonthList, ',')) = 0
			BEGIN
				SET @Year = CAST(LEFT(@MonthKey, 4) AS INT)
				SET @Month = CAST(RIGHT(@MonthKey, 2) AS INT)
				SET @folderName = CONCAT('/chess/parquet_files/agg/ventasvendedordiario/', @dateFormat,
					'/Year=', CAST(@Year AS VARCHAR(4)), '/Month=', CAST(@Month AS VARCHAR(2)), '/')

				EXEC helpers.DropExternalTable @BuildTable

				SET @Sql = 'CREATE EXTERNAL TABLE ' + @BuildTable + ' WITH (LOCATION = ''' + @folderName + ''', DATA_SOURCE = eds_delfos, FILE_FORMAT = eff_delfos_parquet) AS
					SELECT ' + @Columns + '
					FROM agg.VentasVendedorDiario
					WHERE [Year] = ' + CAST(@Year AS VARCHAR(4)) + ' AND [Month] = ' + CAST(@Month AS VARCHAR(2))
				EXEC (@Sql)
				EXEC helpers.DropExternalTable @BuildTable
			END
		END

		IF @MonthCount > 0
		BEGIN
			IF EXISTS (
				SELECT 1
				FROM sys.views v
				INNER JOIN sys.schemas s ON s.schema_id = v.schema_id
				WHERE s.name = 'agg' AND v.name = 'VentasVendedorDiario')
				DROP VIEW agg.VentasVendedorDiario

			EXEC helpers.DropExternalTable 'agg.VentasVendedorDiario'

			SET @Sql = 'CREATE EXTERNAL TABLE agg.VentasVendedorDiario (
					fecha date,
					[Year] int,
					[Month] int,
					idEmpresa int,
					dsEmpresa nvarchar(100),
					idSucursal int,
					dsSucursal nvarchar(100),
					idSupervisor int,
					dsSupervisor nvarchar(100),
					idVendedor int,
					dsVendedor nvarchar(100),
					nroComprobantes int,
					nroClientes int,
					subtotalBruto decimal(18, 4),
					subtotalBonificado decimal(18, 4),
					subtotalNeto decimal(18, 4),
					iva21 decimal(18, 4),
					iva27 decimal(18, 4),
					per3337 decimal(18, 4),
					iva2 decimal(18, 4),
					percepcion212 decimal(18, 4),
					percepcioniibb decimal(18, 4),
					internos decimal(18, 4),
					subtotalFinal decimal(18, 4),
					fechaActualizacion datetime2)
				WITH (
					LOCATION = ''chess/parquet_files/agg/ventasvendedordiario/' + @dateFormat + '/Year=*/Month=*/*.parquet'',
					DATA_SOURCE = eds_delfos,
					FILE_FORMAT = eff_delfos_parquet)'
			EXEC (@Sql)

			SET @OldTableName = (
				SELECT TOP 1 CONCAT('agg.', et.name)
				FROM sys.external_tables et
				INNER JOIN sys.schemas s ON s.schema_id = et.schema_id
				WHERE s.name = 'agg'
				  AND et.name LIKE 'VentasVendedorDiario[_]%' )

			WHILE @OldTableName IS NOT NULL
			BEGIN
				EXEC helpers.DropExternalTable @OldTableName

				SET @OldTableName = (
					SELECT TOP 1 CONCAT('agg.', et.name)
					FROM sys.external_tables et
					INNER JOIN sys.schemas s ON s.schema_id = et.schema_id
					WHERE s.name = 'agg'
					  AND et.name LIKE 'VentasVendedorDiario[_]%' )
			END

			SET @ResultMessage = CONCAT(
				'Datos refrescados correctamente (', CASE WHEN @Full = 1 THEN 'completo, ' ELSE '' END,
				@MonthCount, ' meses: ', REPLACE(@MonthList, ',', ', '), ')')
		END
	END TRY
	BEGIN CATCH
		SET @ResultMessage = CONCAT('Error No: ', ERROR_NUMBER(), ' Message: ', ERROR_MESSAGE())

		BEGIN TRY
			EXEC helpers.DropExternalTable @BuildTable
		END TRY
		BEGIN CATCH
		END CATCH
	END CATCH

	SELECT @StartDateProc, GETDATE(), 'agg.spVentasVendedorDiario_Refresh' AS ProcedureName, @ResultMessage AS LogMessage
END
