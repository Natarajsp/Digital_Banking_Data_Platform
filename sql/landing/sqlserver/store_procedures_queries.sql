-- Create the store procedure for updating the ETL_File_config table after landingZone SQL file got loaded to Azure SQL table 
CREATE OR ALTER PROCEDURE dbo.update_ETL_File_config 
    @config_id INT
AS
BEGIN
    UPDATE dbo.ETL_File_config 
    SET is_active = 0
    WHERE config_id = @config_id;
END

GO;

-- To Execute the stored procedure use below query 
EXEC update_ETL_File_config 1;

GO;
    
-- Stored Procedure to update the dbo.etl_audit table along with watermark Column change 
-- Create the audit-start stored procedure 
CREATE OR ALTER PROCEDURE dbo.SP_Audit_Start 
    @config_id INT,
    @pipeline_run_id VARCHAR(255),
    @old_watermark DATETIME2 = NULL
AS 
    BEGIN
        INSERT INTO dbo.etl_audit 
        (
            config_id,
            pipeline_run_id,
            start_time,
            records_read,
            records_written,
            old_watermark,
            status
        ) 
        VALUES 
        (
            @config_id,
            @pipeline_run_id,
            SYSUTCDATETIME(),
            0,
            0,
            @old_watermark,
            'RUNNING'
        );
    END;

GO;
    
-- Create sp_etl_audit_complete 

CREATE PROCEDURE dbo.SP_etl_audit_complete
    @config_id INT,
    @pipeline_run_id VARCHAR(100),
    @records_read BIGINT,
    @records_written BIGINT,
    @new_watermark DATETIME2 = NULL,
    @status VARCHAR(20),
    @error_message VARCHAR(4000) = NULL
AS
BEGIN

    UPDATE dbo.etl_audit
    SET
        end_time = SYSUTCDATETIME(),
        records_read = @records_read,
        records_written = @records_written,
        new_watermark = @new_watermark,
        status = @status,
        error_message = @error_message
    WHERE config_id = @config_id
      AND pipeline_run_id = @pipeline_run_id;

END;

GO;

--  Create the store procedure to update the new_watermark column value 
CREATE OR ALTER PROCEDURE dbo.SP_update_Audit_new_watermark 
@config_id INT,
@last_watermark DATETIME2 = NULL

AS 

BEGIN

    UPDATE dbo.etl_config 
    SET last_watermark = @last_watermark
    WHERE config_id = @config_id

END;

GO;

