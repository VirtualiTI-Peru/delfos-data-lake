CREATE OR ALTER VIEW gold.CuotaVentas
AS
SELECT
	a.idSucursal,
	a.idPersonal,
	a.periodo,
	a.idAgrupacion,
	a.cuota,
	a.[Year],
	a.[Month],
	a.Ver
FROM silver.CuotaVentas a
WHERE a.Ver <> 0
  AND a.Ver = (
	SELECT MAX(a2.Ver)
	FROM silver.CuotaVentas a2
	WHERE a.idSucursal = a2.idSucursal
	  AND a.idPersonal = a2.idPersonal
	  AND a.periodo = a2.periodo
	  AND a.idAgrupacion = a2.idAgrupacion
  )
