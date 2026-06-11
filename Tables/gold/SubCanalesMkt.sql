CREATE OR ALTER VIEW gold.SubCanalesMkt
AS
SELECT a.idSubcanalMkt, a.desSubcanalMkt, a.idCanalMkt, a.compania, a.Ver
FROM silver.SubCanalesMkt a
WHERE a.Ver <> 0 AND a.Ver = (SELECT MAX(a2.Ver) FROM silver.SubCanalesMkt a2 WHERE a.idSubcanalMkt = a2.idSubcanalMkt)
