CREATE OR ALTER PROCEDURE dbo.usp_GetDiasLaborables
    @Anio int,
    @Mes int,
    @FechaConsulta date = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @FechaConsulta IS NULL
    BEGIN
        SET @FechaConsulta =
            CONVERT(date, SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'SA Pacific Standard Time');
    END;

    DECLARE @InicioMes date = DATEFROMPARTS(@Anio, @Mes, 1);
    DECLARE @FinMes    date = EOMONTH(@InicioMes);

    DECLARE @FechaCorte date =
        CASE
            WHEN @FechaConsulta < @InicioMes THEN DATEADD(DAY, -1, @InicioMes)
            WHEN @FechaConsulta > @FinMes THEN @FinMes
            ELSE @FechaConsulta
        END;

    ;WITH Resumen AS
    (
        SELECT
            COUNT(*) AS DiasNoLaborablesMes,
            COUNT(CASE WHEN fecha <= @FechaCorte THEN 1 END) AS DiasNoLaborablesTranscurridos
        FROM [gold].[DiasNoLaborables]
        WHERE fecha >= @InicioMes
          AND fecha < DATEADD(DAY, 1, @FinMes)
    )
    SELECT
        DiasNoLaborablesMes,
        DAY(@FinMes) - DiasNoLaborablesMes AS DiasLaborablesMes,
        CASE
            WHEN @FechaCorte < @InicioMes THEN 0
            ELSE DATEDIFF(DAY, @InicioMes, @FechaCorte) + 1 - DiasNoLaborablesTranscurridos
        END AS DiasLaborablesTranscurridos
    FROM Resumen;
END;
GO