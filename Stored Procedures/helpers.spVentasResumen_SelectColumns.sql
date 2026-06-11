CREATE OR ALTER PROCEDURE helpers.spVentasResumen_BronzeSelect
    @TableAlias NVARCHAR(10),
    @VerExpression NVARCHAR(100),
    @ColumnSelect NVARCHAR(MAX) OUTPUT
AS
BEGIN
    DECLARE @a NVARCHAR(12) = @TableAlias + N'.';
    SET @ColumnSelect =
        CAST(@a + N'idEmpresa,' AS NVARCHAR(MAX)) + @a + N'dsEmpresa,' + @a + N'idDocumento,' + @a + N'dsDocumento,' +
        @a + N'letra,' + @a + N'serie,' + @a + N'nrodoc,' + @a + N'pickup,' + @a + N'anulado,' +
        @a + N'idMovComercial,' + @a + N'dsMovComercial,' + @a + N'idRechazo,' + @a + N'dsRechazo,' +
        @a + N'fechaComprobate,' + @a + N'fechaAnulacion,' + @a + N'fechaAlta,' + @a + N'usuarioAlta,' +
        @a + N'fechaVencimiento,' + @a + N'fechaEntrega,' + @a + N'idSucursal,' + @a + N'dsSucursal,' +
        @a + N'idFuerzaVentas,' + @a + N'dsFuerzaVentas,' + @a + N'idDeposito,' + @a + N'dsDeposito,' +
        @a + N'idVendedor,' + @a + N'dsVendedor,' + @a + N'idSupervisor,' + @a + N'dsSupervisor,' +
        @a + N'idGerente,' + @a + N'dsGerente,' + @a + N'tipoConstribuyente,' + @a + N'dsTipoConstribuyente,' +
        @a + N'idTipoPago,' + @a + N'dsTipoPago,' + @a + N'fechaPago,' + @a + N'idPedido,' + @a + N'fechaPedido,' +
        @a + N'origen,' + @a + N'idorigen,' + @a + N'planillaCarga,' + @a + N'idFleteroCarga,' + @a + N'dsFleteroCarga,' +
        @a + N'idLiquidacion,' + @a + N'fechaLiquidacion,' + @a + N'idCaja,' + @a + N'fechaCaja,' + @a + N'cajero,' +
        @a + N'idCliente,' + @a + N'nombreCliente,' + @a + N'domicilioCliente,' + @a + N'codigoPostal,' + @a + N'dsLocalidad,' +
        @a + N'idProvincia,' + @a + N'dsProvincia,' + @a + N'idNegocio,' + @a + N'dsNegocio,' +
        @a + N'idAgrupacion,' + @a + N'dsAgrupacion,' + @a + N'idArea,' + @a + N'dsArea,' +
        @a + N'idSegmentoMkt,' + @a + N'dsSegmentoMkt,' + @a + N'idCanalMkt,' + @a + N'dsCanalMkt,' +
        @a + N'idSubcanalMkt,' + @a + N'dsSubcanalMKT,' + @a + N'idLinea,' + @a + N'idArticulo,' + @a + N'dsArticulo,' +
        @a + N'idConcepto,' + @a + N'dsConcepto,' + @a + N'esCombo,' + @a + N'idCombo,' +
        @a + N'idArticuloEstadistico,' + @a + N'dsArticuloEstadistico,' + @a + N'presentacionArticulo,' + @a + N'cantidadPorPallets,' + @a + N'peso,' +
        @a + N'fechaAsientoContable,' + @a + N'nroAsientoContable,' + @a + N'nroPlanContable,' + @a + N'codCuentaContable,' +
        @a + N'idCentroCosto,' + @a + N'dsCuentaContable,' + @a + N'cantidadSolicitada,' + @a + N'unidadesSolicitadas,' +
        @a + N'cantidadesCorCargo,' + @a + N'cantidadesSinCargo,' + @a + N'cantidadesTotal,' + @a + N'pesoTotal,' + @a + N'cantidadesRechazo,' +
        @a + N'unimedcargo,' + @a + N'unimedscargo,' + @a + N'unimedtotal,' + @a + N'precioUnitarioBruto,' + @a + N'bonificacion,' +
        @a + N'precioUnitarioNeto,' + @a + N'subtotalBruto,' + @a + N'subtotalBonificado,' + @a + N'subtotalNeto,' +
        @a + N'iva21,' + @a + N'iva27,' + @a + N'per3337,' + @a + N'iva2,' + @a + N'percepcion212,' + @a + N'percepcioniibb,' +
        @a + N'internos,' + @a + N'subtotalFinal,' + @a + N'tradespendg,' + @a + N'tradespends,' + @a + N'tradespendb,' +
        @a + N'tradespendi,' + @a + N'tradespendp,' + @a + N'tradespendt,' + @a + N'totradspend,' +
        @a + N'acciones,' + @a + N'persiibbd,' + @a + N'persiibbr,' + @a + N'numerosserie,' + @a + N'numerosactivo,' +
        @a + N'cuentayorden,' + @a + N'codprovcyo,' + @a + N'descrip,' + @a + N'nrorendcyo,' +
        @a + N'idTipoCambio,' + @a + N'dsTipoCambio,' + @a + N'cfdiEmitido,' + @a + N'regimenFiscal,' +
        @a + N'informado,' + @a + N'firmadigital,' + @a + N'proveedor,' + @a + N'fvigpcompra,' +
        @a + N'preciocomprabr,' + @a + N'preciocomprant,' + @a + N'lineaCredito,' + @a + N'tipocambio,' +
        @a + N'motivocambio,' + @a + N'descmotcambio,' + @a + N'numeracionFiscal,' + @a + N'codproviibb,' +
        @a + N'TipoId,' + @a + N'DescripcionId,' + @a + N'Identificador,' + @VerExpression + N' AS Ver';
END
GO

CREATE OR ALTER PROCEDURE helpers.spVentasResumen_NullSelect
    @Fecha VARCHAR(10),
    @Ver INT,
    @ColumnSelect NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET @ColumnSelect =
        CAST(N'CAST(NULL AS int) AS idEmpresa,' AS NVARCHAR(MAX)) +
        N'CAST(NULL AS nvarchar(100)) AS dsEmpresa,' +
        N'CAST(NULL AS nvarchar(10)) AS idDocumento,' +
        N'CAST(NULL AS nvarchar(50)) AS dsDocumento,' +
        N'CAST(NULL AS nvarchar(2)) AS letra,' +
        N'CAST(NULL AS int) AS serie,' +
        N'CAST(NULL AS int) AS nrodoc,' +
        N'CAST(NULL AS nvarchar(2)) AS pickup,' +
        N'CAST(NULL AS nvarchar(2)) AS anulado,' +
        N'CAST(NULL AS int) AS idMovComercial,' +
        N'CAST(NULL AS nvarchar(100)) AS dsMovComercial,' +
        N'CAST(NULL AS int) AS idRechazo,' +
        N'CAST(NULL AS nvarchar(100)) AS dsRechazo,' +
        N'CAST(''' + @Fecha + N''' AS datetime) AS fechaComprobate,' +
        N'CAST(NULL AS date) AS fechaAnulacion,' +
        N'CAST(NULL AS date) AS fechaAlta,' +
        N'CAST(NULL AS nvarchar(100)) AS usuarioAlta,' +
        N'CAST(NULL AS date) AS fechaVencimiento,' +
        N'CAST(NULL AS date) AS fechaEntrega,' +
        N'CAST(NULL AS int) AS idSucursal,' +
        N'CAST(NULL AS nvarchar(100)) AS dsSucursal,' +
        N'CAST(NULL AS int) AS idFuerzaVentas,' +
        N'CAST(NULL AS nvarchar(100)) AS dsFuerzaVentas,' +
        N'CAST(NULL AS int) AS idDeposito,' +
        N'CAST(NULL AS nvarchar(100)) AS dsDeposito,' +
        N'CAST(NULL AS int) AS idVendedor,' +
        N'CAST(NULL AS nvarchar(100)) AS dsVendedor,' +
        N'CAST(NULL AS int) AS idSupervisor,' +
        N'CAST(NULL AS nvarchar(100)) AS dsSupervisor,' +
        N'CAST(NULL AS int) AS idGerente,' +
        N'CAST(NULL AS nvarchar(100)) AS dsGerente,' +
        N'CAST(NULL AS nvarchar(100)) AS tipoConstribuyente,' +
        N'CAST(NULL AS nvarchar(100)) AS dsTipoConstribuyente,' +
        N'CAST(NULL AS int) AS idTipoPago,' +
        N'CAST(NULL AS nvarchar(100)) AS dsTipoPago,' +
        N'CAST(NULL AS date) AS fechaPago,' +
        N'CAST(NULL AS int) AS idPedido,' +
        N'CAST(NULL AS date) AS fechaPedido,' +
        N'CAST(NULL AS nvarchar(100)) AS origen,' +
        N'CAST(NULL AS nvarchar(100)) AS idorigen,' +
        N'CAST(NULL AS nvarchar(100)) AS planillaCarga,' +
        N'CAST(NULL AS int) AS idFleteroCarga,' +
        N'CAST(NULL AS nvarchar(100)) AS dsFleteroCarga,' +
        N'CAST(NULL AS int) AS idLiquidacion,' +
        N'CAST(NULL AS date) AS fechaLiquidacion,' +
        N'CAST(NULL AS int) AS idCaja,' +
        N'CAST(NULL AS date) AS fechaCaja,' +
        N'CAST(NULL AS nvarchar(100)) AS cajero,' +
        N'CAST(NULL AS int) AS idCliente,' +
        N'CAST(NULL AS nvarchar(100)) AS nombreCliente,' +
        N'CAST(NULL AS nvarchar(500)) AS domicilioCliente,' +
        N'CAST(NULL AS int) AS codigoPostal,' +
        N'CAST(NULL AS nvarchar(100)) AS dsLocalidad,' +
        N'CAST(NULL AS nvarchar(100)) AS idProvincia,' +
        N'CAST(NULL AS nvarchar(100)) AS dsProvincia,' +
        N'CAST(NULL AS int) AS idNegocio,' +
        N'CAST(NULL AS nvarchar(100)) AS dsNegocio,' +
        N'CAST(NULL AS int) AS idAgrupacion,' +
        N'CAST(NULL AS nvarchar(100)) AS dsAgrupacion,' +
        N'CAST(NULL AS int) AS idArea,' +
        N'CAST(NULL AS nvarchar(100)) AS dsArea,' +
        N'CAST(NULL AS int) AS idSegmentoMkt,' +
        N'CAST(NULL AS nvarchar(100)) AS dsSegmentoMkt,' +
        N'CAST(NULL AS int) AS idCanalMkt,' +
        N'CAST(NULL AS nvarchar(100)) AS dsCanalMkt,' +
        N'CAST(NULL AS int) AS idSubcanalMkt,' +
        N'CAST(NULL AS nvarchar(100)) AS dsSubcanalMKT,' +
        N'CAST(NULL AS int) AS idLinea,' +
        N'CAST(NULL AS int) AS idArticulo,' +
        N'CAST(NULL AS nvarchar(100)) AS dsArticulo,' +
        N'CAST(NULL AS int) AS idConcepto,' +
        N'CAST(NULL AS nvarchar(100)) AS dsConcepto,' +
        N'CAST(NULL AS nvarchar(100)) AS esCombo,' +
        N'CAST(NULL AS int) AS idCombo,' +
        N'CAST(NULL AS int) AS idArticuloEstadistico,' +
        N'CAST(NULL AS nvarchar(100)) AS dsArticuloEstadistico,' +
        N'CAST(NULL AS int) AS presentacionArticulo,' +
        N'CAST(NULL AS int) AS cantidadPorPallets,' +
        N'CAST(NULL AS decimal(14,4)) AS peso,' +
        N'CAST(NULL AS date) AS fechaAsientoContable,' +
        N'CAST(NULL AS int) AS nroAsientoContable,' +
        N'CAST(NULL AS int) AS nroPlanContable,' +
        N'CAST(NULL AS int) AS codCuentaContable,' +
        N'CAST(NULL AS int) AS idCentroCosto,' +
        N'CAST(NULL AS nvarchar(100)) AS dsCuentaContable,' +
        N'CAST(NULL AS int) AS cantidadSolicitada,' +
        N'CAST(NULL AS int) AS unidadesSolicitadas,' +
        N'CAST(NULL AS decimal(14,4)) AS cantidadesCorCargo,' +
        N'CAST(NULL AS decimal(14,4)) AS cantidadesSinCargo,' +
        N'CAST(NULL AS decimal(14,4)) AS cantidadesTotal,' +
        N'CAST(NULL AS decimal(14,4)) AS pesoTotal,' +
        N'CAST(NULL AS decimal(14,4)) AS cantidadesRechazo,' +
        N'CAST(NULL AS decimal(14,4)) AS unimedcargo,' +
        N'CAST(NULL AS decimal(14,4)) AS unimedscargo,' +
        N'CAST(NULL AS decimal(14,4)) AS unimedtotal,' +
        N'CAST(NULL AS decimal(14,4)) AS precioUnitarioBruto,' +
        N'CAST(NULL AS decimal(14,4)) AS bonificacion,' +
        N'CAST(NULL AS decimal(14,4)) AS precioUnitarioNeto,' +
        N'CAST(NULL AS decimal(14,4)) AS subtotalBruto,' +
        N'CAST(NULL AS decimal(14,4)) AS subtotalBonificado,' +
        N'CAST(NULL AS decimal(14,4)) AS subtotalNeto,' +
        N'CAST(NULL AS decimal(14,4)) AS iva21,' +
        N'CAST(NULL AS decimal(14,4)) AS iva27,' +
        N'CAST(NULL AS decimal(14,4)) AS per3337,' +
        N'CAST(NULL AS decimal(14,4)) AS iva2,' +
        N'CAST(NULL AS decimal(14,4)) AS percepcion212,' +
        N'CAST(NULL AS decimal(14,4)) AS percepcioniibb,' +
        N'CAST(NULL AS decimal(14,4)) AS internos,' +
        N'CAST(NULL AS decimal(14,4)) AS subtotalFinal,' +
        N'CAST(NULL AS decimal(14,4)) AS tradespendg,' +
        N'CAST(NULL AS decimal(14,4)) AS tradespends,' +
        N'CAST(NULL AS decimal(14,4)) AS tradespendb,' +
        N'CAST(NULL AS decimal(14,4)) AS tradespendi,' +
        N'CAST(NULL AS decimal(14,4)) AS tradespendp,' +
        N'CAST(NULL AS decimal(14,4)) AS tradespendt,' +
        N'CAST(NULL AS decimal(14,4)) AS totradspend,' +
        N'CAST(NULL AS nvarchar(100)) AS acciones,' +
        N'CAST(NULL AS nvarchar(100)) AS persiibbd,' +
        N'CAST(NULL AS nvarchar(100)) AS persiibbr,' +
        N'CAST(NULL AS nvarchar(100)) AS numerosserie,' +
        N'CAST(NULL AS nvarchar(100)) AS numerosactivo,' +
        N'CAST(NULL AS nvarchar(100)) AS cuentayorden,' +
        N'CAST(NULL AS int) AS codprovcyo,' +
        N'CAST(NULL AS nvarchar(100)) AS descrip,' +
        N'CAST(NULL AS int) AS nrorendcyo,' +
        N'CAST(NULL AS int) AS idTipoCambio,' +
        N'CAST(NULL AS nvarchar(100)) AS dsTipoCambio,' +
        N'CAST(NULL AS nvarchar(100)) AS cfdiEmitido,' +
        N'CAST(NULL AS nvarchar(100)) AS regimenFiscal,' +
        N'CAST(NULL AS nvarchar(100)) AS informado,' +
        N'CAST(NULL AS nvarchar(100)) AS firmadigital,' +
        N'CAST(NULL AS nvarchar(100)) AS proveedor,' +
        N'CAST(NULL AS nvarchar(100)) AS fvigpcompra,' +
        N'CAST(NULL AS decimal(14,4)) AS preciocomprabr,' +
        N'CAST(NULL AS decimal(14,4)) AS preciocomprant,' +
        N'CAST(NULL AS nvarchar(100)) AS lineaCredito,' +
        N'CAST(NULL AS nvarchar(100)) AS tipocambio,' +
        N'CAST(NULL AS int) AS motivocambio,' +
        N'CAST(NULL AS nvarchar(100)) AS descmotcambio,' +
        N'CAST(NULL AS nvarchar(100)) AS numeracionFiscal,' +
        N'CAST(NULL AS nvarchar(100)) AS codproviibb,' +
        N'CAST(NULL AS int) AS TipoId,' +
        N'CAST(NULL AS nvarchar(100)) AS DescripcionId,' +
        N'CAST(NULL AS nvarchar(100)) AS Identificador,' +
        N'CAST(' + CAST(@Ver AS NVARCHAR(10)) + N' AS INT) AS Ver';
END
GO
