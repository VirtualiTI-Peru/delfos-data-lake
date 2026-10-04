CREATE OR ALTER VIEW gold.DiasNoLaborables
AS
SELECT
	a.fecha,
	a.tipo,
	a.descripcion,
	a.[Year],
	a.[Month],
	a.anulado,
	a.Ver
FROM silver.DiasNoLaborables a
WHERE a.Ver <> 0
  AND a.Ver = (
	SELECT MAX(a2.Ver)
	FROM silver.DiasNoLaborables a2
	WHERE a.fecha = a2.fecha
  )
