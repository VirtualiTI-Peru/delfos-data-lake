CREATE OR ALTER PROCEDURE dbo.usp_GetDiasLaborables
    @FecIni date = NULL,
    @FecFin date = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Hoy date =
        CONVERT(date, SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'SA Pacific Standard Time');

    IF @FecIni IS NULL
        SET @FecIni = DATEFROMPARTS(YEAR(@Hoy), MONTH(@Hoy), 1);

    IF @FecFin IS NULL
        SET @FecFin = @Hoy;

    DECLARE @Anio int = YEAR(@FecIni);
    DECLARE @Mes int = MONTH(@FecIni);
    DECLARE @FechaConsulta date = @FecFin;

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
    ),
    Dias as
    (
        SELECT
            DiasNoLaborablesMes,
            DAY(@FinMes) - DiasNoLaborablesMes AS DiasLaborablesMes,
            CASE
                WHEN @FechaCorte < @InicioMes THEN 0
                ELSE DATEDIFF(DAY, @InicioMes, @FechaCorte) + 1 - DiasNoLaborablesTranscurridos
            END AS DiasLaborablesTranscurridos
        FROM Resumen
    )
    SELECT 
        DiasLaborablesMes,
        DiasLaborablesTranscurridos,
        DiasNoLaborablesMes,
        DiasLaborablesMes - DiasLaborablesTranscurridos AS DiasRestantes,
        CAST(DiasLaborablesTranscurridos AS DECIMAL) / CAST(DiasLaborablesMes AS DECIMAL) as ComparativoPct
     FROM Dias
END;
GO