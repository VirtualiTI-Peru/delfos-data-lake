CREATE OR ALTER VIEW gold.Vendedor
AS
SELECT [idSucursal]
      ,[idPersonal]
      ,[desPersonal]
      ,[idPersonalSuperior]
  FROM [gold].[PersCom]
  WHERE 
    cargo = 'VENDEDOR'