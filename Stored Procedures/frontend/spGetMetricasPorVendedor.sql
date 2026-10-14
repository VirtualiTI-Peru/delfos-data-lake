/*
  Misma firma y mismas columnas que frontend.spGetMetricasPorVendedor.
  Cartera y cuotas no cambian.
  Ventas salen de agg.VentasVendedorDiario (ultima Ver, no anulados, ya
  agregados por dia). La fuerza se toma de gold.PersCom: en ldh_pauser
  cada vendedor tiene una sola fuerza por sucursal.
  Cuotas del mes de @FechaIni: suma de cuota por agrupacion y cuota_calculada.
*/
CREATE OR ALTER PROCEDURE frontend.spGetMetricasPorVendedor
(
    @FechaIni date = NULL,
    @FechaFin date = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FechaIni IS NULL
        SET @FechaIni = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);

    IF @FechaFin IS NULL
        SET @FechaFin = CAST(GETDATE() AS date);

    DECLARE @FechaFinExcl date = DATEADD(DAY, 1, @FechaFin);
    DECLARE @TotalDias int = DATEDIFF(DAY, @FechaIni, @FechaFin) + 1;
    DECLARE @SemanasCompletas int = @TotalDias / 7;
    DECLARE @DiasExtra int = @TotalDias % 7;
    -- 1899-12-31 es domingo: 1 = domingo ... 7 = sabado, igual que diasVisita en ldh_pauser.
    DECLARE @DiaInicio int = (DATEDIFF(DAY, '18991231', @FechaIni) % 7) + 1;

    DECLARE @CantDia1 int;
    DECLARE @CantDia2 int;
    DECLARE @CantDia3 int;
    DECLARE @CantDia4 int;
    DECLARE @CantDia5 int;
    DECLARE @CantDia6 int;
    DECLARE @CantDia7 int;

    ;WITH Dias AS
    (
        SELECT
            v.DiaSemana,
            @SemanasCompletas
            + CASE
                WHEN ((v.DiaSemana - @DiaInicio + 7) % 7) < @DiasExtra THEN 1
                ELSE 0
              END AS CantDias
        FROM
        (
            SELECT 1 AS DiaSemana
            UNION ALL SELECT 2
            UNION ALL SELECT 3
            UNION ALL SELECT 4
            UNION ALL SELECT 5
            UNION ALL SELECT 6
            UNION ALL SELECT 7
        ) AS v
    )
    SELECT
        @CantDia1 = MAX(CASE WHEN DiaSemana = 1 THEN CantDias END),
        @CantDia2 = MAX(CASE WHEN DiaSemana = 2 THEN CantDias END),
        @CantDia3 = MAX(CASE WHEN DiaSemana = 3 THEN CantDias END),
        @CantDia4 = MAX(CASE WHEN DiaSemana = 4 THEN CantDias END),
        @CantDia5 = MAX(CASE WHEN DiaSemana = 5 THEN CantDias END),
        @CantDia6 = MAX(CASE WHEN DiaSemana = 6 THEN CantDias END),
        @CantDia7 = MAX(CASE WHEN DiaSemana = 7 THEN CantDias END)
    FROM Dias;

    ;WITH Vendedor_Clientes AS
    (
        SELECT
            cf.idSucursal,
            cf.idFuerzaVentas,
            rv.idPersonal,
            cf.idCliente,
            REPLACE(LTRIM(RTRIM(rv.diasVisita)), ' ', '') AS diasVisita
        FROM gold.Clifuerza AS cf
        INNER JOIN gold.RutasVenta AS rv
            ON rv.idSucursal = cf.idSucursal
           AND rv.idFuerzaVentas = cf.idFuerzaVentas
           AND rv.idRuta = cf.idRuta
        WHERE cf.fechaInicioFuerza < @FechaFinExcl
          AND cf.fechaFinFuerza >= @FechaIni
          AND ISNULL(cf.anulado, 0) = 0
          AND rv.anulado = 0
          AND rv.idPersonal NOT IN (0, 999)
          AND NULLIF(LTRIM(RTRIM(rv.diasVisita)), '') IS NOT NULL
    ),
    Vendedor_Clientes_Dia AS
    (
        SELECT
            vc.idSucursal,
            vc.idFuerzaVentas,
            vc.idPersonal,
            vc.idCliente,
            TRY_CAST(s.value AS int) AS DiaSemana
        FROM Vendedor_Clientes AS vc
        CROSS APPLY STRING_SPLIT(vc.diasVisita, ',') AS s
        WHERE TRY_CAST(s.value AS int) BETWEEN 1 AND 7
        GROUP BY
            vc.idSucursal,
            vc.idFuerzaVentas,
            vc.idPersonal,
            vc.idCliente,
            TRY_CAST(s.value AS int)
    ),
    Dias_Cantidad AS
    (
        SELECT 1 AS DiaSemana, @CantDia1 AS CantDias
        UNION ALL SELECT 2, @CantDia2
        UNION ALL SELECT 3, @CantDia3
        UNION ALL SELECT 4, @CantDia4
        UNION ALL SELECT 5, @CantDia5
        UNION ALL SELECT 6, @CantDia6
        UNION ALL SELECT 7, @CantDia7
    ),
    Cartera_Vendedor AS
    (
        SELECT
            vcd.idSucursal,
            vcd.idFuerzaVentas,
            vcd.idPersonal,
            COUNT(DISTINCT vcd.idCliente) AS Cartera,
            SUM(dc.CantDias) AS Visitas_Programadas
        FROM Vendedor_Clientes_Dia AS vcd
        INNER JOIN Dias_Cantidad AS dc
            ON dc.DiaSemana = vcd.DiaSemana
        GROUP BY
            vcd.idSucursal,
            vcd.idFuerzaVentas,
            vcd.idPersonal
    ),
    Ventas_Vendedor AS
    (
        SELECT
            v.idSucursal,
            v.idVendedor,
            SUM(v.nroComprobantes) AS NumeroDeVentas,
            SUM(v.subtotalFinal) AS subtotalFinal
        FROM agg.VentasVendedorDiario AS v
        WHERE v.fecha >= @FechaIni
          AND v.fecha < @FechaFinExcl
          AND v.idVendedor IS NOT NULL
        GROUP BY
            v.idSucursal,
            v.idVendedor
        HAVING SUM(v.subtotalFinal) > 0
    ),
    CuotaVentas_Vendedor AS
    (
        SELECT
            q.idSucursal,
            q.idPersonal,
            SUM(q.cuota) AS CuotaVentas
        FROM gold.CuotaVentas AS q
        WHERE q.[Year] = YEAR(@FechaIni)
          AND q.[Month] = MONTH(@FechaIni)
        GROUP BY
            q.idSucursal,
            q.idPersonal
    ),
    CuotaCobertura_Vendedor AS
    (
        SELECT
            q.idSucursal,
            q.idPersonal,
            SUM(q.cuota_calculada) AS CuotaCobertura
        FROM gold.CuotaCobertura AS q
        WHERE q.[Year] = YEAR(@FechaIni)
          AND q.[Month] = MONTH(@FechaIni)
        GROUP BY
            q.idSucursal,
            q.idPersonal
    )
    SELECT
        p.idSucursal,
        p.desSucursal,
        p.idFuerzaVentas,
        p.desFuerzaVentas,
        p.desPersonalSuperior,
        p.idPersonal,
        p.desPersonal,
        ISNULL(c.Cartera, 0) AS Cartera,
        ISNULL(c.Visitas_Programadas, 0) AS Visitas_Programadas,
        ISNULL(v.NumeroDeVentas, 0) AS NumeroDeVentas,
        ISNULL(v.subtotalFinal, 0) AS subtotalFinal,
        ISNULL(qv.CuotaVentas, 0) AS CuotaVentas,
        ISNULL(qc.CuotaCobertura, 0) AS CuotaCobertura
    FROM gold.PersCom AS p
    LEFT JOIN Ventas_Vendedor AS v
        ON v.idSucursal = p.idSucursal
       AND v.idVendedor = p.idPersonal
    LEFT JOIN Cartera_Vendedor AS c
        ON c.idSucursal = p.idSucursal
       AND c.idFuerzaVentas = p.idFuerzaVentas
       AND c.idPersonal = p.idPersonal
    LEFT JOIN CuotaVentas_Vendedor AS qv
        ON qv.idSucursal = p.idSucursal
       AND qv.idPersonal = p.idPersonal
    LEFT JOIN CuotaCobertura_Vendedor AS qc
        ON qc.idSucursal = p.idSucursal
       AND qc.idPersonal = p.idPersonal
    WHERE p.cargo = 'VENDEDOR';
END
GO
