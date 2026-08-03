# Digital Banking Data Platform — Source Data (Bronze / messy)

Generated from `Digital_Banking_Data_Platform_-_Source_Architecture.docx`, following its
folder layout and schemas. This is the **messy Bronze version** — every file started as
a clean, fully-consistent dataset (5,000/8,000/3,000/150/100,000/721/1,000,000/200,000
records exactly matching the doc), then had realistic data-quality issues injected on
top: nulls, duplicates, orphaned foreign keys, inconsistent formats, and bad values. Row
counts below are now higher than the doc's target because duplicates are extra rows, not
replacements — that's intentional, the same way a real ingestion replay would leave them.

All data is synthetic. Bank name used throughout: **NovaTrust Bank** (fictional).
Reference "today" for all relative dates: **2026-08-01**.

## Folder structure

```
DigitalBankingData/
├── sqlserver/
│   ├── customers.csv        5,065 rows  (5,000 clean + 50 exact dup + 15 near-dup)
│   ├── accounts.csv         8,080 rows  (8,000 clean + 80 exact dup)
│   ├── loans.csv            3,030 rows  (3,000 clean + 30 exact dup)
│   └── branches.csv         152 rows    (150 clean + 2 exact dup)
├── kafka/
│   ├── transactions.json    102,000 rows (JSON Lines — 100,000 + 2,000 dup)
│   └── transaction_producer.py   real producer script, unaffected by this pass
├── api/
│   └── fx_rates_sample.json  728 snapshots (721 + 7 duplicate-timestamp retries)
├── parquet/
│   └── historical_data.parquet   1,012,000 rows (1,000,000 + 12,000 dup)
└── json/
    └── mobile_events.json    203,000 rows (JSON Lines — 200,000 + 3,000 dup)
```

## Known data quality issues (by file)

Use this as the answer key for your Silver-layer cleaning logic — every issue below was
injected deliberately and can be verified against these counts.

**customers.csv** — blank `email` (~100), `phone` (~75), `occupation` (~75), `gender`
(~50); 50 exact duplicate rows; 15 near-duplicate customers (same person, new
`customer_id`, name in different casing — a duplicate-signup pattern, not a re-ingested
row); ~50 invalid `dob` (future-dated or 130+ years old); whitespace padding on
`customer_name`/`city`; `status` in mixed casing; ~400 `dob`/`created_date` values in
alternate formats (`DD/MM/YYYY`, `MM/DD/YYYY`, `YYYY.MM.DD`, `DD-MM-YYYY`) instead of
`YYYY-MM-DD`; ~900 `phone` values with inconsistent formatting (`+91` prefix, leading
`0`, dashes, spaces); ~500 `email` values with inconsistent casing.

**accounts.csv** — blank `balance` (~160), blank `account_type` (~120); ~120 negative
balances; **80 rows with a `customer_id` that doesn't exist in `customers.csv`**
(orphaned FK — simulates a deleted/late-arriving customer record); `currency` in mixed
casing (`inr`/`INR`/`Inr`); ~640 `opened_date` values in alternate formats; `status` in
mixed casing; 80 exact duplicate rows.

**loans.csv** — blank `interest_rate` (~60), blank `loan_amount` (~45); ~30 rows with an
invalid `interest_rate` (0%, negative, or 45%+); **30 orphaned `customer_id` + 15
orphaned `branch_id`**; `loan_status` with casing/typo variants (`ACTIVE`, `actve`,
`Active `, `Closd`, etc.); 30 exact duplicate rows.

**branches.csv** — 4 blank `manager_name`; a few `state` values upper-cased; 2 exact
duplicate rows.

**kafka/transactions.json** — **2,000 duplicate `transaction_id`** (simulates Kafka
at-least-once redelivery); ~1,200 records missing the `channel` key entirely; ~1,000
missing `amount`; ~1,500 with `amount` typed as a **string** instead of a number;
~1,200 with `customer_id` or `account_id` set to JSON `null`; ~3,000 with
`transaction_timestamp` in an alternate format (no `Z`, `.000Z` milliseconds, or a Unix
epoch integer instead of ISO-8601); ~5,000 `status` values in mixed casing.

**api/fx_rates_sample.json** — ~22 snapshots missing one currency's rate entirely (key
absent — partial API failure); ~11 snapshots with a rate explicitly `null`; 7 duplicate
snapshots carrying the previous poll's timestamp (retry logged twice).

**parquet/historical_data.parquet** — **true Parquet `NULL`s** (not sentinels) in
`customer_id` (~15,000) and `amount` (~15,000); **12,000 duplicate `transaction_id`**
rows; **~10,000 rows with an `account_id` that doesn't exist** in `accounts.csv`
(archived/deleted account, orphaned FK); ~5,000 negative amounts; ~3,000 extreme
outlier amounts (₹5M–₹50M, plausible decimal-point entry errors); ~10,000 rows where
`month` no longer matches the month embedded in `transaction_date` (derived-column
drift). `customer_id`/`amount` are declared `OPTIONAL` in the file's schema, so
`df.isNull()` / `df.dropna()` work exactly as they would against a real nullable Bronze
table — no sentinel-value tricks.

**json/mobile_events.json** — ~2,400 records missing `device_type`, ~2,000 missing
`os`; ~1,200 with `customer_id` set to `null`; ~1,200 with an **orphaned `customer_id`**
that doesn't exist in `customers.csv`; ~1,600 with `latitude`/`longitude` set to a bad
sentinel (`0,0` "null island" or `999,999` out-of-range); ~6,000 `event_timestamp`
values in an alternate format; ~10,000 `event_type` values in mixed casing; 3,000
duplicate `event_id` rows.

## Schemas (as specified in the doc)

**customers.csv** — `customer_id, customer_name, gender, dob, phone, email, occupation,
customer_type, city, state, country, created_date, status`

**accounts.csv** — `account_id, customer_id, branch_id, account_number, account_type,
balance, currency, opened_date, status`. Account types: Savings/Current/Salary.

**branches.csv** — `branch_id, branch_name, city, state, country, ifsc_code,
manager_name, opened_date`. IFSC-format codes (`NOVA0######`).

**loans.csv** — `loan_id, customer_id, branch_id, loan_type, loan_amount, interest_rate,
loan_term, loan_status, disbursement_date`.

**kafka/transactions.json** — `transaction_id, customer_id, account_id, branch_id,
transaction_type, channel, amount, currency, status, transaction_timestamp`.

**api/fx_rates_sample.json** — array of hourly snapshots shaped like the doc's example:
`{"base": "USD", "timestamp": "...", "rates": {"INR": ..., "CAD": ..., "EUR": ...,
"GBP": ..., "JPY": ...}}`.

**parquet/historical_data.parquet** — `transaction_id, customer_id, account_id,
branch_id, amount, transaction_date, year, month`. `transaction_date` is a proper
`DATE` column (INT32 days-since-epoch); `customer_id`/`amount` are `OPTIONAL` (nullable).

**json/mobile_events.json** — `event_id, customer_id, device_type, os, app_version,
event_type, session_id, ip_address, latitude, longitude, event_timestamp`.

## What's still true from the clean version

The underlying data (real customers, real account/loan/transaction relationships,
realistic amounts, the 2021‑01‑01→2026‑05‑02 vs 2026‑05‑03→2026‑08‑01 historical/live
date split) is exactly what was in the clean version — this pass only *added* messiness
on top of a minority of rows/fields, it didn't regenerate anything. So every FK that
*isn't* called out above as "orphaned" is still valid, every date that isn't called out
as reformatted is still `YYYY-MM-DD`, etc.

## A note on the Parquet file

No `pyarrow`/`fastparquet` is available in this sandbox and there's no internet access
to install one, so `historical_data.parquet` (including the nullable-column support
used for this messy pass) is written by a small pure-Python Parquet writer built for
this task. Checked via a byte-for-byte round-trip against an independent decoder I
wrote (including dedicated tests for all-null, all-present, and mixed
definition-level runs), the Linux `file` utility identifying it as genuine
`Apache Parquet`, and a full decode + issue-count check of all 1,012,000 rows. I can't
test it against real PyArrow/Spark from here — worth a quick `spark.read.parquet(...)`
sanity check the first time you load it in Databricks.

## Kafka producer script

`kafka/transaction_producer.py` is a working producer (`kafka-python`) that reads
`accounts.csv` and streams synthetic transactions to a real topic. Untouched by this
messy-data pass — it always generates clean events; that's a reasonable default for a
live producer, but let me know if you'd like it to occasionally emit messy events too
(missing fields, bad types) to simulate a flaky upstream system.

## Assumptions made (doc didn't specify)

- FX history window: 30 days hourly (721 base snapshots).
- Loan types/terms, occupation list, city/state pool, IFSC prefix, session ID format:
  not specified in the doc, chosen for realism.
- `historical_data.parquet` interpreted as archived **transactions** (not account
  snapshots), matching its listed columns and stated purpose.
- Messiness rates (1-8% per issue, per file, detailed above): not specified in the doc,
  calibrated to be realistic without making any single file unusable.
