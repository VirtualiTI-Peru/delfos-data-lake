/*
  Validación post-despliegue del Lakehouse Delfos.
  Ejecutar después de Deploy.sql. Reporta objetos faltantes.
*/
SET NOCOUNT ON;

DECLARE @Errors TABLE (CheckName VARCHAR(100), Status VARCHAR(20), Detail VARCHAR(500));

-- Schemas
INSERT INTO @Errors
SELECT 'Schema: ' + s.name,
	CASE WHEN EXISTS (SELECT 1 FROM sys.schemas WHERE name = s.name) THEN 'OK' ELSE 'FAIL' END,
	''
FROM (VALUES ('bronze'), ('silver'), ('gold'), ('helpers'), ('job'), ('logs'), ('frontend')) AS s(name);

-- Bronze external tables (15)
DECLARE @BronzeCount INT = (
	SELECT COUNT(*) FROM sys.external_tables et
	INNER JOIN sys.schemas sch ON et.schema_id = sch.schema_id
	WHERE sch.name = 'bronze'
);
INSERT INTO @Errors VALUES ('Bronze external tables', CASE WHEN @BronzeCount = 15 THEN 'OK' ELSE 'FAIL' END, CAST(@BronzeCount AS VARCHAR(10)) + ' de 15');

-- Silver external tables (8 activas)
DECLARE @SilverCount INT = (
	SELECT COUNT(*) FROM sys.external_tables et
	INNER JOIN sys.schemas sch ON et.schema_id = sch.schema_id
	WHERE sch.name = 'silver'
);
INSERT INTO @Errors VALUES ('Silver external tables', CASE WHEN @SilverCount >= 8 THEN 'OK' ELSE 'FAIL' END, CAST(@SilverCount AS VARCHAR(10)) + ' (mínimo 8)');

-- Silver Insert/Update procedures (16)
DECLARE @SilverProcCount INT = (
	SELECT COUNT(*) FROM sys.procedures p
	INNER JOIN sys.schemas sch ON p.schema_id = sch.schema_id
	WHERE sch.name = 'silver'
);
INSERT INTO @Errors VALUES ('Silver procedures', CASE WHEN @SilverProcCount >= 16 THEN 'OK' ELSE 'FAIL' END, CAST(@SilverProcCount AS VARCHAR(10)) + ' (mínimo 16)');

-- Job orchestrator
INSERT INTO @Errors
SELECT 'job.spSyncData',
	CASE WHEN OBJECT_ID('job.spSyncData', 'P') IS NOT NULL THEN 'OK' ELSE 'FAIL' END, '';

-- Gold views (9)
DECLARE @GoldViewCount INT = (
	SELECT COUNT(*) FROM sys.views v
	INNER JOIN sys.schemas sch ON v.schema_id = sch.schema_id
	WHERE sch.name = 'gold'
);
INSERT INTO @Errors VALUES ('Gold views', CASE WHEN @GoldViewCount >= 9 THEN 'OK' ELSE 'FAIL' END, CAST(@GoldViewCount AS VARCHAR(10)) + ' (mínimo 9)');

-- Helper objects
INSERT INTO @Errors SELECT 'helpers.spVentasResumen_BronzeSelect', CASE WHEN OBJECT_ID('helpers.spVentasResumen_BronzeSelect', 'P') IS NOT NULL THEN 'OK' ELSE 'FAIL' END, '';
INSERT INTO @Errors SELECT 'helpers.spVentasResumen_NullSelect', CASE WHEN OBJECT_ID('helpers.spVentasResumen_NullSelect', 'P') IS NOT NULL THEN 'OK' ELSE 'FAIL' END, '';
INSERT INTO @Errors SELECT 'logs.Log table', CASE WHEN OBJECT_ID('logs.Log', 'ET') IS NOT NULL THEN 'OK' ELSE 'FAIL' END, '';

-- Conectividad ADLS (opcional, puede fallar si no hay datos)
BEGIN TRY
	DECLARE @AdlsTest INT;
	SELECT TOP 1 @AdlsTest = idCliente FROM bronze.ECliente;
	INSERT INTO @Errors VALUES ('ADLS connectivity (bronze.ECliente)', 'OK', 'Lectura exitosa');
END TRY
BEGIN CATCH
	INSERT INTO @Errors VALUES ('ADLS connectivity (bronze.ECliente)', 'WARN', ERROR_MESSAGE());
END CATCH

SELECT * FROM @Errors ORDER BY Status DESC, CheckName;

DECLARE @FailCount INT = (SELECT COUNT(*) FROM @Errors WHERE Status = 'FAIL');
IF @FailCount > 0
	RAISERROR('ValidateDeployment: %d chequeo(s) fallaron.', 16, 1, @FailCount);
ELSE
	PRINT 'ValidateDeployment: todos los chequeos críticos pasaron.';
