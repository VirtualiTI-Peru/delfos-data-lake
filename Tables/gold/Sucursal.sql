CREATE OR ALTER VIEW gold.Sucursal
AS
SELECT DISTINCT
	a.idSucursal,
	a.desSucursal
FROM silver.PersCom a
WHERE a.Ver <> 0
  AND a.Ver = (
	SELECT MAX(a2.Ver)
	FROM silver.PersCom a2
	WHERE a.idSucursal = a2.idSucursal
	  AND a.idPersonal = a2.idPersonal
  )
