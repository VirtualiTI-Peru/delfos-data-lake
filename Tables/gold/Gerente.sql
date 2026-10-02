CREATE OR ALTER VIEW gold.Gerente
AS
SELECT [idSucursal]
      ,[idPersonal]
      ,[desPersonal]
  FROM [gold].[PersCom]
  WHERE 
    cargo = 'GERENTE'