CREATE OR ALTER VIEW gold.VentasResumen
AS
SELECT
	Fact.idEmpresa, dsEmpresa, Fact.idDocumento, dsDocumento, Fact.letra, Fact.serie, Fact.nrodoc,
	pickup, anulado, idMovComercial, dsMovComercial, idRechazo, dsRechazo, fechaComprobate,
	fechaAnulacion, fechaAlta, usuarioAlta, fechaVencimiento, fechaEntrega, Fact.idSucursal,
	dsSucursal, idFuerzaVentas, dsFuerzaVentas, idDeposito, dsDeposito, idVendedor, dsVendedor,
	idSupervisor, dsSupervisor, idGerente, dsGerente, tipoConstribuyente, dsTipoConstribuyente,
	idTipoPago, dsTipoPago, fechaPago, idPedido, fechaPedido, origen, idorigen, planillaCarga,
	idFleteroCarga, dsFleteroCarga, idLiquidacion, fechaLiquidacion, idCaja, fechaCaja, cajero,
	idCliente, nombreCliente, domicilioCliente, codigoPostal, dsLocalidad, idProvincia, dsProvincia,
	idNegocio, dsNegocio, idAgrupacion, dsAgrupacion, idArea, dsArea, idSegmentoMkt, dsSegmentoMkt,
	idCanalMkt, dsCanalMkt, idSubcanalMkt, dsSubcanalMKT, Fact.idLinea, Fact.idArticulo, dsArticulo,
	idConcepto, dsConcepto, esCombo, idCombo, idArticuloEstadistico, dsArticuloEstadistico,
	presentacionArticulo, cantidadPorPallets, peso, fechaAsientoContable, nroAsientoContable,
	nroPlanContable, codCuentaContable, idCentroCosto, dsCuentaContable, cantidadSolicitada,
	unidadesSolicitadas, cantidadesCorCargo, cantidadesSinCargo, cantidadesTotal, pesoTotal,
	cantidadesRechazo, unimedcargo, unimedscargo, unimedtotal, precioUnitarioBruto, bonificacion,
	precioUnitarioNeto, subtotalBruto, subtotalBonificado, subtotalNeto, iva21, iva27, per3337,
	iva2, percepcion212, percepcioniibb, internos, subtotalFinal, tradespendg, tradespends,
	tradespendb, tradespendi, tradespendp, tradespendt, totradspend, acciones, persiibbd,
	persiibbr, numerosserie, numerosactivo, cuentayorden, codprovcyo, descrip, nrorendcyo,
	idTipoCambio, dsTipoCambio, cfdiEmitido, regimenFiscal, informado, firmadigital, proveedor,
	fvigpcompra, preciocomprabr, preciocomprant, lineaCredito, tipocambio, motivocambio,
	descmotcambio, numeracionFiscal, codproviibb, TipoId, DescripcionId, Identificador, Fact.Ver
FROM silver.VentasResumen Fact
INNER JOIN (
	SELECT Letra, NroDoc, Serie, IdDocumento, idSucursal, IdEmpresa, idLinea, idArticulo, MAX(Ver) AS Ver
	FROM silver.VentasResumen
	GROUP BY Letra, NroDoc, Serie, IdDocumento, idSucursal, IdEmpresa, idLinea, idArticulo
) AS LastVer
	ON ISNULL(Fact.Letra, '') = ISNULL(LastVer.Letra, '')
	AND Fact.NroDoc = LastVer.NroDoc
	AND Fact.Serie = LastVer.Serie
	AND Fact.IdDocumento = LastVer.IdDocumento
	AND Fact.idSucursal = LastVer.idSucursal
	AND Fact.IdEmpresa = LastVer.IdEmpresa
	AND Fact.idLinea = LastVer.idLinea
	AND Fact.idArticulo = LastVer.idArticulo
	AND Fact.Ver = LastVer.Ver
