CREATE OR ALTER PROCEDURE helpers.DropExternalTable
(
	@TableName AS VARCHAR(100)    
)
AS
BEGIN
    SET NOCOUNT ON
	DECLARE @Sql VARCHAR(MAX)
    IF EXISTS ( SELECT * FROM sys.external_tables 
		WHERE object_id = OBJECT_ID(@TableName))
	BEGIN
		SET @SQL = CONCAT('DROP EXTERNAL TABLE ',@TableName)
		EXEC(@SQL)
	END
END