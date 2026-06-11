CREATE OR ALTER VIEW gold.DsStock
AS
SELECT
	s.fecha, s.idDeposito, s.idAlmacen, s.idArticulo, s.dsArticulo,
	s.fecVtoLote, s.cantBultos, s.cantUnidades, s.Ver
FROM silver.DsStock s
WHERE s.Ver <> 0
	AND s.Ver = (
		SELECT MAX(s2.Ver)
		FROM silver.DsStock s2
		WHERE s.fecha = s2.fecha
			AND s.idDeposito = s2.idDeposito
			AND s.idAlmacen = s2.idAlmacen
			AND s.idArticulo = s2.idArticulo
			AND ISNULL(s.fecVtoLote, '1900-01-01') = ISNULL(s2.fecVtoLote, '1900-01-01')
	)
