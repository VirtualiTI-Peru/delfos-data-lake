CREATE OR ALTER VIEW gold.PersCom
AS
SELECT
	a.idSucursal,
	a.desSucursal,
	a.idPersonal,
	a.desPersonal,
	a.idFuerzaVentas,
	a.desFuerzaVentas,
	a.cargo,
	a.tipoVenta,
	a.idPersonalSuperior,
	a.desPersonalSuperior,
	a.domicilio,
	a.telefono,
	a.fechaNacimiento,
	a.usuarioSistema,
	a.idTipoSegmento,
	a.desTipoSegmento,
	a.Ver
FROM silver.PersCom a
WHERE a.Ver <> 0
  AND a.Ver = (
	SELECT MAX(a2.Ver)
	FROM silver.PersCom a2
	WHERE a.idSucursal = a2.idSucursal
	  AND a.idPersonal = a2.idPersonal
  )
