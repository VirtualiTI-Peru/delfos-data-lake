/*
  Script maestro de despliegue - DelfosDataLakeSetup
  Ejecutar desde la raíz del repositorio con sqlcmd:

  sqlcmd -S <workspace>.sql.azuresynapse.net -d master -G ^
    -v DatabaseName="ldh_codisal" ^
    -v AdlsContainerPath="https://adlsdelfosanalytics.blob.core.windows.net/codisal" ^
    -v MasterKeyPassword="$(MasterKeyPassword)" ^
    -v SqlRoot="." ^
    -i Deploy.sql

  Prerrequisitos Azure Synapse:
  - SQL pool creado y accesible
  - Managed Identity del workspace con rol Storage Blob Data Contributor en ADLS
  - CSV fuente cargados en chess/source_files/ del contenedor ADLS
*/

:setvar DatabaseName "ldh_codisal"
:setvar AdlsContainerPath "https://delfosdatalakeaccount.blob.core.windows.net/codisal"
:setvar SqlRoot "."

PRINT '=== 1/7 Bootstrap Lakehouse ==='
:r $(SqlRoot)/InitializeDataLakeHouse.sql
GO

PRINT '=== 2/7 Bronze external tables ==='
:r $(SqlRoot)/Misc/CreateExternalBronzeTables.sql
GO

PRINT '=== 3/7 Silver initialize + Gold views ==='
:r $(SqlRoot)/Misc/CreateExternalSilverTables.sql
GO

PRINT '=== 4/7 Helper procedures ==='
:r $(SqlRoot)/Stored Procedures/helpers.DropExternalTable.sql
GO
:r $(SqlRoot)/Stored Procedures/helpers.spGetDatesToUpdate.sql
GO
:r $(SqlRoot)/Stored Procedures/helpers.spVentasResumen_SelectColumns.sql
GO

PRINT '=== 5/7 Silver Insert/Update procedures ==='
:r $(SqlRoot)/Misc/InsertAndUpdates.sql
GO

PRINT '=== 6/7 Job orchestrator ==='
:r $(SqlRoot)/Stored Procedures/job.SyncData.sql
GO

PRINT '=== 7/7 Frontend views ==='
:r $(SqlRoot)/Misc/CreateFrontendViews.sql
GO

PRINT '=== Despliegue completado. Ejecutar Misc\ValidateDeployment.sql para validar. ==='
