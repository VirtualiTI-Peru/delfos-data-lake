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

DROP EXTERNAL TABLE [silver].[EAgrupacione];
DROP EXTERNAL TABLE [silver].[EArticulo];
DROP EXTERNAL TABLE [silver].[Cliente];
DROP EXTERNAL TABLE [silver].[VentasResumen];
DROP EXTERNAL TABLE [silver].[DsStock];
DROP EXTERNAL TABLE [silver].[CanalesMkt];
DROP EXTERNAL TABLE [silver].[SegmentosMkt];
DROP EXTERNAL TABLE [silver].[SubCanalesMkt];