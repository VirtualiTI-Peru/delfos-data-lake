CREATE OR ALTER VIEW gold.Supervisor
AS
SELECT [idSucursal]
      ,[idPersonal]
      ,[desPersonal]
  FROM [gold].[PersCom]
  WHERE 
    cargo = 'SUPERVISOR'