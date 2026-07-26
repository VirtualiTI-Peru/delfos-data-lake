/*
  KPI resumen comercial para DevExpress (una fila).
  Período anterior = misma duración que [@From,@To], terminando el día previo a @From.
*/
CREATE OR ALTER PROCEDURE frontend.spDashboardComercial_Kpis
    @From date,
    @To   date
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Days int = DATEDIFF(day, @From, @To) + 1;
    DECLARE @PrevTo date = DATEADD(day, -1, @From);
    DECLARE @PrevFrom date = DATEADD(day, 1 - @Days, @PrevTo);

    ;WITH base AS (
        SELECT
            CONVERT(date, fechaComprobate, 103) AS Fecha,
            letra, serie, nrodoc, idDocumento, idSucursal, idEmpresa,
            ISNULL(subtotalNeto, 0) AS SubtotalNeto,
            ISNULL(cantidadesTotal, 0) AS CantidadesTotal
        FROM gold.VentasResumen
        WHERE ISNULL(anulado, 0) = 0
          AND CONVERT(date, fechaComprobate, 103) >= @PrevFrom
          AND CONVERT(date, fechaComprobate, 103) <= @To
    ),
    cur AS (
        SELECT
            SUM(SubtotalNeto) AS ventaNeta,
            SUM(CantidadesTotal) AS unidades,
            COUNT(DISTINCT CONCAT(
                CAST(letra AS nvarchar(10)), N'|',
                CAST(serie AS nvarchar(20)), N'|',
                CAST(nrodoc AS nvarchar(20)), N'|',
                CAST(idDocumento AS nvarchar(20)), N'|',
                CAST(idSucursal AS nvarchar(20)), N'|',
                CAST(idEmpresa AS nvarchar(20)))) AS nroComprobantes
        FROM base
        WHERE Fecha >= @From AND Fecha <= @To
    ),
    prev AS (
        SELECT
            SUM(SubtotalNeto) AS ventaNeta,
            SUM(CantidadesTotal) AS unidades,
            COUNT(DISTINCT CONCAT(
                CAST(letra AS nvarchar(10)), N'|',
                CAST(serie AS nvarchar(20)), N'|',
                CAST(nrodoc AS nvarchar(20)), N'|',
                CAST(idDocumento AS nvarchar(20)), N'|',
                CAST(idSucursal AS nvarchar(20)), N'|',
                CAST(idEmpresa AS nvarchar(20)))) AS nroComprobantes
        FROM base
        WHERE Fecha >= @PrevFrom AND Fecha <= @PrevTo
    )
    SELECT
        CAST(ISNULL(c.ventaNeta, 0) AS decimal(18, 4)) AS ventaNeta,
        CAST(ISNULL(c.unidades, 0) AS decimal(18, 4)) AS unidades,
        CAST(
            CASE WHEN ISNULL(c.nroComprobantes, 0) = 0 THEN 0
                 ELSE ISNULL(c.ventaNeta, 0) / c.nroComprobantes END
            AS decimal(18, 4)) AS ticketPromedio,
        ISNULL(c.nroComprobantes, 0) AS nroComprobantes,
        CAST(ISNULL(p.ventaNeta, 0) AS decimal(18, 4)) AS ventaNetaAnterior,
        CAST(ISNULL(p.unidades, 0) AS decimal(18, 4)) AS unidadesAnterior,
        CAST(
            CASE WHEN ISNULL(p.nroComprobantes, 0) = 0 THEN 0
                 ELSE ISNULL(p.ventaNeta, 0) / p.nroComprobantes END
            AS decimal(18, 4)) AS ticketPromedioAnterior,
        CAST(
            CASE WHEN ISNULL(p.ventaNeta, 0) = 0 THEN NULL
                 ELSE (ISNULL(c.ventaNeta, 0) - p.ventaNeta) / p.ventaNeta END
            AS decimal(18, 6)) AS varVentaNetaPct,
        CAST(
            CASE WHEN ISNULL(p.unidades, 0) = 0 THEN NULL
                 ELSE (ISNULL(c.unidades, 0) - p.unidades) / p.unidades END
            AS decimal(18, 6)) AS varUnidadesPct,
        CAST(
            CASE
                WHEN ISNULL(p.nroComprobantes, 0) = 0 THEN NULL
                WHEN (ISNULL(p.ventaNeta, 0) / p.nroComprobantes) = 0 THEN NULL
                ELSE (
                    (CASE WHEN ISNULL(c.nroComprobantes, 0) = 0 THEN 0
                          ELSE ISNULL(c.ventaNeta, 0) / c.nroComprobantes END)
                    - (ISNULL(p.ventaNeta, 0) / p.nroComprobantes)
                ) / (ISNULL(p.ventaNeta, 0) / p.nroComprobantes)
            END AS decimal(18, 6)) AS varTicketPct,
        @From AS fromFecha,
        @To AS toFecha
    FROM cur c
    CROSS JOIN prev p;
END
GO
