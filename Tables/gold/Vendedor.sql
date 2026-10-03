CREATE OR ALTER VIEW gold.Vendedor
AS
SELECT [idSucursal]
      ,[desSucursal]
      ,[idPersonal]
      ,[desPersonal]
      ,[idPersonalSuperior]
      ,[desPersonalSuperior] as [desSupervisor]
  FROM [gold].[PersCom]
  WHERE 
    cargo = 'VENDEDOR'