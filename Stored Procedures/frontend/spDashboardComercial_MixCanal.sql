CREATE OR ALTER PROCEDURE frontend.spDashboardComercial_MixCanal
    @From date,
    @To   date
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        idCanalMkt,
        ISNULL(NULLIF(LTRIM(RTRIM(dsCanalMkt)), N''), N'(Sin canal)') AS dsCanalMkt,
        CAST(SUM(ISNULL(subtotalNeto, 0)) AS decimal(18, 4)) AS ventaNeta,
        CAST(SUM(ISNULL(cantidadesTotal, 0)) AS decimal(18, 4)) AS unidades
    FROM gold.VentasResumen
    WHERE ISNULL(anulado, 0) = 0
      AND CONVERT(date, fechaComprobate, 103) >= @From
      AND CONVERT(date, fechaComprobate, 103) <= @To
    GROUP BY idCanalMkt, ISNULL(NULLIF(LTRIM(RTRIM(dsCanalMkt)), N''), N'(Sin canal)')
    ORDER BY ventaNeta DESC;
END
GO
