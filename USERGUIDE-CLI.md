# QuinSQL — CLI / Headless Mode

[← Back to User Guide](USERGUIDE.md)

---

## Table of Contents

- [Overview](#overview)
- [Global Flag: `-p / --profile`](#global-flag--p----profile)
- [Commands](#commands)
  - [connect](#connect)
  - [connect-save](#connect-save)
  - [connect-delete](#connect-delete)
  - [exec](#exec)
  - [file](#file)
  - [job](#job)
  - [setup](#setup)
  - [admin-password](#admin-password)
  - [export](#export)
  - [import](#import)
- [Output Formats](#output-formats)
- [Exit Codes](#exit-codes)
- [Piping and Scripting](#piping-and-scripting)
- [SQL\*Plus Script Compatibility](#sqlplus-script-compatibility)

---

## Overview

[^ top](#table-of-contents)

CLI mode runs a single SQL statement or an entire script file without opening the interactive
terminal UI. It is designed for automation, CI/CD pipelines, and shell scripting.

```bash
# General form
quinsql <command> [options] [-p <profile>]
```

All CLI commands honour the global `-p / --profile` flag to specify which saved connection
profile to use.

---

## Global Flag: `-p / --profile`

[^ top](#table-of-contents)

```bash
-p, --profile <name>
```

Specifies the saved connection profile to use. If omitted, QuinSQL uses the profile marked
as the default (if one exists) or prompts you to pick one interactively.

The `-p` flag works with `connect`, `exec` and `file` subcommands.

```bash
quinsql exec "SELECT SYSDATE FROM dual" -p prod-hr
quinsql file deploy.sql -p prod-hr
```

---

## Commands

[^ top](#table-of-contents)

### connect

[^ top](#table-of-contents)

Opens the interactive TUI. If no profile is given, the profile picker is shown.

```bash
quinsql connect [PROFILE]
quinsql connect -p prod-hr
quinsql                        # same as connect with no argument
```

`connect` is also the default command — running `quinsql` with no subcommand is equivalent
to `quinsql connect`.

---

### connect-save

[^ top](#table-of-contents)

Creates or updates a saved connection profile. The connection is verified before saving.
All credentials are prompted interactively (no echo) and stored in the OS keychain or
an encrypted file — never in the profile database.

```bash
quinsql connect-save --name <name> --dsn <dsn> --user <user> [options]
```

**Arguments:**

| Flag | Required | Description |
|---|---|---|
| `--name <name>` | Yes | Profile name; used with `-p` everywhere |
| `--dsn <dsn>` | Yes | Connect string: EZConnect, full descriptor, or TNS alias |
| `--user <user>` | Yes | Oracle database username |
| `--sysdba` | No | Connect with SYSDBA privilege |
| `--sysoper` | No | Connect with SYSOPER privilege |
| `--wallet-path <path>` | No | Path to a wallet `.zip` file or an already-extracted wallet directory |
| `--policy <preset>` | No | Safety policy preset; default `global` |

**Policy presets:**

| Value | Description |
|---|---|
| `global` | Inherit the application-wide policy |
| `open` | No confirmation required for any statement |
| `confirm-writes` | DML/DDL require confirmation; destructive require approval |
| `plan-approval` | Statements above READ require explicit approval |

**Oracle Wallet and ADB connections**

When `--wallet-path` points to a `.zip` file (the bundle downloaded from the Oracle Cloud
Console), QuinSQL extracts it automatically to:

```
~/.quinsql/wallets/<profile-name>/
```

The profile stores the path to this extracted directory. The original zip is not needed
after the profile is saved.

After extracting the zip, QuinSQL prompts for the **wallet password** — the password that
was set in the Oracle Cloud Console when downloading the wallet. This is separate from the
database password and is used to decrypt the TLS private key inside the wallet.

```
Password for ADMIN@...:           ← Oracle database password
Wallet password (set at download time, leave blank if none):   ← wallet download password
```

Leave the wallet password blank if the wallet directory was already extracted and the
`ewallet.pem` file contains an unencrypted private key.

If Oracle Cloud issues a new wallet (wallets have an expiry date), re-run `connect-save`
with the new zip path. QuinSQL will overwrite the extracted directory and update the stored
wallet password.

**Examples:**

```bash
# Basic development connection
quinsql connect-save --name dev-hr \
                     --dsn "localhost:1521/XEPDB1" \
                     --user HR

# Production connection with strict safety policy
quinsql connect-save --name prod-hr \
                     --dsn "db.prod.example.com:1521/HRPDB" \
                     --user HR \
                     --policy confirm-writes

# SYSDBA connection for administration
quinsql connect-save --name sys-dba \
                     --dsn "db.example.com:1521/CDB1" \
                     --user SYS \
                     --sysdba \
                     --policy plan-approval

# Oracle Autonomous Database — pass the zip downloaded from the Cloud Console
quinsql connect-save --name adb-prod \
                     --dsn '(description=(retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=adb.us-phoenix-1.oraclecloud.com))(connect_data=(service_name=abc123_myatp_high.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))' \
                     --user ADMIN \
                     --wallet-path ~/Wallet_myatp.zip

# ADB using a pre-extracted wallet directory (no zip extraction step)
quinsql connect-save --name adb-dev \
                     --dsn "myatp_low" \
                     --user ADMIN \
                     --wallet-path ~/.quinsql/wallets/adb-dev
```

---

### connect-delete

[^ top](#table-of-contents)

Permanently removes a saved profile, including its stored password, local catalog snapshot,
and command history.

```bash
quinsql connect-delete <profile-name>
```

**Example:**

```bash
quinsql connect-delete old-dev
```

---

### exec

[^ top](#table-of-contents)

Executes a single SQL statement against a saved profile and prints the result to stdout.

```bash
quinsql exec "<SQL>" -p <profile> [--format <fmt>] [--no-header]
```

**Arguments:**

| Flag | Description |
|---|---|
| `--format <fmt>` | Output format (see [Output Formats](#output-formats)); default `table` |
| `--no-header` | Omit the column header row |

**Examples:**

```bash
# Count rows
quinsql exec "SELECT COUNT(*) FROM employees" -p dev-hr

# Query with JSON output — pipe to jq
quinsql exec "SELECT employee_id, last_name FROM employees WHERE department_id = 90" \
         -p dev-hr --format json | jq '.[].last_name'

# CSV output — redirect to a file
quinsql exec "SELECT * FROM countries" -p dev-hr --format csv > countries.csv

# Markdown output — useful for documentation generation
quinsql exec "SELECT table_name, num_rows FROM user_tables" \
         -p dev-hr --format md

# No header — for downstream processing
quinsql exec "SELECT MAX(salary) FROM employees" -p dev-hr --no-header
```

---

### file

[^ top](#table-of-contents)

Runs a SQL script file. All SQL\*Plus-compatible statements are supported.
LOAD and UNLOAD commands (SQLcl-compatible) are also supported — see [LOAD/UNLOAD Guide](USERGUIDE-LOAD-UNLOAD.md).

```bash
quinsql file <script.sql> -p <profile> [--format <fmt>] [--no-header]
```

**Arguments:**

| Flag | Description |
|---|---|
| `--format <fmt>` | Output format for `SELECT` results; default `table` |
| `--no-header` | Omit column headers |

**Examples:**

```bash
# Run a deployment script
quinsql file deploy.sql -p prod-hr

# Run schema setup and capture output
quinsql file create_schema.sql -p dev-hr 2>&1 | tee setup.log

# Run a script with CSV output
quinsql file report.sql -p dev-hr --format csv > report.csv

# Inline script using process substitution (Linux/macOS)
quinsql file <(printf 'SELECT SYSDATE FROM dual;') -p dev-hr

# LOAD data from CSV inline
quinsql file <(printf 'LOAD TABLE hr.employees employees.csv') -p dev-hr

# UNLOAD to Parquet
quinsql file <(printf 'SET LOADFORMAT PARQUET\nUNLOAD TABLE sh.sales DIR /tmp/export') \
         -p prod-hr
```

**Script example (`deploy.sql`):**

```sql
SET FEEDBACK ON
SET ECHO ON

WHENEVER SQLERROR EXIT SQL.SQLCODE

-- Create a table
CREATE TABLE orders (
    order_id   NUMBER PRIMARY KEY,
    order_date DATE,
    status     VARCHAR2(20)
);

-- Insert initial data
INSERT INTO orders VALUES (1, SYSDATE, 'NEW');
INSERT INTO orders VALUES (2, SYSDATE, 'NEW');
COMMIT;

-- Verify
SELECT COUNT(*) AS total FROM orders;

EXIT 0
```

---

### job

[^ top](#table-of-contents)

Runs one scheduled job — this is the command the operating-system scheduler
(systemd user timer, launchd agent, or Task Scheduler task) launches at each
fire time.  Jobs are created and managed from the TUI with `/schedule`;
see the [TUI Guide](USERGUIDE-TUI.md#schedule).

```bash
quinsql job <id>          # e.g. quinsql job j-0143
```

The runner executes the job's `.sql` script through the normal QuinSQL
pipeline — same policy gates and audit journal — writing per-run output to
`~/.quinsql/schedule/logs/`, the run history to `schedule.db`, and (when
`[smtp]` is configured) an e-mail notification.  A second concurrent run of
the same job is skipped while one is active.

The runner never prompts: a statement that the profile's policy would gate on
(confirm / plan-approval) is *parked*, the run ends `pending_approval`, and
the job is automatically disabled.  Run it interactively once with
`/schedule run <id>` to answer the prompts at the keyboard and re-enable.

**Exit codes:**

| Code | Meaning |
|---|---|
| `0` | `ok` — all statements succeeded |
| `1` | `error` or `aborted` |
| `2` | `pending_approval` — a gated statement was parked; the job is disabled |
| `3` | skipped / configuration problem (job disabled, before start date, no credentials, previous run still active, schedule.db unreadable) |
| `4` | `cancelled` (user cancel or max-runtime timeout) |

**E-mail notifications** are configured with a `[smtp]` block in
`config.toml`:

```toml
[smtp]
host     = "smtp.example.com"
port     = 587                     # 587 for starttls, 465 for tls, 25 for none
security = "starttls"              # "starttls" | "tls" | "none"
user     = "alerts@example.com"    # omit for an unauthenticated relay
from     = "QuinSQL <alerts@example.com>"
```

The password is **not** in the file — store it once from the TUI with
`/schedule smtp-password` (saved encrypted in `credentials.enc`, the store
the runner reads).  Use *send test email* in `/schedule new` to verify.

---

### setup

[^ top](#table-of-contents)

Initialises the QuinSQL data directory and optionally installs Oracle Instant Client
for thick mode connectivity.

```bash
quinsql setup [--accept-license]
```

| Flag | Description |
|---|---|
| `--accept-license` | Accept the Oracle Instant Client license and download automatically |

Run this once after a fresh installation. Re-running is safe — existing configuration is not overwritten.

---

### admin-password

[^ top](#table-of-contents)

Manages the QuinSQL application-level admin password used to gate privileged operations.

```bash
# Set or change the admin password
quinsql admin-password set

# Reset (requires the current password)
quinsql admin-password reset
```

Both operations prompt for the password interactively; it is never passed as a command-line argument.

---

### export

[^ top](#table-of-contents)

Creates a portable ZIP backup of QuinSQL configuration.

```bash
quinsql export <output.zip> [--include-catalog] [--include-audit] [--include-schedule]
```

| Flag | Description |
|---|---|
| `--include-catalog` | Include the local schema catalog snapshot |
| `--include-audit` | Include the full audit journal |
| `--include-schedule` | Include scheduled jobs, run history, and each job's script (with its `@`/`@@` includes) |

Every export includes `config.toml`, `profiles.db`, `history.db`, the profile
passwords (re-encrypted with a key derived from the administrator password),
the SMTP password when `[smtp].user` is set, and every wallet directory a
profile references as an encrypted blob (`wallets/<n>.bin`) — wallet files are
never stored in clear.  `--include-schedule` adds `schedule.db` (jobs + run
history) and each job's main script under `scripts/<id>/` together with the
`@`-/`@@`-included files collected recursively.  Profiles whose connection
mode needs a live environment (OCI IAM token exchange, Entra ID) export
without credentials.

**Examples:**

```bash
# Minimal backup (profiles + config)
quinsql export ~/backups/quinsql-$(date +%Y%m%d).zip

# Full backup including catalog and audit
quinsql export ~/backups/quinsql-full.zip --include-catalog --include-audit
```

---

### import

[^ top](#table-of-contents)

Restores configuration from a `quinsql export` ZIP file.

```bash
quinsql import <file.zip> [--overwrite] [--data-dir <dir>] \
                          [--scripts-dir <dir>] [--wallet-dir <dir>]
```

| Flag | Description |
|---|---|
| `--overwrite` | Replace existing profiles and settings with those from the backup |
| `--data-dir <dir>` | Restore to a specific data directory instead of the default |
| `--scripts-dir <dir>` | Where job scripts go (default `~/scripts`; prompted when the archive has scripts and the flag is absent) |
| `--wallet-dir <dir>` | Where wallet directories go (default `~/wallet`; prompted likewise). Each wallet lands in `<wallet-dir>/<name>` (`<name>-2`, `-3`… if it exists, unless `--overwrite`) |

When the archive contains a schedule, import **merges** it: every job gets a
fresh `j-NNNN` id (the summary prints the `old → new` mapping), is imported
**disabled**, and its `script_path` is rewritten to
`<scripts-dir>/<old-id>/<file>`.  Run history is copied and remapped.  A
wallet is only extracted when at least one profile that references it was
imported in this run, and the profile's `wallet_path` is rewritten to the new
location — otherwise a `wallet for <profiles> not extracted` line is
printed, so repeated imports do not litter `-2`/`-3` copies.  Runner
credentials for imported jobs are written to the target **file store**
(`credentials.enc`) even when the configured store is the OS keyring; jobs
whose profile has no stored credential are listed with
`re-save via /schedule edit`.  Re-enable on the new machine with
`/schedule enable j-N` — OS timers are never registered during import.
Import does **not** rewrite paths inside script bodies (`UNLOAD … DIR`,
`LOAD … FILE`, `SPOOL`, `HOST`, `@/abs` includes); it prints
`⚠ <file>:<line>: <path> — not a valid path on this OS` for paths foreign
to the target OS — edit those scripts before enabling the job.
On Windows run that step from a terminal started as Administrator: S4U
tasks can only be created elevated (see the `/schedule` platform notes in
USERGUIDE-TUI).

**Examples:**

```bash
# Restore on a new machine (no existing profiles)
quinsql import quinsql-backup.zip

# Restore and overwrite existing settings
quinsql import quinsql-backup.zip --overwrite

# Restore to a custom directory
quinsql import quinsql-backup.zip --data-dir /opt/quinsql
```

---

## Output Formats

[^ top](#table-of-contents)

The `--format` flag (also `-f`) controls how `SELECT` results are printed to stdout.

| Value | Aliases | Description |
|---|---|---|
| `table` | `t` | Aligned, box-drawn table (default) |
| `csv` | `c` | Comma-separated values with header row |
| `json` | `j` | JSON array of objects |
| `md` | `markdown`, `m` | Markdown table |

```bash
quinsql exec "SELECT * FROM regions" -p dev-hr --format table
quinsql exec "SELECT * FROM regions" -p dev-hr --format csv
quinsql exec "SELECT * FROM regions" -p dev-hr --format json
quinsql exec "SELECT * FROM regions" -p dev-hr --format md
```

> Parquet and Arrow IPC output is available through the `UNLOAD` command.
> See [LOAD/UNLOAD Guide](USERGUIDE-LOAD-UNLOAD.md).

---

## Exit Codes

[^ top](#table-of-contents)

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | General error (connection failure, SQL error, etc.) |
| `N` | Custom code set by `EXIT N` in a script |

Use `$?` (Linux/macOS) or `%ERRORLEVEL%` (Windows) to check the exit code in scripts.

Windows note: spool files are written as UTF-8. PowerShell 7 reads them
correctly by default; in PowerShell 5.1 use `Get-Content <file> -Encoding UTF8`,
otherwise the box-drawing lines (`─`) show as garbled characters. Console
output and the TUI are unaffected.

```bash
quinsql file deploy.sql -p prod-hr
if [ $? -ne 0 ]; then
    echo "Deployment failed" >&2
    exit 1
fi
```

---

## Piping and Scripting

[^ top](#table-of-contents)

QuinSQL's headless mode is designed to compose with shell pipelines and standard tools.

```bash
# Extract a list of tables as JSON, filter with jq
quinsql exec "SELECT table_name FROM user_tables" \
         -p dev-hr --format json \
         | jq -r '.[].TABLE_NAME'

# Count rows and capture to a variable
ROWCOUNT=$(quinsql exec "SELECT COUNT(*) FROM orders" \
           -p dev-hr --no-header | tr -d ' ')
echo "Orders: $ROWCOUNT"

# Generate a CSV report and email it
quinsql exec "SELECT * FROM monthly_summary" \
         -p prod-hr --format csv > /tmp/report.csv
mail -s "Monthly Summary" team@example.com < /tmp/report.csv

# Run a series of scripts in sequence
for script in step1.sql step2.sql step3.sql; do
    quinsql file "$script" -p dev-hr || exit 1
done
```

---

## SQL\*Plus Script Compatibility

[^ top](#table-of-contents)

`quinsql file` runs existing SQL\*Plus scripts without modification.
All standard SQL\*Plus commands are supported:

| Command | Description |
|---|---|
| `SET FEEDBACK ON\|OFF` | Show/hide row counts and completion messages |
| `SET ECHO ON\|OFF` | Echo each command before executing |
| `SET HEADING ON\|OFF` | Show/hide column headers |
| `SET LINESIZE <n>` | Output line width |
| `SET PAGESIZE <n>` | Rows per page |
| `SET SERVEROUTPUT ON` | Enable `DBMS_OUTPUT` output |
| `SET DEFINE OFF\|ON\|<char>` | Enable/disable substitution variables |
| `SET TIMING ON\|OFF` | Show execution time per statement |
| `SET VERIFY ON\|OFF` | Show old/new values for substitution variables |
| `SET NULL '<text>'` | Text displayed for NULL values |
| `SET COLSEP '<char>'` | Column separator character |
| `DEFINE <var> = <value>` | Define a substitution variable |
| `@<file>` / `@@<file>` | Run a script (absolute / relative path) |
| `SPOOL <file> [CREATE\|REPLACE\|APPEND]` / `SPOOL OFF` | Write output to a file (quote paths containing spaces; `.lst` added when the file name has no extension) |
| `SET TERMOUT OFF` | Suppress screen output produced by scripts (`file`, `@`, `job`) — the SPOOL file still receives everything |
| `WHENEVER SQLERROR EXIT [code]` | Exit on error with a code |
| `PROMPT <text>` | Print a message |
| `PAUSE [text]` | Wait for user input |
| `ACCEPT <var> PROMPT '<text>'` | Read user input into a variable |
| `VARIABLE <name> <type>` | Declare a bind variable |
| `PRINT <var>` | Print a bind variable |
| `DESC[RIBE] <object>` | Describe a table, view, or procedure |
| `EXIT [code]` / `QUIT [code]` | Exit with a POSIX code |

SPOOL files are always written as plain-text table output without colour,
regardless of `--format` or how QuinSQL was launched (TTY, pipe, or
`quinsql job`) — the console format never leaks into the spool.

**Substitution variables**

Every input line — SQL, PL/SQL and SQL\*Plus commands alike (`SPOOL`, `@`,
`SET`, `COLUMN`, `DEFINE`, `PROMPT`, …) — has its `&var` references expanded
before it is interpreted, exactly as SQL\*Plus does.

```sql
-- Define explicitly, or capture from a query
DEFINE env = PROD
COLUMN ts NEW_VALUE run_ts NOPRINT
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') AS ts FROM dual;

-- A single dot ends the variable name and is consumed:
--   &run_ts..out  ->  20260922_151644.out
SPOOL /reports/status_&run_ts..out REPLACE
SELECT * FROM &env._ORDERS;

-- Script arguments are &1 … &n
@monthly_report.sql 2026 09

-- Undefined &var prompts:  Enter value for dept:
-- The value is used for this statement only; the next statement asks again.
SELECT * FROM emp WHERE deptno = &dept;

-- Undefined &&var prompts once, then behaves like DEFINE for the session.
SELECT * FROM emp WHERE deptno = &&dept;
```

| Setting | Effect |
|---|---|
| `SET DEFINE OFF` | No expansion at all — use when data contains `&` (e.g. `'AT&T'`) |
| `SET DEFINE <char>` | Use another substitution character, e.g. `SET DEFINE ~` |
| `SET VERIFY ON` (default) | Print `old n:` / `new n:` for each SQL line that was changed by substitution |
| `SET VERIFY OFF` | Suppress the old/new lines (common at the top of production scripts) |

In `quinsql file` / `quinsql exec` the prompt is written to stderr and the
answer is read from stdin, so values can be piped: `printf 'alice\n' | quinsql
file report.sql -p prod`. `ACCEPT … HIDE` reads from the terminal directly and
cannot be piped.

**Error handling:**

```sql
WHENEVER SQLERROR EXIT SQL.SQLCODE
CREATE TABLE test (id NUMBER);
-- If CREATE fails, the script exits with the Oracle error code
```
