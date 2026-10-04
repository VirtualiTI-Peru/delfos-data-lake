:setvar SqlRoot "C:\Projects\VirtualiTI\Delfos\delfos-main\delfos-backend\delfos-data-lake"

:r $(SqlRoot)\Tables\silver\Initialize\log.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\Agrupaciones.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\Articulo.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\Cliente.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\VentasResumen.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\DsStock.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\CanalesMkt.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\SegmentosMkt.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\SubCanalesMkt.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\PersCom.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\CuotaVentas.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\CuotaCobertura.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\DiasNoLaborables.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\RutasVenta.sql
go
:r $(SqlRoot)\Tables\silver\Initialize\ClientesRuta.sql
go

:r $(SqlRoot)\Tables\gold\Agrupaciones.sql
go
:r $(SqlRoot)\Tables\gold\Articulo.sql
go
:r $(SqlRoot)\Tables\gold\Cliente.sql
go
:r $(SqlRoot)\Tables\gold\VentasResumen.sql
go
:r $(SqlRoot)\Tables\gold\DsStock.sql
go
:r $(SqlRoot)\Tables\gold\CanalesMkt.sql
go
:r $(SqlRoot)\Tables\gold\SegmentosMkt.sql
go
:r $(SqlRoot)\Tables\gold\SubCanalesMkt.sql
go
:r $(SqlRoot)\Tables\gold\PersCom.sql
go
:r $(SqlRoot)\Tables\gold\CuotaVentas.sql
go
:r $(SqlRoot)\Tables\gold\CuotaCobertura.sql
go
:r $(SqlRoot)\Tables\gold\DiasNoLaborables.sql
go
:r $(SqlRoot)\Tables\gold\RutasVenta.sql
go
:r $(SqlRoot)\Tables\gold\ClientesRuta.sql
go
