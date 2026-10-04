-- ADEMAS HAY QUE BORRAR MANUALMENTE LOS ARCHIVOS .parquet en Azure
DROP VIEW IF EXISTS [gold].[Agrupacion];
DROP VIEW IF EXISTS [gold].[Articulo];
DROP VIEW IF EXISTS [gold].[Articulo_Agrupacion];
DROP VIEW IF EXISTS [gold].[Cliente];
DROP VIEW IF EXISTS [gold].[VentasResumen];
DROP VIEW IF EXISTS [gold].[DsStock];
DROP VIEW IF EXISTS [gold].[CanalesMkt];
DROP VIEW IF EXISTS [gold].[SegmentosMkt];
DROP VIEW IF EXISTS [gold].[SubCanalesMkt];
DROP VIEW IF EXISTS [gold].[PersCom];
DROP VIEW IF EXISTS [gold].[CuotaVentas];
DROP VIEW IF EXISTS [gold].[CuotaCobertura];
DROP VIEW IF EXISTS [gold].[RutasVenta];
DROP VIEW IF EXISTS [gold].[ClientesRuta];

DROP VIEW IF EXISTS [agg].[VentasVendedorDiario];
IF EXISTS (SELECT 1 FROM sys.external_tables WHERE object_id = OBJECT_ID('agg.VentasVendedorDiario'))
	DROP EXTERNAL TABLE [agg].[VentasVendedorDiario];

DECLARE @MartTable VARCHAR(100) = (
	SELECT TOP 1 CONCAT('agg.', et.name)
	FROM sys.external_tables et
	INNER JOIN sys.schemas s ON s.schema_id = et.schema_id
	WHERE s.name = 'agg' AND et.name LIKE 'VentasVendedorDiario[_]%');
WHILE @MartTable IS NOT NULL
BEGIN
	EXEC helpers.DropExternalTable @MartTable;
	SET @MartTable = (
		SELECT TOP 1 CONCAT('agg.', et.name)
		FROM sys.external_tables et
		INNER JOIN sys.schemas s ON s.schema_id = et.schema_id
		WHERE s.name = 'agg' AND et.name LIKE 'VentasVendedorDiario[_]%');
END

DROP EXTERNAL TABLE [logs].[Log];
DROP EXTERNAL TABLE [silver].[EAgrupacione];
DROP EXTERNAL TABLE [silver].[EArticulo];
DROP EXTERNAL TABLE [silver].[Cliente];
DROP EXTERNAL TABLE [silver].[VentasResumen];
DROP EXTERNAL TABLE [silver].[DsStock];
DROP EXTERNAL TABLE [silver].[CanalesMkt];
DROP EXTERNAL TABLE [silver].[SegmentosMkt];
DROP EXTERNAL TABLE [silver].[SubCanalesMkt];
DROP EXTERNAL TABLE [silver].[PersCom];
DROP EXTERNAL TABLE [silver].[CuotaVentas];
DROP EXTERNAL TABLE [silver].[CuotaCobertura];
DROP EXTERNAL TABLE [silver].[RutasVenta];
DROP EXTERNAL TABLE [silver].[ClientesRuta];