SELECT TOP (1000) * FROM [dbo].[etl_config]


INSERT INTO etl_config
(
    source_system,
    source_type,
    source_schema,
    source_table,
    source_path,
    target_schema,
    target_table,
    target_path,
    load_type,
    watermark_column,
    last_watermark,
    primary_key_column,
    file_format,
    is_active,
    created_date,
    modified_date
)
VALUES
-- Customers
(
    'AzureSQL',
    'AzureSQL',
    'landing',
    'Customers',
    NULL,
    'bronze',
    'customers',
    'data/landing_zone/sqlserver/customers/',
    'INCREMENTAL',
    'created_date',
    NULL,
    'customer_id',
    'parquet',
    1,
    GETDATE(),
    GETDATE()
),

-- Accounts
(
    'AzureSQL',
    'AzureSQL',
    'landing',
    'Accounts',
    NULL,
    'bronze',
    'accounts',
    'data/landing_zone/sqlserver/accounts/',
    'INCREMENTAL',
    'opened_date',
    NULL,
    'account_id',
    'parquet',
    1,
    GETDATE(),
    GETDATE()
),

-- Loans
(
    'AzureSQL',
    'AzureSQL',
    'landing',
    'Loans',
    NULL,
    'bronze',
    'loans',
    'data/landing_zone/sqlserver/loans/',
    'INCREMENTAL',
    'disbursement_date',
    NULL,
    'loan_id',
    'parquet',
    1,
    GETDATE(),
    GETDATE()
),

-- Branches
(
    'AzureSQL',
    'AzureSQL',
    'landing',
    'Branches',
    NULL,
    'bronze',
    'branches',
    'data/landing_zone/sqlserver/branches/',
    'FULL',
    NULL,
    NULL,
    'branch_id',
    'parquet',
    1,
    GETDATE(),
    GETDATE()
),

-- FX Rates API
(
    'FX_API',
    'REST_API',
    NULL,
    NULL,
    'https://raw.githubusercontent.com/Natarajsp/Digital_Banking_Data_Platform/refs/heads/main/data/landing/api/fx_rates_sample.json',
    'bronze',
    'fx_rates',
    'data/landing_zone/api/fx_rates/',
    'INCREMENTAL',
    'timestamp',
    NULL,
    'base',
    'json',
    1,
    GETDATE(),
    GETDATE()
),

-- Historical Transactions
(
    'Partner',
    'ADLS',
    NULL,
    'historical_transactions',
    'landing/parquet/',
    'bronze',
    'historical_transactions',
    'data/landing_zone/parquet/historical_transactions/',
    'FULL',
    NULL,
    NULL,
    'transaction_id',
    'parquet',
    1,
    GETDATE(),
    GETDATE()
),

-- Mobile Events
(
    'Mobile',
    'ADLS',
    NULL,
    'mobile_events',
    'https://raw.githubusercontent.com/Natarajsp/Digital_Banking_Data_Platform/refs/heads/main/data/landing/json/mobile_events.json',
    'bronze',
    'mobile_events',
    'data/landing_zone/json/mobile_events/',
    'INCREMENTAL',
    'event_timestamp',
    NULL,
    'event_id',
    'json',
    1,
    GETDATE(),
    GETDATE()
);
