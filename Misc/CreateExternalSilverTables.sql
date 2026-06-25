:setvar SqlRoot "C:\Projects\VirtualiTI\delfos\delfos-backend\delfos-data-lake"

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
