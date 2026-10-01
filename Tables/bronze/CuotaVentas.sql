CREATE EXTERNAL TABLE bronze.CuotaVentas(
	idSucursal int,
	idPersonal int,
	periodo nchar(7),
	idAgrupacion nvarchar(100),
	cuota decimal(18, 2)
)
WITH (
    LOCATION = 'chess/objetivos_files/ventas/',
    DATA_SOURCE = eds_delfos,
    FILE_FORMAT = eff_delfos_csv
)
