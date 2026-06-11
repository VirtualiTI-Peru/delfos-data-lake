CREATE OR ALTER VIEW gold.SegmentosMkt
AS
SELECT a.idSegmentoMkt, a.desSegmentoMkt, a.compania, a.Ver
FROM silver.SegmentosMkt a
WHERE a.Ver <> 0 AND a.Ver = (SELECT MAX(a2.Ver) FROM silver.SegmentosMkt a2 WHERE a.idSegmentoMkt = a2.idSegmentoMkt)
