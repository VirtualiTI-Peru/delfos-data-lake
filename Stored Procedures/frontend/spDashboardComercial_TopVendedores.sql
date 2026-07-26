CREATE OR ALTER PROCEDURE frontend.spDashboardComercial_TopVendedores
    @From date,
    @To   date,
    @Top  int = 10
AS
BEGIN
    SET NOCOUNT ON;

    IF @Top IS NULL OR @Top < 1
        SET @Top = 10;

    SELECT TOP (@Top)
        idVendedor,
        dsVendedor,
        CAST(SUM(ISNULL(subtotalNeto, 0)) AS decimal(18, 4)) AS ventaNeta,
        CAST(SUM(ISNULL(cantidadesTotal, 0)) AS decimal(18, 4)) AS unidades
    FROM gold.VentasResumen
    WHERE ISNULL(anulado, 0) = 0
      AND CONVERT(date, fechaComprobate, 103) >= @From
      AND CONVERT(date, fechaComprobate, 103) <= @To
    GROUP BY idVendedor, dsVendedor
    ORDER BY ventaNeta DESC;
END
GO
