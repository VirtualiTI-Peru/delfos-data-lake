CREATE OR ALTER PROCEDURE silver.spArticulo_Anular
AS
BEGIN
	DECLARE @ResultMessage VARCHAR(MAX) = 'No hay articulos para anular'
	DECLARE @StartDateProc DateTime = GETDATE()

	DECLARE @Sql VARCHAR(MAX)
	DECLARE @Version INT = 1
	DECLARE @RowsAffected INT = 0
	DECLARE @TableName AS VARCHAR(100)
	DECLARE @dateFormat AS VARCHAR(14) = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	SET @TableName = CONCAT('articuloAnular', @dateFormat)

	-- Solo anular si bronze tiene datos (evita marcar todo como anulado ante una ingesta vacia/fallida)
	IF EXISTS (SELECT TOP 1 1 FROM bronze.EArticulo)
	AND EXISTS (
		SELECT TOP 1 1
		FROM gold.Articulo G
		WHERE ISNULL(G.anulado, 0) = 0
		  AND NOT EXISTS (
				SELECT 1
				FROM bronze.EArticulo B
				WHERE B.idArticulo = G.idArticulo
		  )
	)
	BEGIN
		SET @Version = ISNULL(
							(SELECT
								MAX(result.filepath(1))
							FROM
								OPENROWSET(
									BULK 'chess/parquet_files/articulo/Ver=*/*/*.parquet',
									DATA_SOURCE = 'eds_delfos',
									FORMAT = 'PARQUET'
								) AS result)
							, 0) + 1

		DECLARE @folderName AS VARCHAR(100) = CONCAT('/chess/parquet_files/articulo/Ver=', @Version, '/', @dateFormat, '/')
		BEGIN TRY
			SELECT @RowsAffected = COUNT(*)
			FROM gold.Articulo T1
			WHERE ISNULL(T1.anulado, 0) = 0
			  AND NOT EXISTS (
					SELECT 1
					FROM bronze.EArticulo B
					WHERE B.idArticulo = T1.idArticulo
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
							T1.idArticulo
							,T1.desArticulo
							,T1.descDetallada
							,T1.unidadesBulto
							,CAST(1 AS bit) AS anulado
							,T1.fechaAlta
							,T1.factorVenta
							,T1.minimoVenta
							,T1.pesable
							,T1.pesoCotaSuperior
							,T1.pesoCotaInferior
							,T1.esCombo
							,T1.detalleComboImp
							,T1.detalleComboInf
							,T1.exentoIva
							,T1.inafecto
							,T1.exonerado
							,T1.ivaDiferencial
							,T1.tasaIva
							,T1.tasaInternos
							,T1.internosBulto
							,T1.tasaIibb
							,T1.esAlcoholico
							,T1.visibleMobile
							,T1.esComodatable
							,T1.desCortaArticulo
							,T1.idPresentacionBulto
							,T1.desPresentacionBulto
							,T1.idPresentacionUnidad
							,T1.desPresentacionUnidad
							,T1.idUnidadMedida
							,T1.desUnidadMedida
							,T1.valorUnidadMedida
							,T1.idArticuloEstadistico
							,T1.codBarraBulto
							,T1.codBarraUnidad
							,T1.tieneRetornables
							,T1.bultosPallet
							,T1.pisosPallet
							,T1.apilabilidad
							,T1.pesoBulto
							,T1.llevaFrescura
							,T1.diasBloqueo
							,T1.politicaStock
							,T1.diasVentana
							,T1.esActivoFijo
							,T1.cantidadPuertas
							,T1.unidadesFrente
							,T1.litrosRepago
							,T1.idArtUsado
							,T1.aniosAmortizacion
							,' + CAST(@Version AS VARCHAR(10)) + ' AS Ver
						FROM gold.Articulo T1
						WHERE ISNULL(T1.anulado, 0) = 0
						  AND NOT EXISTS (
								SELECT 1
								FROM bronze.EArticulo B
								WHERE B.idArticulo = T1.idArticulo
						  )'
			EXEC (@SQL)
			EXEC helpers.DropExternalTable @TableName
			SET @ResultMessage = CONCAT('Articulos marcados como anulados (ausentes en bronze) (', @RowsAffected, ' filas)')
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
		,'silver.spArticulo_Anular' AS ProcedureName
		,@ResultMessage AS LogMessage
END
