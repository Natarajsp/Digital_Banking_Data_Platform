-- Create the store procedure for updating the ETL_File_config table after landingZone SQL file got loaded to Azure SQL table 
CREATE OR ALTER PROCEDURE dbo.update_ETL_File_config 
    @config_id INT
AS
BEGIN
    UPDATE dbo.ETL_File_config 
    SET is_active = 0
    WHERE config_id = @config_id;
END

GO
-- To Execute the stored procedure use below query 
EXEC update_ETL_File_config 1;


