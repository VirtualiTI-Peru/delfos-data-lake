/*
  Bootstrap del Lakehouse Delfos.
  Ejecutar con sqlcmd pasando variables de entorno (nunca commitear MasterKeyPassword):

  sqlcmd -S <synapse-workspace>.sql.azuresynapse.net -d <DatabaseName> -G ^
    -v DatabaseName="ldh_factoria" ^
    -v AdlsContainerPath="https://adlsdelfosanalytics.blob.core.windows.net/factoria" ^
    -v MasterKeyPassword="$(MasterKeyPassword)" ^
    -i InitializeDataLakeHouse.sql
*/

--CREATE DATABASE $(DatabaseName) COLLATE Latin1_General_100_BIN2_UTF8
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'CP3H7nuep7AdqCqgmdPGwXdwGAYA8ZMF')
BEGIN
    DECLARE @mkSql NVARCHAR(4000) = N'CREATE MASTER KEY ENCRYPTION BY PASSWORD = ''' + REPLACE('CP3H7nuep7AdqCqgmdPGwXdwGAYA8ZMF', '''', '''''') + '''';
    EXEC (@mkSql);
END

IF NOT EXISTS (SELECT 1 FROM sys.database_scoped_credentials WHERE name = 'WorkspaceIdentity')
BEGIN
    CREATE DATABASE SCOPED CREDENTIAL WorkspaceIdentity
    WITH IDENTITY = 'Managed Identity';
END

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')
    EXEC('CREATE SCHEMA bronze AUTHORIZATION dbo');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA gold AUTHORIZATION dbo');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
    EXEC('CREATE SCHEMA silver AUTHORIZATION dbo');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'helpers')
    EXEC('CREATE SCHEMA helpers AUTHORIZATION dbo');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'frontend')
    EXEC('CREATE SCHEMA frontend AUTHORIZATION dbo');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'logs')
    EXEC('CREATE SCHEMA logs AUTHORIZATION dbo');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'job')
    EXEC('CREATE SCHEMA job AUTHORIZATION dbo');

IF NOT EXISTS (SELECT 1 FROM sys.external_data_sources WHERE name = 'eds_delfos')
BEGIN
    CREATE EXTERNAL DATA SOURCE eds_delfos
        WITH (
            LOCATION   = 'https://delfosdatalakeaccount.blob.core.windows.net/factoria',
            CREDENTIAL = WorkspaceIdentity
        );
END

IF NOT EXISTS (SELECT 1 FROM sys.external_file_formats WHERE name = 'eff_delfos_csv')
BEGIN
    CREATE EXTERNAL FILE FORMAT eff_delfos_csv
        WITH (
            FORMAT_TYPE = DELIMITEDTEXT,
            FORMAT_OPTIONS (
                FIELD_TERMINATOR = N'|',
                FIRST_ROW = 2,
                USE_TYPE_DEFAULT = False
            )
        );
END

IF NOT EXISTS (SELECT 1 FROM sys.external_file_formats WHERE name = 'eff_delfos_parquet')
BEGIN
    CREATE EXTERNAL FILE FORMAT eff_delfos_parquet
        WITH (FORMAT_TYPE = PARQUET);
END
