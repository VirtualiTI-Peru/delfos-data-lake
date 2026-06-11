# DelfosDataLakeSetup

Scripts SQL para desplegar y operar un **Lakehouse medallion** (bronze → silver → gold) en **Azure Synapse Dedicated SQL Pool**, conectado a **Azure Data Lake Storage Gen2**.

## Arquitectura

```
CSV (ADLS)  →  bronze.* (external tables)
                    ↓
              job.spSyncData
                    ↓
              silver.* (Parquet versionado en ADLS)
                    ↓
              gold.* (views, última versión)
                    ↓
              frontend.* (views para BI)
```

| Capa | Contenido | Almacenamiento |
|------|-----------|----------------|
| **bronze** | Fuentes CSV crudas | `chess/source_files/*.csv` |
| **silver** | Datos curados con `Ver` | `chess/parquet_files/<entidad>/` |
| **gold** | Vista de negocio (`MAX(Ver)`) | Views sobre silver |
| **logs** | Trazas de ETL | `chess/parquet_files/log/` |

### Entidades en pipeline activo

Agrupaciones, Articulo, Cliente, VentasResumen, DsStock, CanalesMkt, SegmentosMkt, SubCanalesMkt.

Ver [docs/BRONZE_PIPELINE_BACKLOG.md](docs/BRONZE_PIPELINE_BACKLOG.md) para entidades bronze pendientes.

## Prerrequisitos Azure

1. **Synapse workspace** con SQL pool dedicado
2. **ADLS Gen2** (`adlsdelfosanalytics`) con contenedor/carpeta del cliente (ej. `codisal`)
3. **Managed Identity** del workspace con rol **Storage Blob Data Contributor** en el storage account
4. CSV fuente cargados en `chess/source_files/` del contenedor ADLS

### Estructura ADLS esperada

```
codisal/
  chess/
    source_files/          # CSV bronze (delimitador |, primera fila cabecera)
      VentasResumen.csv
      ECliente.csv
      ...
    parquet_files/         # Generado por ETL
      ventasresumen/Year=*/Month=*/Day=*/Ver=*/*/*.parquet
      cliente/Ver=*/*/*.parquet
      log/*/*.parquet
      ...
```

## Despliegue

### Variables requeridas

| Variable | Ejemplo | Descripción |
|----------|---------|-------------|
| `DatabaseName` | `ldh_codisal` | Base de datos del SQL pool |
| `AdlsContainerPath` | `https://adlsdelfosanalytics.blob.core.windows.net/codisal` | Ruta del external data source |
| `MasterKeyPassword` | *(secreto)* | Password del Database Master Key — **nunca commitear** |
| `SqlRoot` | `.` | Raíz del repo (para `:r` en sqlcmd) |

### Opción A: sqlcmd (recomendado)

Desde la raíz del repositorio:

```powershell
cd DelfosDataLakeSetup-main

sqlcmd -S <workspace>.sql.azuresynapse.net `
  -d ldh_codisal `
  -G `
  -v DatabaseName="ldh_codisal" `
  -v AdlsContainerPath="https://adlsdelfosanalytics.blob.core.windows.net/codisal" `
  -v MasterKeyPassword="$env:DELFOS_MASTER_KEY_PASSWORD" `
  -v SqlRoot="." `
  -i Deploy.sql
```

### Opción B: Synapse Studio

Ejecutar los scripts en orden manualmente desde el editor SQL, comenzando por `InitializeDataLakeHouse.sql`.

### Validación post-despliegue

```powershell
sqlcmd -S <workspace>.sql.azuresynapse.net -d ldh_codisal -G -i Misc\ValidateDeployment.sql
```

### Orden de ejecución (Deploy.sql)

1. `InitializeDataLakeHouse.sql` — schemas, credenciales, ADLS
2. `Misc/CreateExternalBronzeTables.sql`
3. `Misc/CreateExternalSilverTables.sql` — silver init + gold views + logs
4. Helper procedures y funciones
5. `Misc/InsertAndUpdates.sql` — SPs silver
6. `Stored Procedures/job.SyncData.sql`
7. `Misc/CreateFrontendViews.sql`

## Operación

### Sincronización manual

```sql
EXEC job.spSyncData;
```

### Programar en Synapse

Crear un **SQL Trigger** o **Pipeline** con actividad *SQL pool stored procedure* / script T-SQL que ejecute `EXEC job.spSyncData` en el horario deseado.

### Monitoreo

```sql
-- Últimos logs de ejecución
SELECT TOP 50 * FROM logs.Log ORDER BY LogDate DESC;

-- Resultado inmediato del job (también devuelve filas al ejecutar)
EXEC job.spSyncData;
```

### Limpieza

```sql
-- Elimina objetos SQL (los .parquet en ADLS deben borrarse manualmente)
:r Misc\CleanupSilverTables.sql
:r Misc\CleanUpBronzeTables.sql
```

## Seguridad

- La password del Master Key se pasa solo por variable de despliegue (`MasterKeyPassword`)
- Si la password anterior estuvo en el repositorio, **rotarla** en Azure antes de producción
- No commitear archivos `.env` ni credenciales (ver `.gitignore`)

## CI/CD

Ver [azure-pipelines.yml](azure-pipelines.yml). Configurar en Azure DevOps:

- `AzureServiceConnection`
- `SynapseServer`, `DatabaseName`, `AdlsContainerPath`
- `MasterKeyPassword` como variable secreta

## Estructura del repositorio

```
├── Deploy.sql                    # Script maestro
├── InitializeDataLakeHouse.sql # Bootstrap parametrizado
├── Tables/
│   ├── bronze/                   # 15 external tables CSV
│   ├── silver/Initialize|Insert|Update/
│   └── gold/                     # Views
├── Stored Procedures/
│   ├── job.SyncData.sql
│   └── helpers.*
├── Misc/                         # Orquestación y validación
└── docs/BRONZE_PIPELINE_BACKLOG.md
```
