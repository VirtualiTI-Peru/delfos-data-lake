/*
  Domingo = 1, independiente de @@DATEFIRST.
  Cartera: ignora asignaciones anuladas y solo devuelve cargo VENDEDOR.
  Ventas: ultima Ver por linea, leyendo solo los meses del rango
  (filepath sobre Year/Month; un mes sin carpeta no aporta filas).
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

    DECLARE @Year int = YEAR(@FechaIni);
    DECLARE @Month int = MONTH(@FechaIni);
    DECLARE @EndKey int = YEAR(@FechaFin) * 100 + MONTH(@FechaFin);
    DECLARE @MonthFilter nvarchar(max) = N'';

    WHILE (@Year * 100 + @Month) <= @EndKey
    BEGIN
        IF @MonthFilter <> N''
            SET @MonthFilter += N' OR ';

        SET @MonthFilter += N'(src.filepath(1) = ''' + CAST(@Year AS varchar(4))
            + N''' AND src.filepath(2) = ''' + CAST(@Month AS varchar(2)) + N''')';

        SET @Month += 1;
        IF @Month > 12
        BEGIN
            SET @Month = 1;
            SET @Year += 1;
        END
    END

    IF @MonthFilter = N''
        SET @MonthFilter = N'1 = 0';

    DECLARE @Sql nvarchar(max) = N'
    ;WITH Vendedor_Clientes AS
    (
        SELECT
            cf.idSucursal,
            cf.idFuerzaVentas,
            rv.idPersonal,
            cf.idCliente,
            REPLACE(LTRIM(RTRIM(rv.diasVisita)), '' '', '''') AS diasVisita
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
          AND NULLIF(LTRIM(RTRIM(rv.diasVisita)), '''') IS NOT NULL
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
        CROSS APPLY STRING_SPLIT(vc.diasVisita, '','') AS s
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
    Ventas_Origen AS
    (
        SELECT
            src.idSucursal,
            src.idFuerzaVentas,
            src.idVendedor,
            src.idCliente,
            src.idDocumento,
            src.letra,
            src.serie,
            src.nrodoc,
            src.fechaComprobate,
            src.anulado,
            src.subtotalFinal,
            src.Ver,
            src.idEmpresa,
            src.idLinea,
            src.idArticulo
        FROM OPENROWSET(
            BULK ''chess/parquet_files/ventasresumen/Year=*/Month=*/Day=*/Ver=*/*/*.parquet'',
            DATA_SOURCE = ''eds_delfos'',
            FORMAT = ''PARQUET''
        ) WITH (
            idSucursal int,
            idFuerzaVentas int,
            idVendedor int,
            idCliente int,
            idDocumento nvarchar(10),
            letra nvarchar(2),
            serie int,
            nrodoc int,
            fechaComprobate datetime,
            anulado bit,
            subtotalFinal decimal(14, 4),
            Ver int,
            idEmpresa int,
            idLinea int,
            idArticulo int
        ) AS src
        WHERE src.Ver <> 0
          AND src.fechaComprobate >= @FechaIni
          AND src.fechaComprobate < @FechaFinExcl
          AND (' + @MonthFilter + N')
    ),
    Ventas_Vigente AS
    (
        SELECT
            d.idSucursal,
            d.idFuerzaVentas,
            d.idVendedor,
            d.idCliente,
            d.idDocumento,
            d.letra,
            d.serie,
            d.nrodoc,
            d.fechaComprobate,
            d.subtotalFinal
        FROM
        (
            SELECT
                o.idSucursal,
                o.idFuerzaVentas,
                o.idVendedor,
                o.idCliente,
                o.idDocumento,
                o.letra,
                o.serie,
                o.nrodoc,
                o.fechaComprobate,
                o.anulado,
                o.subtotalFinal,
                ROW_NUMBER() OVER (
                    PARTITION BY ISNULL(o.letra, ''''), o.serie, o.nrodoc, o.idDocumento,
                                 o.idSucursal, o.idEmpresa, o.idLinea, o.idArticulo
                    ORDER BY o.Ver DESC
                ) AS rn
            FROM Ventas_Origen AS o
        ) AS d
        WHERE d.rn = 1
          AND d.idVendedor IS NOT NULL
          AND ISNULL(d.anulado, 0) = 0
    ),
    Ventas_Vendedor_Diario AS
    (
        SELECT
            v.idSucursal,
            v.idFuerzaVentas,
            v.idVendedor,
            v.idCliente,
            v.idDocumento,
            v.letra,
            v.serie,
            v.nrodoc,
            v.fechaComprobate,
            SUM(v.subtotalFinal) AS subtotalFinal
        FROM Ventas_Vigente AS v
        GROUP BY
            v.idSucursal,
            v.idFuerzaVentas,
            v.idVendedor,
            v.idCliente,
            v.idDocumento,
            v.letra,
            v.serie,
            v.nrodoc,
            v.fechaComprobate
    ),
    Ventas_Vendedor AS
    (
        SELECT
            v.idSucursal,
            v.idFuerzaVentas,
            v.idVendedor,
            COUNT(*) AS NumeroDeVentas,
            SUM(v.subtotalFinal) AS subtotalFinal
        FROM Ventas_Vendedor_Diario AS v
        GROUP BY
            v.idSucursal,
            v.idFuerzaVentas,
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
        p.idFuerzaVentas,
        p.desFuerzaVentas,
        p.idPersonal,
        p.desPersonal,
        c.Cartera,
        c.Visitas_Programadas,
        v.NumeroDeVentas,
        v.subtotalFinal,
        qv.CuotaVentas,
        qc.CuotaCobertura
    FROM gold.PersCom AS p
    LEFT JOIN Ventas_Vendedor AS v
        ON v.idSucursal = p.idSucursal
       AND v.idFuerzaVentas = p.idFuerzaVentas
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
    WHERE p.cargo = ''VENDEDOR'';';
    print @sql
    EXEC sp_executesql
        @Sql,
        N'@FechaIni date, @FechaFinExcl date, @CantDia1 int, @CantDia2 int, @CantDia3 int, @CantDia4 int, @CantDia5 int, @CantDia6 int, @CantDia7 int',
        @FechaIni = @FechaIni,
        @FechaFinExcl = @FechaFinExcl,
        @CantDia1 = @CantDia1,
        @CantDia2 = @CantDia2,
        @CantDia3 = @CantDia3,
        @CantDia4 = @CantDia4,
        @CantDia5 = @CantDia5,
        @CantDia6 = @CantDia6,
        @CantDia7 = @CantDia7;
END
GO
