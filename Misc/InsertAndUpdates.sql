:setvar pathInsert "C:\Projects\VirtualiTI\delfos\delfos-backend\delfos-data-lake\Tables\silver\Insert"
:setvar pathUpdate "C:\Projects\VirtualiTI\delfos\delfos-backend\delfos-data-lake\Tables\silver\Update"
:setvar pathAnular "C:\Projects\VirtualiTI\delfos\delfos-backend\delfos-data-lake\Tables\silver\Anular"

:r $(pathInsert)\Agrupaciones.sql
go
:r $(pathInsert)\Articulo.sql
go
:r $(pathInsert)\Cliente.sql
go
:r $(pathInsert)\VentasResumen.sql
go
:r $(pathInsert)\DsStock.sql
go
:r $(pathInsert)\CanalesMkt.sql
go
:r $(pathInsert)\SegmentosMkt.sql
go
:r $(pathInsert)\SubCanalesMkt.sql
go
:r $(pathInsert)\PersCom.sql
go
:r $(pathInsert)\CuotaVentas.sql
go
:r $(pathInsert)\CuotaCobertura.sql
go
:r $(pathInsert)\RutasVenta.sql
go
:r $(pathInsert)\ClientesRuta.sql
go

:r $(pathUpdate)\Agrupaciones.sql
go
:r $(pathUpdate)\Articulo.sql
go
:r $(pathUpdate)\Cliente.sql
go
:r $(pathUpdate)\VentasResumen.sql
go
:r $(pathUpdate)\DsStock.sql
go
:r $(pathUpdate)\CanalesMkt.sql
go
:r $(pathUpdate)\SegmentosMkt.sql
go
:r $(pathUpdate)\SubCanalesMkt.sql
go
:r $(pathUpdate)\PersCom.sql
go
:r $(pathUpdate)\CuotaVentas.sql
go
:r $(pathUpdate)\CuotaCobertura.sql
go
:r $(pathUpdate)\RutasVenta.sql
go
:r $(pathUpdate)\ClientesRuta.sql
go

:r $(pathAnular)\Articulo.sql
go
:r $(pathAnular)\Cliente.sql
go
:r $(pathAnular)\RutasVenta.sql
go
:r $(pathAnular)\ClientesRuta.sql
go
