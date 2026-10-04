CREATE EXTERNAL TABLE bronze.DiasNoLaborables(
	fecha nchar(10),
	tipo nvarchar(20),
	descripcion nvarchar(200)
)
WITH (
    LOCATION = 'chess/objetivos_files/calendario/',
    DATA_SOURCE = eds_delfos,
    FILE_FORMAT = eff_delfos_csv
)
