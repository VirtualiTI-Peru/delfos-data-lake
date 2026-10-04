/*
  Obsoleto: el despliegue por cliente lo hace Delfos.Ingestion.Cli
  (lakehouse onboard / lakehouse deploy). Este archivo no se mantiene.

  Script maestro de despliegue - DelfosDataLakeSetup
  Ejecutar desde la raíz del repositorio con sqlcmd:

  sqlcmd -S <workspace>.sql.azuresynapse.net -d master -G ^
    -v DatabaseName="ldh_factoria" ^
    -v AdlsContainerPath="https://delfosdatalakeaccount.blob.core.windows.net/factoria" ^
    -v MasterKeyPassword="$(MasterKeyPassword)" ^
    -v SqlRoot="." ^
    -i Deploy.sql

  Prerrequisitos Azure Synapse:
  - SQL pool creado y accesible
  - Managed Identity del workspace con rol Storage Blob Data Contributor en ADLS
  - CSV fuente cargados en chess/source_files/ del contenedor ADLS
*/

:setvar DatabaseName "ldh_factoria"
:setvar AdlsContainerPath "https://delfosdatalakeaccount.blob.core.windows.net/factoria"
:setvar SqlRoot "C:\Projects\VirtualiTI\delfos\delfos-backend\delfos-data-lake"
:setvar SqlMisc "C:\Projects\VirtualiTI\delfos\delfos-backend\delfos-data-lake\Misc"
:setvar SqlSP "C:\Projects\VirtualiTI\delfos\delfos-backend\delfos-data-lake\Stored Procedures"

--PRINT '=== 1/9 Bootstrap Lakehouse ==='
--:r $(SqlRoot)/InitializeDataLakeHouse.sql
--GO

--PRINT '=== 2/9 Bronze external tables ==='
--:r $(SqlMisc)/CreateExternalBronzeTables.sql
--GO

--PRINT '=== 3/9 Silver initialize + Gold views ==='
--:r $(SqlRoot)/Misc/CreateExternalSilverTables.sql
GO

--PRINT '=== 4/9 Helper procedures ==='
--:r $(SqlSP)/helpers.DropExternalTable.sql
--GO
--:r $(SqlSP)/helpers.spGetDatesToUpdate.sql
--GO
--:r $(SqlSP)/helpers.spVentasResumen_SelectColumns.sql
--GO

--PRINT '=== 5/9 Silver Insert/Update procedures ==='
--:r $(SqlMisc)/InsertAndUpdates.sql
--GO

--PRINT '=== 6/9 Mart tables + refresh procedures ==='
--:r $(SqlRoot)/Tables/mart/VentasVendedorDiario.sql
--GO
--:r $(SqlSP)/mart.spVentasVendedorDiario_Refresh.sql
--GO

--PRINT '=== 7/9 Job orchestrator ==='
--:r $(SqlRoot)/Stored Procedures/job.SyncData.sql
--GO
--:r $(SqlRoot)/Stored Procedures/job.SyncCuotaVentas.sql
--GO
--:r $(SqlRoot)/Stored Procedures/job.SyncCuotaCobertura.sql
--GO
--:r $(SqlRoot)/Stored Procedures/job.SyncDiasNoLaborables.sql
--GO

--PRINT '=== 8/9 Frontend views ==='
--:r $(SqlRoot)/Misc/CreateFrontendViews.sql
--GO

--PRINT '=== 9/9 Frontend dashboard SPs ==='
--:r $(SqlRoot)/Misc/CreateFrontendDashboardProcs.sql
--GO

--PRINT '=== Despliegue completado. Ejecutar Misc\ValidateDeployment.sql para validar. ==='
