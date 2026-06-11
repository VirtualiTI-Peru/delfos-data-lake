CREATE OR ALTER VIEW gold.CanalesMkt
AS
SELECT a.idCanalMkt, a.desCanalMkt, a.idSegmentoMkt, a.compania, a.Ver
FROM silver.CanalesMkt a
WHERE a.Ver <> 0 AND a.Ver = (SELECT MAX(a2.Ver) FROM silver.CanalesMkt a2 WHERE a.idCanalMkt = a2.idCanalMkt)
