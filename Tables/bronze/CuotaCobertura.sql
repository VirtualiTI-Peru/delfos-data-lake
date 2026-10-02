CREATE EXTERNAL TABLE bronze.CuotaCobertura(
	idSucursal int,
	idPersonal int,
	periodo nchar(7),
	cuota_calculada decimal(18, 2),
	cuota decimal(18, 2)
)
WITH (
    LOCATION = 'chess/objetivos_files/cobertura/',
    DATA_SOURCE = eds_delfos,
    FILE_FORMAT = eff_delfos_csv
)
