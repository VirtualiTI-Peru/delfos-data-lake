CREATE OR ALTER VIEW gold.CuotaCobertura
AS
SELECT
	a.idSucursal,
	a.idPersonal,
	a.periodo,
	a.cuota_calculada,
	a.cuota,
	a.[Year],
	a.[Month],
	a.Ver
FROM silver.CuotaCobertura a
WHERE a.Ver <> 0
  AND a.Ver = (
	SELECT MAX(a2.Ver)
	FROM silver.CuotaCobertura a2
	WHERE a.idSucursal = a2.idSucursal
	  AND a.idPersonal = a2.idPersonal
	  AND a.periodo = a2.periodo
  )
