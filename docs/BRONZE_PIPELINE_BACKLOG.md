# Backlog: pipelines bronze pendientes

Entidades con pipeline **completo** (Initialize → Insert → Update → Gold → job.spSyncData):

| Entidad | Estado |
|---------|--------|
| Agrupaciones (EAgrupacione) | Implementado |
| Articulo (EArticulo) | Implementado |
| Cliente (ECliente) | Implementado |
| VentasResumen | Implementado |
| DsStock | Implementado |
| CanalesMkt | Implementado |
| SegmentosMkt | Implementado |
| SubCanalesMkt | Implementado |
| PersCom (EPersCom) | Implementado |
| RutasVenta (ERutasVenta) | Implementado. Clave `idRuta`. `IdRutaAuto` se regenera en cada extracción y el Update no lo compara |
| ClientesRuta (EClientesRuta) | Implementado. Clave `idCliente` + `idRuta`. `idRuta` se resuelve con `bronze.ERutasVenta` por `IdRutaAuto` de la misma extracción. `anulado` solo existe en silver/gold |
| CuotaVentas | Implementado (job.spSyncCuotaVentas, origen delfos-api) |
| CuotaCobertura | Implementado (job.spSyncCuotaCobertura, origen delfos-api) |

## Pendientes (prioridad sugerida)

### Prioridad 1 — Operaciones

| Bronze | Clave de negocio sugerida | Carpeta Parquet |
|--------|---------------------------|-----------------|
| Pedido | idPedido | `chess/parquet_files/pedido/` |
| Item | idPedido + idLinea | `chess/parquet_files/item/` |

### Prioridad 2 — Rutas y fuerza de ventas

| Bronze | Clave de negocio sugerida |
|--------|---------------------------|
| EClifuerza | idFuerza |
| EClialias | idAlias |

## Plantilla para nueva entidad

1. Crear `Tables/silver/Initialize/<Entidad>.sql` — CTAS vacío + external table silver
2. Crear `Tables/silver/Insert/<Entidad>.sql` — `silver.sp<Entidad>_Insert`
3. Crear `Tables/silver/Update/<Entidad>.sql` — `silver.sp<Entidad>_Update` comparando atributos con `ISNULL` (sin `HASHBYTES`: un `CHAR(0)` trunca el hash y no detecta cambios)
4. Crear `Tables/gold/<Entidad>.sql` — view con `MAX(Ver)` por clave
5. Registrar en `Misc/CreateExternalSilverTables.sql`, `Misc/InsertAndUpdates.sql`
6. Agregar llamadas en `Stored Procedures/job.SyncData.sql`
7. Actualizar `Misc/CleanupSilverTables.sql` y `Misc/ValidateDeployment.sql`

Copiar como referencia: `Tables/silver/Insert/CanalesMkt.sql` (dimensión simple) o `Tables/silver/Insert/DsStock.sql` (hecho con clave compuesta).
