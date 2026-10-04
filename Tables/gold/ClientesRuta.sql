CREATE OR ALTER VIEW gold.ClientesRuta
AS
SELECT
	d.idCliente,
	d.razonSocial,
	d.intercalacionVisita,
	d.intercalacionEntrega,
	d.idRuta,
	d.anulado,
	d.Ver
FROM (
	SELECT
		a.*,
		ROW_NUMBER() OVER (
			PARTITION BY a.idCliente, a.idRuta
			ORDER BY
				a.Ver DESC,
				ISNULL(a.anulado, 0),
				ISNULL(a.intercalacionVisita, 0),
				ISNULL(a.intercalacionEntrega, 0),
				ISNULL(a.razonSocial, '')
		) AS rn
	FROM silver.ClientesRuta a
	WHERE a.Ver <> 0
) d
WHERE d.rn = 1
