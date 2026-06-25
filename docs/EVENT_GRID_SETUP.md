# Trigger automático: ZIP en ADLS → Pipeline Synapse (Fase 1.4)

Automatiza la ejecución del pipeline de Synapse (unzip + `job.spSyncData`) cuando la
ingesta sube un nuevo ZIP a `{contenedor}/chess/zip_files/`.

## Arquitectura

```text
delfos-ingestion (CLI / Function)
        │  sube data_yyyyMMddHHmm.zip
        ▼
{contenedor}/chess/zip_files/*.zip
        │  Blob Created
        ▼
Storage event trigger (Synapse, usa Event Grid)
        │
        ▼
Pipeline Synapse: unzip → source_files → job.spSyncData (DBName = ldh_<cliente>)
```

Como el pipeline **borra el ZIP al terminar**, siempre hay 0 o 1 archivo en `zip_files/`.
El trigger solo dispara la corrida; el pipeline procesa el único ZIP presente, por lo que
no necesita recibir la ruta del blob.

## Prerrequisito (una sola vez por suscripción)

Registrar **DOS** resource providers. El de `Microsoft.DataFactory` es obligatorio aunque
no uses Data Factory: Synapse lo necesita internamente para activar storage event triggers.
Si falta, la activación falla con el error de claims `puid`/`altsecid`/`oid` (ver Troubleshooting).

```powershell
az provider register --namespace Microsoft.EventGrid
az provider register --namespace Microsoft.DataFactory

az provider show --namespace Microsoft.EventGrid   --query "registrationState" -o tsv
az provider show --namespace Microsoft.DataFactory --query "registrationState" -o tsv
# Esperar a que ambos devuelvan: Registered
```

## Crear el Storage event trigger (Synapse Studio)

`Pipeline` → **Add trigger** → **New/Edit** → **+ New**

| Campo | Valor |
|-------|-------|
| Name | `trg-factoria-zip` |
| Type | **Storage events** |
| Azure subscription | `2fd80362-a9d0-4fe2-b52b-4b953695d5ca` |
| Storage account | `delfosdatalakeaccount` |
| Container name | `factoria` |
| Blob path begins with | `chess/zip_files/` |
| Blob path ends with | `.zip` |
| Event | **Blob created** |
| Ignore empty blobs | Sí |

### Parámetros del pipeline

Al asociar el trigger, fijar los parámetros del pipeline:

| Parámetro | Valor |
|-----------|-------|
| `DBName` | `ldh_factoria` |
| `containerName` (si existe) | `factoria` |

No se requiere `zipBlobPath`: el pipeline toma el único ZIP de la carpeta.

### Publicar

**Publish all**. El trigger queda activo solo después de publicar.

## Probar end-to-end

```powershell
cd C:\Projects\VirtualiTI\delfos\delfos-backend\delfos-ingestion
dotnet run --project Delfos.Ingestion.Cli -- --company FACTORIA --past-days 30
```

Verificar en Synapse Studio:

- **Monitor → Trigger runs**: aparece `trg-factoria-zip`
- **Monitor → Pipeline runs**: corrida automática del pipeline

Verificar el lakehouse (`ldh_factoria`, Dedicated pool):

```sql
SELECT TOP 15 LogDate, ProcedureName, LEFT(LogMessage, 100) AS LogMessage, LogType
FROM logs.Log
ORDER BY LogDate DESC;

SELECT COUNT(*) AS clientes FROM gold.Cliente;
SELECT COUNT(*) AS ventas   FROM gold.VentasResumen;
```

## Multi-cliente

Un trigger por contenedor, cada uno con su `DBName`:

| Trigger | Container | DBName |
|---------|-----------|--------|
| `trg-factoria-zip` | `factoria` | `ldh_factoria` |
| `trg-codisal-zip` | `codisal` | `ldh_codisal` |

## Permisos

| Identidad | Recurso | Rol |
|-----------|---------|-----|
| Usuario que crea el trigger | `delfosdatalakeaccount` | Owner / Contributor (Synapse registra el event subscription por detrás) |
| MI del workspace `delfos-synapse` | `ldh_<cliente>` | `db_owner` (`CREATE USER ... FROM EXTERNAL PROVIDER`) |
| MI del workspace `delfos-synapse` | `delfosdatalakeaccount` | Storage Blob Data Contributor |

## Notas

- Cada upload nuevo = un evento `BlobCreated` = una corrida del pipeline.
- Evitar re-subir un blob con el mismo nombre exacto (un overwrite puede no generar evento nuevo). La ingesta ya genera nombres únicos con timestamp.
- Si el pipeline borra el ZIP muy rápido no hay problema: el evento se captura en el momento del upload.

## Troubleshooting

### El trigger no dispara al subir el ZIP manualmente desde el Portal

`delfosdatalakeaccount` es una cuenta **ADLS Gen2 (namespace jerárquico / HNS)**. Al subir
un archivo con el botón **Upload** del Portal, la subida va por el endpoint **DFS (Data Lake)**
y el evento `Microsoft.Storage.BlobCreated` resultante NO coincide con lo que espera el
storage event trigger, por lo que **no dispara** (se observa `PublishSuccessCount = 0` y
`MatchedEventCount = 0` en las métricas del System Topic).

Esto es solo un problema de **prueba manual**, no de producción:

| Método de subida | Endpoint | ¿Dispara el trigger? |
|------------------|----------|----------------------|
| App de ingesta (`BlobClient.UploadAsync`) | Blob | Sí |
| `az storage blob upload` / `az storage blob copy` | Blob | Sí |
| Portal → botón **Upload** (cuenta HNS) | DFS | No |

**Para probar end-to-end usa la ruta real (app de ingesta), que sube por el endpoint de blob:**

```powershell
cd C:\Projects\VirtualiTI\delfos\delfos-backend\delfos-ingestion
dotnet run --project Delfos.Ingestion.Cli -- --company FACTORIA --past-days 7
```

> Nota: las métricas de Event Grid y `az synapse trigger-run query-by-workspace` pueden
> tener varios minutos de lag. Para confirmar rápido, mira **Monitor → Pipeline runs** en
> Synapse Studio, o verifica que el ZIP haya sido consumido/eliminado de `chess/zip_files/`
> (el pipeline borra el ZIP al terminar).



### Error al activar el trigger: claims `puid` / `altsecid` / `oid`

```text
Failed to activate Trigger: The received access token is not valid: at least one of
the claims 'puid' or 'altsecid' or 'oid' should be present. If you are accessing as
application please make sure service principal is properly created in the tenant.
```

**Causa real (confirmada):** el resource provider `Microsoft.DataFactory` **no estaba
registrado** en la suscripción. Pese al mensaje, NO es problema de la cuenta (guest vs
member): el mismo error aparece con ambas. El token que falla es el que usa Synapse por
detrás para crear el event subscription, y sin `Microsoft.DataFactory` registrado no se
emiten las claims correctas.

**Solución:**

```powershell
az provider register --namespace Microsoft.DataFactory
az provider show --namespace Microsoft.DataFactory --query "registrationState" -o tsv
# Esperar a que devuelva: Registered (1-3 min)
```

Luego volver a **Publish / Activate** el trigger en Synapse con tu cuenta habitual.

> Nota: lo de pre-crear el system topic o usar una cuenta member NO resuelve este error;
> el único fix es registrar `Microsoft.DataFactory`.

### Prerrequisitos verificados (suscripción VirtualiTI)

- `Microsoft.EventGrid` provider: Registered
- `Microsoft.DataFactory` provider: Registered ← faltaba; causaba el error de claims
- `Microsoft.Synapse` provider: Registered
- SP de primera parte `Microsoft.EventGrid` (`4962773b-...`): existe en el tenant
