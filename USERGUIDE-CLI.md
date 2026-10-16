# QuinSQL — CLI / Headless Mode

[← Back to User Guide](USERGUIDE.md)

---

## Table of Contents

- [Overview](#overview)
- [Global Flag: `-p / --profile`](#global-flag--p----profile)
- [Commands](#commands)
  - [connect](#connect)
  - [connect-save](#connect-save)
  - [connect-list](#connect-list)
  - [connect-delete](#connect-delete)
  - [exec](#exec)
  - [file](#file)
  - [job](#job)
  - [setup](#setup)
  - [admin-password](#admin-password)
  - [llm-key](#llm-key)
  - [skills](#skills)
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

### connect-list

[^ top](#table-of-contents)

Lists all saved connection profiles — no secrets shown, no administrator password
required.

```bash
quinsql connect-list
quinsql connect-list --name <profile>   # one profile as a vertical record
```

Columns: `Profile` ( `*` marks the default), `User`, `Priv` (`normal`/`sysdba`/`sysoper`),
`Auth` (`password`/`wallet`/`oci`), `Policy` (preset · `global`/`custom` source),
`Credential` — where a stored credential was found: `keychain`, `file`, `keychain+file`
(a leftover entry in the OS keychain alongside the file store), `—` (none), or `n/a`
for non-password auth methods — and `DSN` last.

In a terminal the `DSN` column is truncated with `…` so the table fits the screen
width (never narrower than 20 columns); output piped to a file or another command
is never truncated. Use `--name <profile>` for the full record — in a terminal the
DSN wraps onto continuation lines indented under the value column; piped output is
a single line:

```text
Profile:     adb-prod *
User:        ADMIN
Privilege:   normal
Auth:        wallet
Policy:      open · global
Credential:  n/a
Wallet:      /home/oracle/.quinsql/wallets/adb-prod   (only when a wallet is set)
DSN:         (description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1521)
             (host=adb.us-phoenix-1.oraclecloud.com))(connect_data=(service_name=...))
```

---

### connect-delete

[^ top](#table-of-contents)

Permanently removes a saved profile, including its stored password, local catalog snapshot,
and command history.

```bash
quinsql connect-delete <profile-name>
quinsql connect-delete --all      # delete every saved profile (asks for confirmation)
```

**Examples:**

```bash
quinsql connect-delete old-dev
quinsql connect-delete --all
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
| `--format <fmt>` | Output format (see [Output Formats](#output-formats)); default `table`, or `csv` when stdout is piped and no `--format` is given |
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
| `--format <fmt>` | Output format for `SELECT` results; default `table` — `file` always keeps `table` when piped (SQL\*Plus scripts redirected to a log must not change format); the piped-CSV default applies to `exec` only |
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

**Line continuation:** like SQL\*Plus, a line whose trimmed text ends with
`-` continues onto the next line — the hyphen becomes a single space. This
applies to SQL\*Plus commands (`SET FEEDBACK -` + `OFF`), to `REM` lines and
to SQL (even when the line ends with an inline `--` comment). Lines that
*start* with `--` never continue, so `-- --------` separators are safe.
Inside PL/SQL blocks the hyphen stays literal.

**Headless `/ask`:** `quinsql exec "/ask …"` and `/ask` lines inside `quinsql
file` scripts print the AI proposal but never park for confirmation. The
generated statement executes only when it is classified `READ` and
`[ai].auto_run_reads = true`; otherwise QuinSQL prints `statement not
executed — requires interactive confirmation`, audits the proposal, and
continues with exit code 0. See the [AI Guide](USERGUIDE-AI.md#headless-ask).

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

### llm-key

[^ top](#table-of-contents)

Manages the LLM API key used by `/ask`, ORA-error explain, and agent skills.
The key is stored in the configured credential store under `__llm__:<provider>`
— never in `config.toml`; the provider's standard environment variable
(e.g. `ANTHROPIC_API_KEY`) is used as a fallback.

```bash
quinsql llm-key set [--provider <p>]
quinsql llm-key delete [--provider <p>]
```

| Flag | Description |
|---|---|
| `--provider <p>` | any `[llm]` provider name (see USERGUIDE-AI.md → `[llm]`); defaults to `[llm].provider` |

---

### skills

[^ top](#table-of-contents)

Headless mirror of the `/skills` REPL command — lists, inspects, and validates
agent skills under `[ai.skills].dir`. Pure filesystem: works with no LLM
configured and no database connection.

```bash
quinsql skills list
quinsql skills show <name>
quinsql skills validate [<name>]
```

| Exit code | Meaning |
|---|---|
| `0` | Success |
| `1` | `validate` found an error-severity issue (CI gate) |
| `2` | `show` named an unknown skill |

---

### export

[^ top](#table-of-contents)

Creates a portable ZIP backup of QuinSQL configuration.

```bash
quinsql export <output.zip> [--include-catalog] [--include-audit] [--include-schedule] [--include-skills]
```

| Flag | Description |
|---|---|
| `--include-catalog` | Include the local schema catalog snapshot |
| `--include-audit` | Include the full audit journal |
| `--include-schedule` | Include scheduled jobs, run history, and each job's script (with its `@`/`@@` includes) |
| `--include-skills` | Include agent skills from `[ai.skills].dir` under `skills/<name>/` |

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
                          [--scripts-dir <dir>] [--wallet-dir <dir>] [--skills-dir <dir>]
```

| Flag | Description |
|---|---|
| `--overwrite` | Replace existing profiles and settings with those from the backup — stored credentials are deleted then re-written in both the OS keychain and `credentials.enc`; without it, credentials of skipped (existing) profiles are kept as-is |
| `--data-dir <dir>` | Restore to a specific data directory instead of the default |
| `--scripts-dir <dir>` | Where job scripts go (default `<data-dir>/schedule/scripts`, i.e. `~/.quinsql/schedule/scripts`; prompted when the archive has scripts and the flag is absent) |
| `--wallet-dir <dir>` | Where wallet directories go (default `<data-dir>/wallets`, i.e. `~/.quinsql/wallets`; prompted likewise). Each wallet lands in `<wallet-dir>/<name>` (`<name>-2`, `-3`… if it exists, unless `--overwrite`) |
| `--skills-dir <dir>` | Where agent skills go (default `[ai.skills].dir`, i.e. `~/.quinsql/skills`) |

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

JSON columns (Oracle 21c+/26ai `JSON` type) render as compact JSON text —
e.g. `{"a":1,"b":"x"}`, with object keys sorted and top-level JSON strings
keeping their quotes (`"ALICE"`). `COLUMN … FORMAT` applies to them as text
and `SET LONG` does not cap them (the thin driver decodes them natively; the
thick `oracle`-crate driver does not support JSON yet).

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
| `SET SERVEROUTPUT ON [SIZE n\|UNLIMITED] [FORMAT WRAPPED\|WORD_WRAPPED\|TRUNCATED]` | Enable `DBMS_OUTPUT` output; `FORMAT` wraps/truncates lines at `LINESIZE` |
| `SET DEFINE OFF\|ON\|<char>` | Enable/disable substitution variables |
| `SET TIMING ON\|OFF` | Show execution time per statement |
| `SET VERIFY ON\|OFF` | Show old/new values for substitution variables |
| `SET NULL '<text>'` | Text displayed for NULL values |
| `SET COLSEP '<char>'` | Column separator character |
| `SET AUTOCOMMIT OFF\|ON\|IMMEDIATE\|<n>` | Commit automatically: `ON`/`IMMEDIATE` after every DML/PLSQL statement (`Commit complete.` is printed), `<n>` after every *n* DML statements, `OFF` (default) never |
| `SET SQLFORMAT [csv\|delimited [d [l [r]]]\|json\|json-formatted\|markdown\|insert\|default\|ansiconsole\|text\|fixed]` | SQLcl output format — drives **both** console and SPOOL while in force (unlike `/format`/`--format`, which set the console only and leave the spool in Table). `csv` quotes every non-numeric cell; `delimited` takes optional separator/left/right enclosure characters (`l`/`r` honoured asymmetrically, both default to `"`); `insert` emits `REM INSERTING into <T>` / `SET DEFINE OFF;` / `Insert into …` statements per SQLcl (table = first FROM-clause table). Bare `SET SQLFORMAT` resets to the default. `loader`, `html`, `xml` report `SP2-0158` — not supported |
| `SET MARKUP CSV ON [DELIMITER c] [QUOTE ON\|OFF]` / `SET MARKUP CSV OFF` | SQL\*Plus equivalent of `SET SQLFORMAT csv` (quote-all by default; `QUOTE OFF` = minimal quoting). `OFF` restores whatever format was in force before `ON`. `SET MARKUP HTML …` is accepted and ignored |
| `SET LONG <n>` | Maximum characters displayed per CLOB/NCLOB/LONG/XMLTYPE value (1..2,000,000,000; the value is truncated before rendering, so every format sees the cap). Never set = uncapped; `SHOW LONG` then reports `long 2000000000` |
| `TIMI[NG] START [text]` / `TIMING SHOW` / `TIMING STOP` | Nested elapsed timers (LIFO). `SHOW`/bare `TIMING` peek; `STOP` pops and prints `timing for: <name>` + `Elapsed: HH:MM:SS.cc`; bare `TIMING` prints `N timing elements in use.`; `STOP` on an empty stack reports `SP2-0630`. `CLEAR TIMING` removes all timers |
| `SHOW SQLFORMAT` / `SHOW MARKUP` / `SHOW LONG` / `SHOW TIMING` | Report the corresponding session state |
| `SET SQLPROMPT` / `SET LONGCHUNKSIZE` | Accepted and ignored |
| `SET EXITCOMMIT ON\|OFF` | Whether ending the session commits (default `ON`) or rolls back uncommitted work |
| `DEFINE <var> = <value>` | Define a substitution variable |
| `@<file>` / `@@<file>` | Run a script (absolute / relative path) |
| `SPOOL <file> [CREATE\|REPLACE\|APPEND]` / `SPOOL OFF` | Write output to a file (quote paths containing spaces; `.lst` added when the file name has no extension) |
| `SET TERMOUT OFF` | Suppress screen output produced by scripts (`file`, `@`, `job`) — the SPOOL file still receives everything |
| `WHENEVER SQLERROR EXIT [code] [COMMIT\|ROLLBACK]` | Exit on error with a code; the optional keyword picks the transaction disposition (default: `EXITCOMMIT` → commit) |
| `WHENEVER OSERROR EXIT [code] [COMMIT\|ROLLBACK]` | Exit after a failed `HOST` command; without a code the process exits with the command's own exit status; the optional keyword picks the transaction disposition |
| `HOST <cmd>` / `! <cmd>` / `$ <cmd>` | Run an OS command through the shell (`sh -c`, `cmd /C` on Windows). On a TTY with no SPOOL active the command inherits the terminal (interactive programs like `vi` work); otherwise output is captured, printed and spooled. The exit status is kept for `WHENEVER OSERROR`. Bare `HOST` prints SP2-0734 — an interactive shell is not supported |
| `CLEAR SCREEN` / `CLEAR SCR` | Clear the terminal (ANSI erase; no output when piped or spooled). `CLEAR BREAKS` / `CLEAR COMPUTES` / `CLEAR COLUMNS` clear the corresponding report state; `CLEAR TIMING` empties the timer stack; `CLEAR BUFFER\|SQL` are silent no-ops |
| `COLUMN [<col> [<option> …]]` | SQL*Plus column formatting: `FORMAT A<n>` or a numeric mask (`999,990.00`, `$99,990.00`, `999MI`, `B999`, `RN`, `TM`, `EEEE`, …), `HEADING 'x'` (split lines on `|` — the SET HEADSEP char), `JUSTIFY LEFT\|CENTER\|RIGHT`, `NULL 'text'`, `WRAPPED`/`WORD_WRAPPED`/`TRUNCATED`, `FOLD_AFTER`/`FOLD_B[EFORE]`, `PRINT`/`NOPRINT`, `NEW_VALUE var`/`OLD_VALUE var` (feed titles/substitution), `LIKE <col>` (copy another column's format), `ALIAS <name>`, `ON`/`OFF`, `CLEAR`. Bare `COLUMN` lists every definition; `COLUMN <col>` lists one (`SP2-0046` when undefined). Bad options report `SP2-0158` |
| `BRE[AK] [ON {col\|ROW\|REPORT} [SKI[P] n\|PAGE] [DUP[LICATES]\|NODUP[LICATES]]] …` | Group/report breaks: `SKIP n` blank lines (or `SKIP PAGE`) between groups, `NODUP` (default) blanks repeated values. Each `BREAK` replaces the previous spec; multiple `ON` targets are outer→inner. Bare `BREAK` lists the spec |
| `COMP[UTE] [fn [LAB[EL] 'text'] … OF col … ON {col\|ROW\|REPORT} …]` | Aggregate rows at breaks — `AVG`, `COU[NT]`, `MIN[IMUM]`, `MAX[IMUM]`, `NUM[BER]`, `SUM`, `STD`, `VAR[IANCE]`; compute lines accumulate. The label prints in the break column (first column for `ON REPORT`), underlined by `*` (break column) and the underline char (computed columns). A compute whose `ON` target has no matching `BREAK` is inert |
| `TTI[TLE]` / `BTI[TLE]` / `REPH[EADER]` / `REPF[OOTER] [printspec]` | Report titles/footers. Print specs: `LE[FT]`, `CE[NTER]`, `R[IGHT]`, `COL n`, `TAB n`, `S[KIP] [n]`, `BOLD` (no-op), `FORMAT mask`, quoted text, `SQL.LNO\|PNO\|RELEASE\|SQLCODE\|USER`, and bare `NEW_VALUE`/`OLD_VALUE`/define variable names. `ON`/`OFF` toggles without losing the spec; bare command lists it; `REPHEADER PAGE` puts the header on its own page; bad options report `SP2-0158`. Single-argument form is the legacy centred title |
| `PASSW[ORD] [<user>]` | Change a user's password via hidden prompts (`Old password:` → `New password:` → `Retype new password:`). The old-password prompt is skipped when a privileged session names a different user. Passwords are never echoed, logged, audited, or written to history |
| `STARTUP [FORCE] [RESTRICT] [PFILE=<file>] [NOMOUNT\|MOUNT\|OPEN [READ ONLY\|READ WRITE]] [UPGRADE\|DOWNGRADE]` | Start the Oracle instance. Requires `AS SYSDBA`/`AS SYSOPER`; gated as `DESTRUCTIVE` (confirm/plan/deny per the profile's destructive policy). Thin and thick modes currently report `SP2-0640` — see *Known gaps* |
| `SHUTDOWN [NORMAL\|IMMEDIATE\|TRANSACTIONAL [LOCAL]\|ABORT]` | Shut the Oracle instance down. Same privilege/policy gating and `SP2-0640` caveat as `STARTUP`. Illegal options report `SP2-0717` (STARTUP: `SP2-0714`) |
| `PROMPT <text>` | Print a message |
| `PAUSE [text]` | Wait for user input |
| `ACCEPT <var> PROMPT '<text>'` | Read user input into a variable |
| `VARIABLE <name> <type> [= <value>]` | Declare a named bind variable. Types: `NUMBER`, `CHAR[(n [CHAR\|BYTE])]`, `NCHAR[(n)]`, `VARCHAR2[(n [CHAR\|BYTE])]`, `NVARCHAR2[(n)]`, `CLOB`, `NCLOB`, `BINARY_FLOAT`, `BINARY_DOUBLE`, `BINARY_INTEGER`, `BLOB`, `BFILE`, `REFCURSOR` (OUT cursor bind — `EXEC OPEN :rc FOR SELECT …` fills it, `PRINT rc` renders the rows as a grid once, like SQL*Plus). `:name` references in SQL/PLSQL are bound IN/OUT — `EXEC :x := 42` stores `42` in `x`; a later `SELECT :x` uses it as input. `VARIABLE` alone lists declarations (`variable X` / `datatype NUMBER`). Undeclared references fail with `SP2-0552` before reaching the database |
| `PRINT [<var>…]` | Print each bind variable as a one-row result grid (header, `─` underline, value line; NULL prints a blank value line). `COLUMN` formats, `SET NULL`, `NUMFORMAT` and `SQLFORMAT`/`MARKUP` apply as for SELECT; numbers right-align. One blank line after each variable block; no "rows selected" footer. `PRINT` alone prints all declared variables in declaration order. Undeclared names report `SP2-0552` |
| `DESC[RIBE] <object>` | Describe a table, view, or procedure |
| `CONN[ECT] <user>[/<password>][@<dsn>] [AS SYSDBA\|SYSOPER\|SYSASM\|SYSBACKUP\|SYSDG\|SYSKM]` | Switch the session to another user/database. Without `/<password>` you are prompted (input hidden). Without `@<dsn>` the current DSN is reused; in thin mode a bare `tnsnames` alias also falls back to the current DSN (thin cannot resolve aliases). On failure the existing session is kept. The new session stays active for the rest of the script/REPL session, as in SQL\*Plus; the previous session's uncommitted work is ended per `EXITCOMMIT` before the swap — committed by default (see *Transactions and EXIT*) |
| `DISC[ONNECT]` | Accepted and ignored in script context — the session ends when the script finishes |
| `SHOW USER` | Connected user (from the live session) |
| `SHOW REL[EASE]` | Database release number |
| `SHOW PARAMETER[S] [filter]` | V$PARAMETER entries matching `filter` |
| `SHOW SPPARAMETER[S] [filter]` | V$SPPARAMETER entries matching `filter` |
| `SHOW CON_NAME` / `SHOW CON_ID` | Current container name / id |
| `SHOW PDBS` | Pluggable databases (`V$PDBS`) |
| `SHOW SGA` | SGA components (`V$SGA`) |
| `SHOW EDITION` | Current edition |
| `SHOW ERRORS [type [schema.]name]` | Compilation errors |
| `SHOW ALL` / `SHOW <setting>` | Session settings (`LINESIZE`, `DEFINE`, `VERIFY`, …) |
| `EXIT [code\|:bind\|<var>] [COMMIT\|ROLLBACK]` / `QUIT …` | Exit with a POSIX code. `EXIT :x` uses the bind variable's value (non-numeric → 1); a bare `<var>` reads a `DEFINE` substitution variable. `COMMIT`/`ROLLBACK` override `EXITCOMMIT` for this exit |

**Display settings**

These `SET` options drive the renderer for script (`file`, `@`, `job`) and
SPOOL output:

| Setting | Behaviour |
|---|---|
| `SET PAGESIZE 0` | Suppresses column headings everywhere |
| `SET PAGESIZE <n>` | Repeats heading and separator every *n* data rows (script/SPOOL only; the interactive grid shows one heading) |
| `SET LINESIZE <n>` | Splits over-wide rows into SQL*Plus column bands that each fit within *n* characters (script/SPOOL only; must be set explicitly) |
| `SET NULL '<text>'` | Text shown for NULL values in Table, CSV and Markdown (JSON stays `null`) |
| `SET COLSEP '<sep>'` | Literal column separator in header, separator and data rows; the default `" "` keeps QuinSQL's 3-space gutter |
| `SET WRAP ON\|OFF` | ON continues over-wide cells on following lines within their column (other columns blank); OFF truncates. The interactive console always truncates. Cells with embedded newlines (CLOBs, `DBMS_METADATA` output) render one output line per segment — the first on the row line, continuations with the other columns blank; CSV keeps the newline inside the quoted field, JSON escapes it as `\n`, Markdown flattens to a space |
| `SET TRIMSPOOL ON\|OFF` | When explicitly set ON, strips trailing blanks from every SPOOL line |
| `SET NEWPAGE <n>` | Blank lines emitted at each page break (default 1) |
| `SET FEEDBACK <n>` | "N rows selected" footer only when the result has at least *n* rows; `ON` = 1, `OFF` hides footers and completion messages |
| `SET ECHO ON\|OFF` | Echo each script statement before its result as written, including the source terminator (`;` on the last line, `/` on its own line); typed input is never echoed and no `SQL> ` prompts or line numbers are added |
| `SET TIMING ON\|OFF` | Append `Elapsed: HH:MM:SS.cc` after SQL/PLSQL statements |
| `SET NUMFORMAT '<mask>'` | Default numeric mask for columns without a `COLUMN … FORMAT` (also right-justifies bare numeric `SQL.*` title variables at NUMWIDTH) |
| `SET NUMWIDTH <n>` | Default numeric display width; unformatted numbers wider than *n* overflow to `#`s (script/SPOOL only) |
| `SET HEADSEP '<c>'` / `SET HEADSEP OFF` | Character that splits `COLUMN … HEADING` text into multiple heading lines (default `\|`) |
| `SET UNDERLINE '<c>'` / `SET UNDERLINE ON\|OFF` | Character used for the heading separator band and compute underlines (default `─`); `OFF` removes the band (script/SPOOL only) |
| `SET RECSEP WRAPPED\|EACH\|OFF` | Print a record-separator line after wrapped rows / every row / never (script/SPOOL, only when set explicitly) |
| `SET RECSEPCHAR '<c>'` | Character for the record-separator line |

**Reports**

`COLUMN`, `BREAK`, `COMPUTE` and the four title commands combine into the
classic SQL\*Plus report. The canonical form — one page per department with
the department number in the title and a grand total at the end:

```sql
SET LINESIZE 60
SET PAGESIZE 20
COLUMN deptno NEW_VALUE dv NOPRINT
BREAK ON deptno SKIP PAGE
TTITLE LEFT 'Department ' dv
BTITLE CENTER '-- confidential --'
COMPUTE SUM OF sal ON REPORT
SELECT deptno, ename, sal FROM quinsql_emp ORDER BY deptno, ename;
```

```text
Department 10

ENAME     SAL
──────   ────
CLARK    2450
KING     5000
MILLER   1300

                     -- confidential --

Department 20
…
```

(the `dv` variable is re-valued per page; each page ends with `BTITLE` on the
last line).

What applies where:

- **Interactive console / TUI:** `COLUMN` masks, headings (`|` split),
  `JUSTIFY`, per-column `NULL`, `BREAK`/`COMPUTE` rows, and titles —
  `REPHEADER`/`TTITLE` once above the grid, `BTITLE`/`REPFOOTER` once below.
- **Script (`file`, `@`, `job`) and SPOOL only:** `PAGESIZE` line accounting
  with repeated headings, `REPHEADER PAGE`, `SKIP PAGE` page breaks, title
  `SQL.LNO`/`SQL.PNO` per page, per-column overflow (`WRAPPED`…), folds,
  `SET UNDERLINE`, `SET RECSEP`, `SET NUMWIDTH`.
- **Titles and breaks/computes render in Table format only** — CSV, JSON and
  Markdown exports never include them.
- `SET PAGESIZE 0` suppresses titles and headings entirely.

Known deviations from SQL\*Plus:

- `BOLD` in a title is accepted but renders plain (no terminal-bold tracking).
- `L`/`C`/`U` currency mask elements render the session currency as `$`
  (no NLS lookup yet).
- `SQL.SQLCODE` in titles is always `0` (last-error tracking not wired).
- The heading band uses `─` (or `SET UNDERLINE c`); the compute underline
  uses `*` under the break column.
- `PAGESIZE` counts physical lines SQL*Plus-style (titles + blank + headings
  + data) in scripts/SPOOL; the interactive console never paginates.

**Unsupported SQL\*Plus commands**

`APPEND`, `ARCHIVE`, `ATTRIBUTE`, `CHANGE`, `COPY`, `DEL`, `EDIT`, `GET`,
`HELP`, `HISTORY`, `INPUT`, `LIST`, `RECOVER`,
`RUN`, `SAVE`, `STORE` and `XQUERY`
are recognised but not implemented. They are reported as
`SP2-0734: unknown command "<name>" - not supported by QuinSQL, rest of line ignored`
— a client-side message, not a SQL error, so `WHENEVER SQLERROR` does not
trigger — and are never sent to the database. Oracle SQL that begins with
`SET` (`SET TRANSACTION`, `SET ROLE`, `SET CONSTRAINT[S]`, and the Oracle
26ai access-control statement `SET USE DATA GRANTS ONLY ON …
[ENABLED|DISABLED]`) is passed through to the database unchanged —
`;`-terminated and possibly multi-line, like any SQL statement. A `SET`
option that is neither implemented nor on the accepted-and-ignored list
reports `SP2-0158: unknown SET option "<name>"`.

**CONNECT**

`CONNECT user/password[@dsn] [AS SYSDBA|SYSOPER|…]` opens a new session and
prints `Connected.` User and password may each be double-quoted —
`CONNECT alice/"P@ss/w0rd"@orclpdb` strips the quotes and treats `/` and
`@` inside them literally. `CONNECT user[@dsn]` (no `/`) prompts for the
password on stderr. A failed `CONNECT` leaves the session disconnected —
statements then fail with `SP2-0640: Not connected` until a `CONNECT`
succeeds.

**Transactions and EXIT**

QuinSQL follows the SQL\*Plus/SQLcl rules for what happens to open work:

| Event | Behaviour | Controlled by |
|---|---|---|
| DML / PL/SQL statement | No commit — work stays in the open transaction | `SET AUTOCOMMIT OFF` (default) |
| `SET AUTOCOMMIT ON` / `IMMEDIATE` | `COMMIT` after every successful DML/PLSQL statement; prints `Commit complete.` | |
| `SET AUTOCOMMIT <n>` | `COMMIT` after every *n* successful DML statements | |
| `COMMIT` / `ROLLBACK` | Explicit | |
| DDL (`CREATE`, `ALTER`, `DROP`, …) | Implicit commit (server side — cannot be prevented) | |
| `EXIT` / `QUIT`, `WHENEVER … EXIT`, end of script | **COMMIT** | `SET EXITCOMMIT ON` (default) |
| `EXIT COMMIT` / `EXIT ROLLBACK` | As written — overrides `EXITCOMMIT` | |
| `SET EXITCOMMIT OFF` + `EXIT` | `ROLLBACK` | |
| `WHENEVER SQLERROR\|OSERROR EXIT … COMMIT\|ROLLBACK` | The keyword is applied when the action fires | |
| `CONNECT` to another session | The old session's transaction is ended per `EXITCOMMIT` **before** the swap; on success `Connected.` is printed. On failure the session is left **disconnected** (SQL\*Plus semantics): subsequent statements report `SP2-0640: Not connected` until a later `CONNECT` succeeds | |
| Session killed / network drop | `ROLLBACK` (server side) | |

Headless mode (`exec`, `file`, `job`) never prompts: a failed session-end
`COMMIT` is printed and makes the exit code non-zero. The interactive TUI
handles uncommitted changes separately — see `USERGUIDE-TUI.md`
(`[transaction] exit = "ask"`, the default).

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

**Known gaps**

| Command | Status |
|---|---|
| `STARTUP` / `SHUTDOWN` | Fully parsed and policy-gated (`DESTRUCTIVE`), but both the thin driver lacks the startup/shutdown and the thick driver (not wired yet) report `SP2-0640: <CMD> is not available in thin mode`. |
