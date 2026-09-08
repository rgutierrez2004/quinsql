# QuinSQL — Data Import and Export (LOAD / UNLOAD)

[← Back to User Guide](USERGUIDE.md)

---

## Table of Contents

- [Overview](#overview)
- [LOAD — Import Data](#load--import-data)
  - [Basic syntax](#basic-syntax)
  - [File formats supported](#file-formats-supported-for-load)
  - [Load modifiers](#load-modifiers)
  - [Examples](#load-examples)
- [UNLOAD — Export Data](#unload--export-data)
  - [Basic syntax](#unload-basic-syntax)
  - [File formats supported](#file-formats-supported-for-unload)
  - [Output file naming](#output-file-naming)
  - [Examples](#unload-examples)
- [SET LOADFORMAT — Configure the Export Format](#set-loadformat)
  - [CSV / DELIMITED options](#csv--delimited-options)
  - [JSON-FORMATTED](#json-formatted)
  - [INSERT](#insert)
  - [LOADER (SQL\*Loader)](#loader-sqlloader)
  - [PARQUET](#parquet)
  - [ARROW](#arrow)
- [SET LOAD — Configure Import Behaviour](#set-load)
  - [Batch and commit settings](#batch-and-commit-settings)
  - [Date and timestamp formats](#date-and-timestamp-formats)
  - [Error handling](#error-handling)
  - [Schema inference control](#schema-inference-control)
- [Parquet and Arrow — Advanced Details](#parquet-and-arrow--advanced-details)
  - [Oracle type mapping](#oracle-type-mapping)
  - [Streaming architecture](#streaming-architecture)
  - [Parquet vs Arrow IPC comparison](#parquet-vs-arrow-ipc-comparison)
- [Comparison with SQLcl](#comparison-with-sqlcl)
- [Complete Script Examples](#complete-script-examples)

---

## Overview

[^ top](#table-of-contents)

QuinSQL supports the same `LOAD` and `UNLOAD` commands as Oracle SQLcl, making it easy to
migrate existing scripts. It also extends the feature set with Apache Parquet and Apache Arrow
IPC output, gzip decompression on load, Excel workbook support, and schema inference.

`LOAD` and `UNLOAD` work in **both CLI (headless) and TUI (interactive) modes**. They can appear
in SQL scripts passed to `quinsql file`, or be typed directly at the TUI prompt.

---

## LOAD — Import Data

[^ top](#table-of-contents)

### Basic syntax

[^ top](#table-of-contents)

```sql
LOAD [TABLE] [schema.]table_name  file_path  [modifier]
```

| Part | Required | Description |
|---|---|---|
| `TABLE` | No | Optional keyword for clarity |
| `[schema.]table_name` | Yes | Target table; schema defaults to the connected user |
| `file_path` | Yes | Path to the source file |
| `modifier` | No | See [Load modifiers](#load-modifiers) |

### File formats supported for LOAD

[^ top](#table-of-contents)

| Extension | Format |
|---|---|
| `.csv` | Comma-separated values (delimiter and enclosure configurable) |
| `.gz` | Gzip-compressed CSV — decompressed transparently |
| `.xlsx`, `.xlsb`, `.xlsm` | Microsoft Excel workbook |
| `.xls` | Legacy Excel format |
| `.ods` | OpenDocument Spreadsheet |
| `.json` | JSON array |

The format is detected automatically from the file extension.

### Load modifiers

[^ top](#table-of-contents)

A modifier at the end of a `LOAD` statement controls what happens during import:

| Modifier | Aliases | Description |
|---|---|---|
| _(none)_ | | Load rows into the existing table |
| `NEW` | | Infer DDL from the file, create the table, then load all rows |
| `SHOW` | `DDL_SHOW`, `DDLSHOW` | Infer and print the DDL; do not create the table or load data |
| `CREATE` | `DDL_CREATE`, `DDLCREATE` | Infer and execute the DDL; do not load data |

The `SHOW` / `CREATE` variants are useful for reviewing the inferred schema before committing
to it.

### LOAD examples

[^ top](#table-of-contents)

```sql
-- Load CSV into an existing table
LOAD hr.employees employees.csv

-- Load gzip-compressed CSV
LOAD hr.employees employees.csv.gz

-- Load Excel spreadsheet into an existing table
LOAD hr.employees employees.xlsx

-- Infer schema, create table, then load
LOAD TABLE hr.new_employees new_employees.csv NEW

-- Preview the inferred DDL only (does not create or load)
LOAD TABLE hr.new_employees new_employees.csv SHOW

-- Create the table using inferred DDL, do not load yet
LOAD TABLE hr.new_employees new_employees.csv CREATE

-- Load JSON array into an existing table
LOAD hr.departments departments.json
```

**In a script file (`quinsql file`):**

```sql
SET FEEDBACK ON

-- Truncate existing data before loading
SET LOAD TRUNCATE ON

-- Load 50 000 rows per commit
SET LOAD BATCH_ROWS 50000
SET LOAD BATCHES_PER_COMMIT 1

-- Load from gzipped CSV
LOAD TABLE sh.sales sales_2025.csv.gz
```

**Headless (shell):**

```bash
# Load CSV via inline script
quinsql file <(printf 'LOAD TABLE hr.employees employees.csv') -p dev-hr

# Load Excel and create table
quinsql file <(printf 'LOAD TABLE hr.new_employees new_employees.xlsx NEW') -p dev-hr
```

---

## UNLOAD — Export Data

[^ top](#table-of-contents)

### UNLOAD basic syntax

[^ top](#table-of-contents)

```sql
UNLOAD [TABLE] [schema.]table_name  [ DIRECTORY | DIR  directory_path ]
```

| Part | Required | Description |
|---|---|---|
| `TABLE` | No | Optional keyword for clarity |
| `[schema.]table_name` | Yes | Source table to export |
| `DIRECTORY` / `DIR` | No | Output directory; defaults to the current working directory |

### File formats supported for UNLOAD

[^ top](#table-of-contents)

Set the format with `SET LOADFORMAT` before the `UNLOAD` command:

| Format | Description |
|---|---|
| `CSV` / `DELIMITED` | Comma-separated values (default) |
| `JSON` | JSON array (compact) |
| `JSON-FORMATTED` | JSON array with indentation for readability |
| `INSERT` | SQL `INSERT` statements — runnable in SQL\*Plus |
| `LOADER` | SQL\*Loader control file + data file pair |
| `PARQUET` | Apache Parquet (columnar; highly compressed) |
| `ARROW` | Apache Arrow IPC stream format |

### Output file naming

[^ top](#table-of-contents)

QuinSQL follows SQLcl naming conventions:

```
<TABLE>_DATA_TABLE.<ext>
```

For example, exporting `SH.SALES` to CSV produces `SALES_DATA_TABLE.csv`.
If the file already exists, a numeric suffix is added: `SALES_DATA_TABLE_1.csv`,
`SALES_DATA_TABLE_2.csv`, and so on.

### UNLOAD examples

[^ top](#table-of-contents)

```sql
-- Export to CSV (default format)
UNLOAD hr.employees

-- Export to a specific directory
UNLOAD hr.employees DIR /data/export

-- Export a specific schema's table
UNLOAD TABLE sh.sales DIR /data/export

-- Export to JSON
SET LOADFORMAT JSON
UNLOAD hr.employees DIR /tmp/export

-- Export to formatted JSON
SET LOADFORMAT JSON-FORMATTED
UNLOAD hr.employees DIR /tmp/export

-- Export to SQL INSERT statements
SET LOADFORMAT INSERT
UNLOAD hr.employees DIR /tmp/export

-- Export to SQL*Loader format (control + data files)
SET LOADFORMAT LOADER
UNLOAD hr.employees DIR /tmp/loader

-- Export to Apache Parquet
SET LOADFORMAT PARQUET
UNLOAD sh.sales DIR /data/parquet

-- Export to Apache Arrow IPC
SET LOADFORMAT ARROW
UNLOAD sh.sales DIR /data/arrow
```

**Headless (shell):**

```bash
# Export to Parquet via inline script
quinsql file <(printf 'SET LOADFORMAT PARQUET\nUNLOAD TABLE sh.sales DIR /tmp/export') \
         -p prod-hr

# Export to CSV and compress with gzip
quinsql file <(printf 'SET LOADFORMAT CSV\nUNLOAD hr.employees DIR /tmp/export') \
         -p dev-hr && gzip /tmp/export/EMPLOYEES_DATA_TABLE.csv
```

---

## SET LOADFORMAT

[^ top](#table-of-contents)

`SET LOADFORMAT` controls the output format and format-specific options for `UNLOAD`.
It must be set before the `UNLOAD` command.

```sql
SET LOADFORMAT <format> [option value ...]
```

### CSV / DELIMITED options

[^ top](#table-of-contents)

```sql
SET LOADFORMAT CSV                     -- switch to CSV (also resets options to default)
SET LOADFORMAT DELIMITED               -- alias for CSV
SET LOADFORMAT CSV COLUMN_NAMES ON     -- include header row (default: ON)
SET LOADFORMAT CSV DELIMITER <char>    -- field delimiter (default: ,)
SET LOADFORMAT CSV ENCLOSURE <char>    -- quote character (default: ")
SET LOADFORMAT CSV ENCLOSURE OFF       -- disable quoting
SET LOADFORMAT CSV ENCODING <name>     -- character encoding (default: UTF-8)
SET LOADFORMAT CSV SKIP_ROWS <n>       -- skip n rows at start of file (LOAD only)
SET LOADFORMAT CSV ROW_LIMIT <n>       -- stop after n rows
SET LOADFORMAT CSV DOUBLE ON           -- represent double-quote as "" (RFC 4180)
```

**Examples:**

```sql
-- Pipe-separated, no header
SET LOADFORMAT CSV DELIMITER | COLUMN_NAMES OFF
UNLOAD hr.employees DIR /tmp

-- Tab-separated
SET LOADFORMAT CSV DELIMITER TAB
UNLOAD hr.employees DIR /tmp

-- Skip first 2 rows when loading
SET LOADFORMAT CSV SKIP_ROWS 2
LOAD hr.employees source.csv
```

### JSON-FORMATTED

[^ top](#table-of-contents)

```sql
SET LOADFORMAT JSON-FORMATTED
UNLOAD hr.employees DIR /tmp/export
```

Produces a pretty-printed JSON array — easier to read and inspect, slightly larger than `JSON`.

### INSERT

[^ top](#table-of-contents)

```sql
SET LOADFORMAT INSERT
UNLOAD hr.employees DIR /tmp/export
```

Produces a `.sql` file containing one `INSERT INTO ... VALUES (...)` statement per row.
The file can be run directly in SQL\*Plus, SQLcl, or QuinSQL CLI:

```bash
quinsql file EMPLOYEES_DATA_TABLE.sql -p dev-hr
```

### LOADER (SQL\*Loader)

[^ top](#table-of-contents)

```sql
SET LOADFORMAT LOADER
UNLOAD hr.employees DIR /tmp/loader
```

Produces two files:

| File | Contents |
|---|---|
| `EMPLOYEES_DATA_TABLE.ctl` | SQL\*Loader control file |
| `EMPLOYEES_DATA_TABLE.dat` | Data file |

Use with Oracle `sqlldr` to load into another Oracle instance:

```bash
sqlldr HR/password@target-db CONTROL=/tmp/loader/EMPLOYEES_DATA_TABLE.ctl
```

### PARQUET

[^ top](#table-of-contents)

```sql
SET LOADFORMAT PARQUET
UNLOAD sh.sales DIR /data/parquet
```

Exports to Apache Parquet — an open columnar binary format supported by Spark, Trino,
DuckDB, pandas, and virtually all modern data platforms.

- All Oracle number types are mapped to the correct Parquet/Arrow types (see [Oracle type mapping](#oracle-type-mapping))
- Data is written in streaming row-group batches; memory usage stays bounded regardless of table size
- Files are self-describing and include the Oracle schema embedded as Arrow metadata

### ARROW

[^ top](#table-of-contents)

```sql
SET LOADFORMAT ARROW
UNLOAD sh.sales DIR /data/arrow
```

Exports to Apache Arrow IPC stream format — zero-copy interchange format for in-process
and inter-process columnar analytics.

- Ideal for direct ingestion into data pipelines that support Arrow (DuckDB, Polars, PyArrow, etc.)
- Arrow IPC is a QuinSQL-specific extension; SQLcl does not support this format

---

## SET LOAD

[^ top](#table-of-contents)

`SET LOAD` configures how `LOAD` processes rows. Settings persist for the current session.

```sql
SET LOAD <key> <value>
```

### Batch and commit settings

[^ top](#table-of-contents)

| Setting | Default | Description |
|---|---|---|
| `BATCH_ROWS <n>` | `10000` | Rows per batch sent to Oracle |
| `BATCHES_PER_COMMIT <n>` | `1` | Commit after every N batches |
| `COMMIT ON\|OFF` | `ON` | Automatically commit after each batch group |
| `TRUNCATE ON\|OFF` | `OFF` | Truncate the target table before loading |

```sql
-- Large-table load — 50K rows per batch, commit every 5 batches
SET LOAD BATCH_ROWS 50000
SET LOAD BATCHES_PER_COMMIT 5

-- Truncate first, then load
SET LOAD TRUNCATE ON
LOAD hr.employees employees.csv
```

### Date and timestamp formats

[^ top](#table-of-contents)

| Setting | Default | Description |
|---|---|---|
| `DATE_FORMAT '<mask>'` | `YYYY-MM-DD` | Oracle date mask for date columns |
| `TIMESTAMP_FORMAT '<mask>'` | `YYYY-MM-DD HH24:MI:SS` | Timestamp mask |
| `TIMESTAMPTZ_FORMAT '<mask>'` | `YYYY-MM-DD HH24:MI:SS TZR` | Timestamp with time zone mask |
| `LOCALE <value>` | `en` | Locale for number and date parsing |

```sql
-- Load CSV with European date format
SET LOAD DATE_FORMAT 'DD/MM/YYYY'
SET LOAD TIMESTAMP_FORMAT 'DD/MM/YYYY HH24:MI:SS'
LOAD hr.events events_eu.csv
```

### Error handling

[^ top](#table-of-contents)

| Setting | Default | Description |
|---|---|---|
| `ERRORS <n>` | `50` | Abort after N row-level errors |
| `UNKNOWN_COLUMNS_FAIL ON\|OFF` | `OFF` | Reject load if the CSV has columns not in the table |
| `MAP_COLUMN_NAMES ON\|OFF` | `ON` | Match CSV headers to column names case-insensitively |

```sql
-- Strict load: fail immediately on any unknown column
SET LOAD UNKNOWN_COLUMNS_FAIL ON

-- Lenient load: allow up to 500 bad rows
SET LOAD ERRORS 500
```

### Schema inference control

[^ top](#table-of-contents)

| Setting | Default | Description |
|---|---|---|
| `SCAN_ROWS <n>` | `100` | Rows sampled when inferring DDL for `LOAD ... NEW` |

```sql
-- Scan 500 rows to infer types more accurately for sparse data
SET LOAD SCAN_ROWS 500
LOAD TABLE hr.new_employees new_employees.csv NEW
```

---

## Parquet and Arrow — Advanced Details

[^ top](#table-of-contents)

### Oracle type mapping

[^ top](#table-of-contents)

QuinSQL maps Oracle SQL types to Arrow/Parquet types with full fidelity:

| Oracle type | Arrow / Parquet type |
|---|---|
| `NUMBER` (no precision/scale) | `Float64` (`double`) |
| `NUMBER(p, 0)` precision ≤ 18 | `Int64` |
| `NUMBER(p, s)` | `Decimal128(p, s)` |
| `BINARY_FLOAT` | `Float32` |
| `BINARY_DOUBLE` | `Float64` |
| `DATE` | `Timestamp[microsecond]` |
| `TIMESTAMP` | `Timestamp[microsecond]` |
| `TIMESTAMP WITH TIME ZONE` | `Timestamp[microsecond, UTC]` |
| `VARCHAR2`, `NVARCHAR2` | `Utf8` |
| `CHAR`, `NCHAR` | `Utf8` |
| `CLOB`, `NCLOB` | `LargeUtf8` |
| `RAW` | `Binary` |
| `BLOB` | `LargeBinary` |
| Boolean | `Boolean` |
| Unknown / unsupported | `Utf8` (safe fallback) |

### Streaming architecture

[^ top](#table-of-contents)

Both Parquet and Arrow IPC exports use a **streaming writer**:

- Rows are fetched from Oracle in batches of up to 65,536 rows
- Each batch is written to the output file as a row group (Parquet) or record batch (Arrow)
- Memory usage is proportional to the batch size, not the full table size
- Very large tables (millions or billions of rows) export without running out of memory

This also means Parquet files will contain multiple row groups — one per batch — which is the
correct and expected structure for large Parquet files (e.g. Spark, Trino, DuckDB will read them
efficiently).

### Parquet vs Arrow IPC comparison

[^ top](#table-of-contents)

| Feature | Parquet | Arrow IPC |
|---|---|---|
| Format | Columnar binary, compressed | Columnar binary, uncompressed |
| Best for | Storage, archival, batch analytics | In-process pipelines, low-latency read |
| Ecosystem support | Spark, Hive, Trino, DuckDB, pandas, … | DuckDB, Polars, PyArrow, … |
| File size | Smaller (compression) | Larger (raw) |
| Read speed | Slower (decompression) | Fastest (zero-copy capable) |
| Oracle to Oracle | Via Spark / external tool | Via direct pipeline |
| QuinSQL support | Yes | Yes |
| SQLcl support | Yes | No (QuinSQL only) |

---

## Comparison with SQLcl

[^ top](#table-of-contents)

| Feature | SQLcl | QuinSQL |
|---|---|---|
| Requires JVM | Yes | No |
| CSV LOAD | Yes | Yes |
| Gzip CSV LOAD | Yes | Yes |
| Excel LOAD (xlsx/ods) | No | Yes |
| JSON UNLOAD | Yes | Yes |
| INSERT UNLOAD | Yes | Yes |
| SQL\*Loader UNLOAD | Yes | Yes |
| Parquet UNLOAD | Yes | Yes |
| Arrow IPC UNLOAD | No | Yes |
| Streaming export (bounded memory) | No | Yes |
| Oracle-native Parquet type mapping | Partial | Full |
| Schema inference (`NEW`) | No | Yes |

---

## Complete Script Examples

[^ top](#table-of-contents)

### Load from CSV and verify

```sql
SET FEEDBACK ON
SET LOAD BATCH_ROWS 10000
SET LOAD TRUNCATE OFF
SET LOAD ERRORS 100

LOAD TABLE hr.employees employees.csv

SELECT COUNT(*) AS loaded_rows FROM hr.employees;
```

### Load gzipped CSV with custom date format

```sql
SET LOAD DATE_FORMAT 'DD-MON-YYYY'
SET LOAD TIMESTAMP_FORMAT 'DD-MON-YYYY HH24:MI:SS.FF3'
SET LOAD BATCH_ROWS 50000

LOAD TABLE sh.sales_archive sales_2024.csv.gz
```

### Export to multiple formats in one script

```sql
SET FEEDBACK ON

-- CSV export
SET LOADFORMAT CSV COLUMN_NAMES ON
UNLOAD TABLE hr.employees DIR /data/export

-- Parquet export (same data)
SET LOADFORMAT PARQUET
UNLOAD TABLE hr.employees DIR /data/parquet

-- Arrow IPC export (same data)
SET LOADFORMAT ARROW
UNLOAD TABLE hr.employees DIR /data/arrow
```

### Full table refresh pipeline

```sql
-- Step 1: Truncate and reload from CSV
SET FEEDBACK ON
SET LOAD TRUNCATE ON
SET LOAD BATCH_ROWS 100000
SET LOAD BATCHES_PER_COMMIT 1

LOAD TABLE sh.sales sales_current.csv.gz

-- Step 2: Verify row count
SELECT COUNT(*) AS total_rows FROM sh.sales;

-- Step 3: Export to Parquet for the data warehouse
SET LOADFORMAT PARQUET
UNLOAD TABLE sh.sales DIR /data/warehouse/sales
```

### Create new table from CSV with inferred DDL

```sql
-- Preview what DDL will be inferred
LOAD TABLE reporting.new_kpi_data kpi_data.csv SHOW

-- Create the table (no data yet)
LOAD TABLE reporting.new_kpi_data kpi_data.csv CREATE

-- Load the data
LOAD TABLE reporting.new_kpi_data kpi_data.csv
```

### Export to SQL*Loader for cross-instance copy

```sql
-- On source instance
SET LOADFORMAT LOADER
UNLOAD TABLE hr.employees DIR /tmp/loader_export

-- Then on target instance via shell
-- sqlldr HR/password@target CONTROL=/tmp/loader_export/EMPLOYEES_DATA_TABLE.ctl
```
