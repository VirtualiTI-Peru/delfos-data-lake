:setvar pathInsert "C:\Projects\VirtualiTI\delfos\delfos-backend\delfos-data-lake\Tables\silver\Insert"
:setvar pathUpdate "C:\Projects\VirtualiTI\delfos\delfos-backend\delfos-data-lake\Tables\silver\Update"

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
