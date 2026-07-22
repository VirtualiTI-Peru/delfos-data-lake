CREATE OR ALTER PROCEDURE silver.spCliente_Anular
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay clientes para anular'
	DECLARE @StartDateProc DateTime = GETDATE()

	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @TableName AS VARCHAR(100)
	DECLARE @dateFormat AS VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	DECLARE @fechaBaja AS NVARCHAR(100) = CONVERT(VARCHAR(23), GETDATE(), 126)
	SET @TableName = CONCAT('clienteAnular', @dateFormat)

	-- Solo anular si bronze tiene datos (evita marcar todo como anulado ante una ingesta vacia/fallida)
	IF EXISTS (SELECT TOP 1 1 FROM bronze.ECliente)
	AND EXISTS (
		SELECT TOP 1 1
		FROM gold.Cliente G
		WHERE ISNULL(G.anulado, 0) = 0
		  AND NOT EXISTS (
				SELECT 1
				FROM bronze.ECliente B
				WHERE B.idCliente = G.idCliente
		  )
	)
	BEGIN
		SET @Version = ISNULL(
							(SELECT
								MAX(result.filepath(1))
							FROM
								OPENROWSET(
									BULK 'chess/parquet_files/cliente/Ver=*/*/*.parquet',
									DATA_SOURCE = 'eds_delfos',
									FORMAT = 'PARQUET'
								) AS result)
							, 0) + 1

		DECLARE @folderName AS VARCHAR(100) = CONCAT('/chess/parquet_files/cliente/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SELECT @RowsAffected = COUNT(*)
			FROM gold.Cliente T1
			WHERE ISNULL(T1.anulado, 0) = 0
			  AND NOT EXISTS (
					SELECT 1
					FROM bronze.ECliente B
					WHERE B.idCliente = T1.idCliente
			  )

			SET @SQL =
				'CREATE EXTERNAL TABLE ' + @TableName +
				' WITH (
						LOCATION = ''' + @folderName + ''',
						DATA_SOURCE = eds_delfos,
						FILE_FORMAT = eff_delfos_parquet
					)
					AS
						SELECT
							T1.idSucursal
							,T1.desSucursal
							,T1.idCliente
							,T1.fechaAlta
							,CAST(1 AS bit) AS anulado
							,CAST(''' + REPLACE(@fechaBaja, '''', '''''') + ''' AS nvarchar(100)) AS fechaBaja
							,T1.idAliasVigente
							,T1.idFormaPago
							,T1.desFormaPago
							,T1.plazoPago
							,T1.idListaPrecio
							,T1.desListaPrecio
							,T1.idComprobante
							,T1.desComprobante
							,T1.limiteImporte
							,T1.idArtLimite
							,T1.desArtLimite
							,T1.cantArtLimite
							,T1.cpbtesImpagos
							,T1.diasDeudaVencida
							,T1.idPais
							,T1.idProvincia
							,T1.desProvincia
							,T1.idDepartamento
							,T1.desDepartamento
							,T1.idLocalidad
							,T1.desLocalidad
							,T1.calle
							,T1.altura
							,T1.entreCalle1
							,T1.entreCalle2
							,T1.comentario
							,T1.longitudGeo
							,T1.latitudGeo
							,T1.horario
							,T1.idLocalidadEntrega
							,T1.desLocalidadEntrega
							,T1.calleEntrega
							,T1.alturaEntrega
							,T1.pisoDeptoEntrega
							,T1.entreCalle1Entrega
							,T1.entreCalle2Entrega
							,T1.comentarioEntrega
							,T1.longitudGeoEntrega
							,T1.latitudGeoEntrega
							,T1.horarioEntrega
							,T1.telefonoFijo
							,T1.telefonoMovil
							,T1.email
							,T1.comentarioAdicional
							,T1.idComisionVenta
							,T1.desComisionVenta
							,T1.idComisionFlete
							,T1.desComisionFlete
							,T1.porcentajeFlete
							,T1.idSubcanalMkt
							,T1.desSubcanalMkt
							,T1.idCanalMkt
							,T1.desCanalMkt
							,T1.idSegmentoMkt
							,T1.desSegmentoMkt
							,T1.idRamo
							,T1.desRamo
							,T1.idArea
							,T1.desArea
							,T1.idAgrupacion
							,T1.desAgrupacion
							,T1.esPotencial
							,T1.esCuentayOrden
							,T1.idOcasionConsumo
							,T1.desOcasionConsumo
							,T1.idSubcategoriaFoco
							,T1.desSubcategoriaFoco
							,T1.focoTrade
							,T1.focoVentas
							,T1.clusterVentas
							,' + CAST(@Version AS VARCHAR(10)) + ' AS Ver
						FROM gold.Cliente T1
						WHERE ISNULL(T1.anulado, 0) = 0
						  AND NOT EXISTS (
								SELECT 1
								FROM bronze.ECliente B
								WHERE B.idCliente = T1.idCliente
						  )'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Clientes marcados como anulados (ausentes en bronze) (', @RowsAffected, ' filas)')
		END TRY
		BEGIN CATCH
			SET @ResultMessage = CONCAT(
				'Error No: ', ERROR_NUMBER()
				,'Message: ', ERROR_MESSAGE()
			)
		END CATCH
	END

	SELECT
		@StartDateProc
		,GETDATE()
		,'silver.spCliente_Anular' AS ProcedureName
		,@ResultMessage AS LogMessage
END
