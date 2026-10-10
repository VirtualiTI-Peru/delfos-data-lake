CREATE OR ALTER VIEW gold.RutasVenta
AS
SELECT
	d.idSucursal,
	d.desSucursal,
	d.idFuerzaVentas,
	d.desFuerzaVentas,
	d.idModoAtencion,
	d.desModoAtencion,
	d.idRuta,
	d.desRuta,
	d.fechaDesde,
	d.fechaHasta,
	d.anulado,
	d.idPersonal,
	d.desPersonal,
	d.periodicidadVisita,
	d.semanaVisita,
	d.diasVisita,
	d.periodicidadEntrega,
	d.semanaEntrega,
	d.diasEntrega,
	d.IdRutaAuto,
	d.Ver
FROM (
	SELECT
		a.*,
		ROW_NUMBER() OVER (
			PARTITION BY a.idSucursal, a.idFuerzaVentas, a.idRuta, a.idPersonal
			ORDER BY a.Ver DESC, ISNULL(a.anulado, 0)
		) AS rn
	FROM silver.RutasVenta a
	WHERE a.Ver <> 0
) d
WHERE d.rn = 1
