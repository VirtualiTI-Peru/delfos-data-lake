/*
  Vistas de consumo para BI en el schema frontend.
  Exponen solo columnas de negocio desde gold.
*/
CREATE OR ALTER VIEW frontend.vwVentasResumen
AS
SELECT
	idEmpresa, dsEmpresa, idDocumento, letra, serie, nrodoc, fechaComprobate,
	idSucursal, dsSucursal, idCliente, nombreCliente, idLinea, idArticulo, dsArticulo,
	cantidadesTotal, subtotalNeto, subtotalFinal, anulado
FROM gold.VentasResumen;
GO

CREATE OR ALTER VIEW frontend.vwCliente
AS
SELECT
	idCliente, desSucursal, desProvincia, desLocalidad, desCanalMkt, desSegmentoMkt,
	desSubcanalMkt, desAgrupacion, anulado, email, telefonoMovil
FROM gold.Cliente;
GO

CREATE OR ALTER VIEW frontend.vwArticulo
AS
SELECT
	idArticulo, desArticulo, desCortaArticulo, anulado, esCombo, idArticuloEstadistico,
	desPresentacionBulto, pesoBulto
FROM gold.Articulo;
GO

CREATE OR ALTER VIEW frontend.vwDsStock
AS
SELECT fecha, idDeposito, idAlmacen, idArticulo, dsArticulo, cantBultos, cantUnidades
FROM gold.DsStock;
GO

CREATE OR ALTER VIEW frontend.vwAgrupacionArticulo
AS
SELECT * FROM gold.Articulo_Agrupacion;
GO
