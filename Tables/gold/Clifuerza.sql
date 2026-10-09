CREATE OR ALTER VIEW gold.Clifuerza
AS
SELECT
	d.idSucursal,
	d.idCliente,
	d.idFuerzaVentas,
	d.desFuerzaVenta,
	d.idModoAtencion,
	d.desModoAtencion,
	d.fechaInicioFuerza,
	d.fechaFinFuerza,
	d.idRuta,
	d.fechaRutaVenta,
	d.anulado,
	d.periodicidadVisita,
	d.semanaVisita,
	d.diasVisita,
	d.intercalacionVisita,
	d.perioricidadEntrega,
	d.semanaEntrega,
	d.diasEntrega,
	d.intercalacionEntrega,
	d.Horarios,
	d.Ver
FROM (
	SELECT
		a.*,
		ROW_NUMBER() OVER (
			PARTITION BY a.idSucursal, a.idCliente, a.idFuerzaVentas, a.idRuta
			ORDER BY a.Ver DESC, ISNULL(a.anulado, 0), a.fechaInicioFuerza DESC
		) AS rn
	FROM silver.Clifuerza a
	WHERE a.Ver <> 0
) d
WHERE d.rn = 1
