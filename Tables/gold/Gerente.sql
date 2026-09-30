CREATE OR ALTER VIEW gold.Vendedor
AS
SELECT [idSucursal]
      ,[idPersonal]
      ,[desPersonal]
  FROM [gold].[PersCom]
  WHERE 
    cargo = 'GERENTE'
  ORDER BY desPersonal