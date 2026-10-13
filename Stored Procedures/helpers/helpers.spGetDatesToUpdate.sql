CREATE OR ALTER PROCEDURE [helpers].[spGetDatesToUpdate]
    @Table VARCHAR(20) = 'VentasResumen'
AS
BEGIN
    /*
      Retorna fechas distintas a procesar según la entidad.
      VentasResumen: fechas de comprobante.
      DsStock: fechas de snapshot de inventario.
    */
    IF @Table = 'DsStock'
    BEGIN
        SELECT DISTINCT CONVERT(date, s.fecha) AS FechaFac
        FROM bronze.DsStock s
        WHERE s.fecha IS NOT NULL
        ORDER BY 1;
    END
    ELSE
    BEGIN
        SELECT DISTINCT CONVERT(date, m.fechaComprobate, 103) AS FechaFac
        FROM bronze.VentasResumen m
        WHERE m.fechaComprobate IS NOT NULL
        ORDER BY 1;
    END
END
