DECLARE @StartDate DATE
DECLARE @EndDate DATE
DECLARE @Date DATE
DECLARE @Year INT
DECLARE @Month INT
DECLARE @Day INT
DECLARE @SQL NVARCHAR(MAX)
DECLARE @Version INT
DECLARE @dateFormat VARCHAR(14) = '00000000000000'
DECLARE @folderName VARCHAR(100)
DECLARE @ColumnSelect NVARCHAR(MAX)
DECLARE @ErrorNum INT
DECLARE @TempTableName VARCHAR(128)
DECLARE @FechaStr VARCHAR(10)

DROP TABLE IF EXISTS #Dates
CREATE TABLE #Dates (FechaFac DATE)
INSERT INTO #Dates EXEC helpers.spGetDatesToUpdate 'VentasResumen'

SET @StartDate = (SELECT MIN(FechaFac) FROM #Dates)
SET @EndDate = (SELECT MAX(FechaFac) FROM #Dates)
SET @Date = @StartDate

WHILE @Date IS NOT NULL AND @Date <= @EndDate
BEGIN
	SET @Year = YEAR(@Date)
	SET @Month = MONTH(@Date)
	SET @Day = DAY(@Date)
	SET @Version = 0
	SET @folderName = CONCAT('/chess/parquet_files/ventasresumen/Year=',
		CAST(@Year AS VARCHAR(4)), '/Month=', CAST(@Month AS VARCHAR(2)),
		'/Day=', CAST(@Day AS VARCHAR(2)), '/Ver=', CAST(@Version AS VARCHAR(10)), '/', @dateFormat, '/')
	SET @TempTableName = 'VentasResumen' + CAST(@Year AS VARCHAR(4)) + CAST(@Month AS VARCHAR(2)) + CAST(@Day AS VARCHAR(2)) + '#v' + CAST(@Version AS VARCHAR(10))
	SET @FechaStr = CONVERT(VARCHAR(10), @Date, 23)
	EXEC helpers.spVentasResumen_NullSelect @Fecha = @FechaStr, @Ver = @Version, @ColumnSelect = @ColumnSelect OUTPUT

	SET @SQL = '
		CREATE EXTERNAL TABLE ' + @TempTableName + '
		WITH (
			LOCATION = ''' + @folderName + ''',
			DATA_SOURCE = eds_delfos,
			FILE_FORMAT = eff_delfos_parquet
		)
		AS
		SELECT ' + @ColumnSelect

	BEGIN TRY
		EXEC (@SQL)
	END TRY
	BEGIN CATCH
		SET @ErrorNum = ERROR_NUMBER()
		IF @ErrorNum <> 15842 THROW
	END CATCH

	IF EXISTS (SELECT 1 FROM sys.external_tables WHERE object_id = OBJECT_ID(@TempTableName))
	BEGIN
		SET @SQL = 'DROP EXTERNAL TABLE ' + @TempTableName
		EXEC (@SQL)
	END

	IF NOT EXISTS (SELECT 1 FROM sys.external_tables WHERE object_id = OBJECT_ID('silver.VentasResumen'))
	BEGIN
		CREATE EXTERNAL TABLE silver.VentasResumen (
			idEmpresa int, dsEmpresa nvarchar(100), idDocumento nvarchar(10), dsDocumento nvarchar(50),
			letra nvarchar(2), serie int, nrodoc int, pickup nvarchar(2), anulado nvarchar(2),
			idMovComercial int, dsMovComercial nvarchar(100), idRechazo int, dsRechazo nvarchar(100),
			fechaComprobate datetime, fechaAnulacion date, fechaAlta date, usuarioAlta nvarchar(100),
			fechaVencimiento date, fechaEntrega date, idSucursal int, dsSucursal nvarchar(100),
			idFuerzaVentas int, dsFuerzaVentas nvarchar(100), idDeposito int, dsDeposito nvarchar(100),
			idVendedor int, dsVendedor nvarchar(100), idSupervisor int, dsSupervisor nvarchar(100),
			idGerente int, dsGerente nvarchar(100), tipoConstribuyente nvarchar(100), dsTipoConstribuyente nvarchar(100),
			idTipoPago int, dsTipoPago nvarchar(100), fechaPago date, idPedido int, fechaPedido date,
			origen nvarchar(100), idorigen nvarchar(100), planillaCarga nvarchar(100), idFleteroCarga int,
			dsFleteroCarga nvarchar(100), idLiquidacion int, fechaLiquidacion date, idCaja int, fechaCaja date,
			cajero nvarchar(100), idCliente int, nombreCliente nvarchar(100), domicilioCliente nvarchar(500),
			codigoPostal int, dsLocalidad nvarchar(100), idProvincia nvarchar(100), dsProvincia nvarchar(100),
			idNegocio int, dsNegocio nvarchar(100), idAgrupacion int, dsAgrupacion nvarchar(100),
			idArea int, dsArea nvarchar(100), idSegmentoMkt int, dsSegmentoMkt nvarchar(100),
			idCanalMkt int, dsCanalMkt nvarchar(100), idSubcanalMkt int, dsSubcanalMKT nvarchar(100),
			idLinea int, idArticulo int, dsArticulo nvarchar(100), idConcepto int, dsConcepto nvarchar(100),
			esCombo nvarchar(100), idCombo int, idArticuloEstadistico int, dsArticuloEstadistico nvarchar(100),
			presentacionArticulo int, cantidadPorPallets int, peso decimal(14, 4),
			fechaAsientoContable date, nroAsientoContable int, nroPlanContable int, codCuentaContable int,
			idCentroCosto int, dsCuentaContable nvarchar(100), cantidadSolicitada int, unidadesSolicitadas int,
			cantidadesCorCargo decimal(14, 4), cantidadesSinCargo decimal(14, 4), cantidadesTotal decimal(14, 4),
			pesoTotal decimal(14, 4), cantidadesRechazo decimal(14, 4), unimedcargo decimal(14, 4),
			unimedscargo decimal(14, 4), unimedtotal decimal(14, 4), precioUnitarioBruto decimal(14, 4),
			bonificacion decimal(14, 4), precioUnitarioNeto decimal(14, 4), subtotalBruto decimal(14, 4),
			subtotalBonificado decimal(14, 4), subtotalNeto decimal(14, 4), iva21 decimal(14, 4),
			iva27 decimal(14, 4), per3337 decimal(14, 4), iva2 decimal(14, 4), percepcion212 decimal(14, 4),
			percepcioniibb decimal(14, 4), internos decimal(14, 4), subtotalFinal decimal(14, 4),
			tradespendg decimal(14, 4), tradespends decimal(14, 4), tradespendb decimal(14, 4),
			tradespendi decimal(14, 4), tradespendp decimal(14, 4), tradespendt decimal(14, 4),
			totradspend decimal(14, 4), acciones nvarchar(100), persiibbd nvarchar(100), persiibbr nvarchar(100),
			numerosserie nvarchar(100), numerosactivo nvarchar(100), cuentayorden nvarchar(100),
			codprovcyo int, descrip nvarchar(100), nrorendcyo int, idTipoCambio int, dsTipoCambio nvarchar(100),
			cfdiEmitido nvarchar(100), regimenFiscal nvarchar(100), informado nvarchar(100),
			firmadigital nvarchar(100), proveedor nvarchar(100), fvigpcompra nvarchar(100),
			preciocomprabr decimal(14, 4), preciocomprant decimal(14, 4), lineaCredito nvarchar(100),
			tipocambio nvarchar(100), motivocambio int, descmotcambio nvarchar(100),
			numeracionFiscal nvarchar(100), codproviibb nvarchar(100), TipoId int,
			DescripcionId nvarchar(100), Identificador nvarchar(100), Ver INT)
		WITH (
			LOCATION = 'chess/parquet_files/ventasresumen/Year=*/Month=*/Day=*/Ver=*/*/*.parquet',
			DATA_SOURCE = eds_delfos,
			FILE_FORMAT = eff_delfos_parquet
		)
	END

	SET @Date = DATEADD(day, 1, @Date)
END
