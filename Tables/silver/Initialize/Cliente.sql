DECLARE @Sql VARCHAR(MAX)
DECLARE @Version INT = 0
DECLARE @dateFormat AS varchar(14) = '00000000000000'
DECLARE @folderName as VARCHAR(100) = CONCAT('/chess/parquet_files/cliente/Ver=0/',@dateFormat,'/')
SET @SQL = '
			CREATE EXTERNAL TABLE ECliente#NA
			WITH (
				LOCATION = '''+ @folderName + ''',
				DATA_SOURCE = eds_delfos,  
				FILE_FORMAT = eff_delfos_parquet
			)
			AS
			SELECT
				CAST( NULL AS int) AS idSucursal
				, CAST( NULL AS nvarchar(100)) AS desSucursal
				, CAST( NULL AS int) AS idCliente
				, CAST( NULL AS date) AS fechaAlta
				, CAST( NULL AS bit) AS anulado
				, CAST( NULL AS date) AS fechaBaja
				, CAST( NULL AS int) AS idAliasVigente
				, CAST( NULL AS int) AS idFormaPago
				, CAST( NULL AS nvarchar(100)) AS desFormaPago
				, CAST( NULL AS int) AS plazoPago
				, CAST( NULL AS int) AS idListaPrecio
				, CAST( NULL AS nvarchar(100)) AS desListaPrecio
				, CAST( NULL AS nvarchar(100)) AS idComprobante
				, CAST( NULL AS nvarchar(100)) AS desComprobante
				, CAST( NULL AS decimal(14,4)) AS limiteImporte
				, CAST( NULL AS int) AS idArtLimite
				, CAST( NULL AS nvarchar(100)) AS desArtLimite
				, CAST( NULL AS int) AS cantArtLimite
				, CAST( NULL AS int) AS cpbtesImpagos
				, CAST( NULL AS int) AS diasDeudaVencida
				, CAST( NULL AS nvarchar(100)) AS idPais
				, CAST( NULL AS nvarchar(100)) AS idProvincia
				, CAST( NULL AS nvarchar(100)) AS desProvincia
				, CAST( NULL AS int) AS idDepartamento
				, CAST( NULL AS nvarchar(100)) AS desDepartamento
				, CAST( NULL AS int) AS idLocalidad
				, CAST( NULL AS nvarchar(100)) AS desLocalidad
				, CAST( NULL AS nvarchar(100)) AS calle
				, CAST( NULL AS int) AS altura
				, CAST( NULL AS nvarchar(100)) AS entreCalle1
				, CAST( NULL AS nvarchar(100)) AS entreCalle2
				, CAST( NULL AS nvarchar(500)) AS comentario
				, CAST( NULL AS nvarchar(100)) AS longitudGeo
				, CAST( NULL AS nvarchar(100)) AS latitudGeo
				, CAST( NULL AS int) AS horario
				, CAST( NULL AS int) AS idLocalidadEntrega
				, CAST( NULL AS nvarchar(100)) AS desLocalidadEntrega
				, CAST( NULL AS nvarchar(100)) AS calleEntrega
				, CAST( NULL AS int) AS alturaEntrega
				, CAST( NULL AS nvarchar(100)) AS pisoDeptoEntrega
				, CAST( NULL AS nvarchar(100)) AS entreCalle1Entrega
				, CAST( NULL AS nvarchar(100)) AS entreCalle2Entrega
				, CAST( NULL AS nvarchar(500)) AS comentarioEntrega
				, CAST( NULL AS nvarchar(100)) AS longitudGeoEntrega
				, CAST( NULL AS nvarchar(100)) AS latitudGeoEntrega
				, CAST( NULL AS nvarchar(100)) AS horarioEntrega
				, CAST( NULL AS nvarchar(100)) AS telefonoFijo
				, CAST( NULL AS nvarchar(100)) AS telefonoMovil
				, CAST( NULL AS nvarchar(100)) AS email
				, CAST( NULL AS nvarchar(500)) AS comentarioAdicional
				, CAST( NULL AS int) AS idComisionVenta
				, CAST( NULL AS nvarchar(100)) AS desComisionVenta
				, CAST( NULL AS int) AS idComisionFlete
				, CAST( NULL AS nvarchar(100)) AS desComisionFlete
				, CAST( NULL AS decimal(14,4)) AS porcentajeFlete
				, CAST( NULL AS int) AS idSubcanalMkt
				, CAST( NULL AS nvarchar(100)) AS desSubcanalMkt
				, CAST( NULL AS int) AS idCanalMkt
				, CAST( NULL AS nvarchar(100)) AS desCanalMkt
				, CAST( NULL AS int) AS idSegmentoMkt
				, CAST( NULL AS nvarchar(100)) AS desSegmentoMkt
				, CAST( NULL AS int) AS idRamo
				, CAST( NULL AS nvarchar(100)) AS desRamo
				, CAST( NULL AS int) AS idArea
				, CAST( NULL AS nvarchar(100)) AS desArea
				, CAST( NULL AS int) AS idAgrupacion
				, CAST( NULL AS nvarchar(100)) AS desAgrupacion
				, CAST( NULL AS bit) AS esPotencial
				, CAST( NULL AS bit) AS esCuentayOrden
				, CAST( NULL AS int) AS idOcasionConsumo
				, CAST( NULL AS nvarchar(100)) AS desOcasionConsumo
				, CAST( NULL AS int) AS idSubcategoriaFoco
				, CAST( NULL AS nvarchar(100)) AS desSubcategoriaFoco
				, CAST( NULL AS bit) AS focoTrade
				, CAST( NULL AS bit) AS focoVentas
				, CAST( NULL AS nvarchar(100)) AS clusterVentas
				, CAST( 0 AS int) AS Ver
'

EXEC (@SQL)
DROP EXTERNAL TABLE ECliente#NA

CREATE EXTERNAL TABLE [silver].[Cliente]
(
	[idSucursal] [int],
	[desSucursal] [nvarchar](100),
	[idCliente] [int],
	[fechaAlta] [date],
	[anulado] [bit],
	[fechaBaja] [date],
	[idAliasVigente] [int],
	[idFormaPago] [int],
	[desFormaPago] [nvarchar](100),
	[plazoPago] [int],
	[idListaPrecio] [int],
	[desListaPrecio] [nvarchar](100),
	[idComprobante] [nvarchar](100),
	[desComprobante] [nvarchar](100),
	[limiteImporte] [decimal](14, 4),
	[idArtLimite] [int],
	[desArtLimite] [nvarchar](100),
	[cantArtLimite] [int],
	[cpbtesImpagos] [int],
	[diasDeudaVencida] [int],
	[idPais] [nvarchar](100),
	[idProvincia] [nvarchar](100),
	[desProvincia] [nvarchar](100),
	[idDepartamento] [int],
	[desDepartamento] [nvarchar](100),
	[idLocalidad] [int],
	[desLocalidad] [nvarchar](100),
	[calle] [nvarchar](100),
	[altura] [int],
	[entreCalle1] [nvarchar](100),
	[entreCalle2] [nvarchar](100),
	[comentario] [nvarchar](500),
	[longitudGeo] [nvarchar](100),
	[latitudGeo] [nvarchar](100),
	[horario] [int],
	[idLocalidadEntrega] [int],
	[desLocalidadEntrega] [nvarchar](100),
	[calleEntrega] [nvarchar](100),
	[alturaEntrega] [int],
	[pisoDeptoEntrega] [nvarchar](100),
	[entreCalle1Entrega] [nvarchar](100),
	[entreCalle2Entrega] [nvarchar](100),
	[comentarioEntrega] [nvarchar](500),
	[longitudGeoEntrega] [nvarchar](100),
	[latitudGeoEntrega] [nvarchar](100),
	[horarioEntrega] [nvarchar](100),
	[telefonoFijo] [nvarchar](100),
	[telefonoMovil] [nvarchar](100),
	[email] [nvarchar](100),
	[comentarioAdicional] [nvarchar](500),
	[idComisionVenta] [int],
	[desComisionVenta] [nvarchar](100),
	[idComisionFlete] [int],
	[desComisionFlete] [nvarchar](100),
	[porcentajeFlete] [decimal](14, 4),
	[idSubcanalMkt] [int],
	[desSubcanalMkt] [nvarchar](100),
	[idCanalMkt] [int],
	[desCanalMkt] [nvarchar](100),
	[idSegmentoMkt] [int],
	[desSegmentoMkt] [nvarchar](100),
	[idRamo] [int],
	[desRamo] [nvarchar](100),
	[idArea] [int],
	[desArea] [nvarchar](100),
	[idAgrupacion] [int],
	[desAgrupacion] [nvarchar](100),
	[esPotencial] [bit],
	[esCuentayOrden] [bit],
	[idOcasionConsumo] [int],
	[desOcasionConsumo] [nvarchar](100),
	[idSubcategoriaFoco] [int],
	[desSubcategoriaFoco] [nvarchar](100),
	[focoTrade] [bit],
	[focoVentas] [bit],
	[clusterVentas] [nvarchar](100),
	Ver INT
)
WITH (
    LOCATION = 'chess/parquet_files/cliente/Ver=*/*/*.parquet',
    DATA_SOURCE = eds_delfos,  
    FILE_FORMAT = eff_delfos_parquet
)