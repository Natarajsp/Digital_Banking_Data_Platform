-- Creating the database 
CREATE DATABASE azuredatabase

USE azuredatabase

-- Creating Schema 
CREATE SCHEMA landing

-- Creating Customers Table 
CREATE TABLE landing.Customers (
    customer_id VARCHAR(255),
    customer_name VARCHAR(255),
    gender VARCHAR(20),
    dob VARCHAR(20),
    phone VARCHAR(20),
    email VARCHAR(50),
    occupation VARCHAR(50),
    customer_type VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    created_date VARCHAR(20),
    status VARCHAR(20)
)

-- Creating Accounts Table 
CREATE TABLE landing.Accounts (
    account_id VARCHAR(255),
    customer_id VARCHAR(255),
    branch_id VARCHAR(255),
    account_number VARCHAR(255),
    account_type VARCHAR(50),
    balance VARCHAR(50),
    currency VARCHAR(50),
    opened_date VARCHAR(20),
    status VARCHAR(20)
)

-- Creating Branches Table 
CREATE TABLE landing.Branches (
    branch_id VARCHAR(255),
    branch_name VARCHAR(255),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    ifsc_code VARCHAR(50),
    manager_name VARCHAR(50),
    opened_date VARCHAR(20)
)

-- Creating Loans Table 
CREATE TABLE landing.Loans (
    loan_id VARCHAR(255),
    customer_id VARCHAR(50),
    branch_id VARCHAR(255),
    loan_type VARCHAR(50),
    loan_amount VARCHAR(50),
    interest_rate VARCHAR(50),
    loan_term VARCHAR(50),
    loan_status VARCHAR(20),
    disbursement_date VARCHAR(20)
)

-- Creating the ETL_File_Config table to store meta-data information related to landingZone AzureSQLDatabase files and tables 
CREATE TABLE dbo.ETL_File_Config
(
    config_id INT IDENTITY(1,1),
    source_folder VARCHAR(500),
    source_file VARCHAR(255),
    target_server VARCHAR(255),
    target_database VARCHAR(255),
    target_schema VARCHAR(100),
    target_table VARCHAR(255),
    is_active BIT
);

-- Insert the meta-data to ETL_File_Config table 
INSERT INTO ETL_File_Config
(
    source_folder,
    source_file,
    target_server,
    target_database,
    target_schema,
    target_table,
    is_active
)
VALUES
(
    'data/landing/sqlserver',
    'customers.csv',
    'mssqlazureserver.database.windows.net',
    'azuredatabase',
    'landing',
    'Customers',
    1
),
(
    'data/landing/sqlserver',
    'accounts.csv',
    'mssqlazureserver.database.windows.net',
    'azuredatabase',
    'landing',
    'Accounts',
    1
),
(
    'data/landing/sqlserver',
    'branches.csv',
    'mssqlazureserver.database.windows.net',
    'azuredatabase',
    'landing',
    'Branches',
    1
),
(
    'data/landing/sqlserver',
    'loans.csv',
    'mssqlazureserver.database.windows.net',
    'azuredatabase',
    'landing',
    'Loans',
    1
);

-- Display the table data using bolow queries

SELECT TOP 100 * FROM dbo.ETL_File_Config

SELECT COUNT(*) FROM landing.Customers
SELECT COUNT(*) FROM landing.Accounts
SELECT COUNT(*) FROM landing.Branches
SELECT COUNT(*) FROM landing.Loans

