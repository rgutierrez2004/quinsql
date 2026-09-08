# QuinSQL User Guide

**QuinSQL** is a modern, single-binary workbench for Oracle Databases — a fast, feature-rich
alternative for SQL\*Plus and SQLcl with no JVM, no Oracle Client required.

---

## Table of Contents

- [Overview](#overview)
- [Platform Support](#platform-support)
- [Installation and First-Time Setup](#installation-and-first-time-setup)
  - [Download](#download)
  - [First-time setup wizard](#first-time-setup-wizard)
  - [Thick mode (optional)](#thick-mode-optional)
- [Connection Profiles](#connection-profiles)
  - [Saving a profile](#saving-a-profile)
  - [Connecting](#connecting)
  - [Deleting a profile](#deleting-a-profile)
- [Modes of Operation](#modes-of-operation)
- [Administration](#administration)
  - [Admin password](#admin-password)
  - [Export and import](#export-and-import)
- [Further Reading](#further-reading)

---

## Overview

[^ top](#table-of-contents)

QuinSQL is a command-line Oracle database tool designed for DBAs, developers, and data engineers.
It runs as a single native binary with no additional runtimes.

**Key capabilities:**

- **Interactive REPL** — full-screen terminal UI with multi-line SQL editing, syntax highlighting,
  and schema-aware autocompletion for tables, columns, views, synonyms, and packages.
- **Headless mode** — run a single SQL statement or a full script from the command line;
  pipe output to `jq`, `grep`, or any other tool.
- **SQL\*Plus compatibility** — existing SQL\*Plus scripts run unmodified. `SET`, `DEFINE`,
  `COLUMN`, `SPOOL`, `WHENEVER SQLERROR`, `@`, `@@`, substitution variables — all supported.
- **Data import and export** — `LOAD` and `UNLOAD` commands (SQLcl-compatible) with support
  for CSV, Excel, JSON, SQL\*Loader format, Apache Parquet, and Apache Arrow IPC.
- **Schema catalog and graph** — browse objects, relationships, and privilege chains without
  writing queries.
- **Safety policies** — classify every statement by blast-radius and require confirmation
  or approval before destructive operations execute.
- **Audit journal** — every statement is recorded with outcome, actor, and timing.

---

## Platform Support

[^ top](#table-of-contents)

| Platform | Architecture | Notes |
|---|---|---|
| Linux | x86-64 | Oracle Linux 9, RHEL 9, Ubuntu 22.04+|
| macOS 12+ | arm64 (Apple Silicon) | M2+ Chips |
| Windows 10 / 11 | x86-64 | Native binary; no WSL required |

**No runtime dependencies in thin mode** (the default):

- No JVM
- No Oracle Client or Instant Client
- No ODBC drivers

QuinSQL connects directly to Oracle Database using its own built-in network driver (thin mode).
An optional **thick mode** is available for environments that require Oracle Client features such as
wallets, advanced network encryption, or TNS name resolution; see [Thick mode (optional)](#thick-mode-optional).

**Supported Oracle Database versions:** 12c, 18c, 19c, 21c, 23ai, and 26ai — on-premises or in Oracle Cloud.

---

## Installation and First-Time Setup

[^ top](#table-of-contents)

### Download

Download the binary for your platform from the QuinSQL release page.
Place it somewhere on your `PATH`, for example `/usr/local/bin/quinsql` on Linux/macOS
or `C:\tools\quinsql.exe` on Windows.

Verify the installation:

```bash
quinsql --version
```

### First-time setup wizard

Run the setup wizard once after first installation to initialise the QuinSQL data directory
(history, catalog cache, audit journal, configuration):

```bash
quinsql setup
```

The wizard will:

1. Create the QuinSQL data directory (`~/.quinsql` on Linux/macOS, `%APPDATA%\quinsql` on Windows).
2. Generate a default configuration file.

### Thick mode (optional)

Thick mode requires Oracle Instant Client to be installed on the machine.
To install Instant Client through the setup wizard:

```bash
quinsql setup --accept-license
```

To switch an existing installation to thick mode, edit the configuration file and set
`connection_mode = "thick"`.

Thick mode is only needed for:

- TNS name resolution (`tnsnames.ora`)
- Oracle Wallet authentication (mTLS / ADB)
- Advanced Oracle Network compression

For most use cases, thin mode is sufficient and recommended.

---

## Connection Profiles

[^ top](#table-of-contents)

QuinSQL stores named connection profiles so you never type a password in the command line
or shell history. Passwords are stored in the OS keychain
(macOS Keychain, Windows Credential Manager, Linux Secret Service with encrypted-file fallback).

### Saving a profile

```bash
quinsql connect-save --name <profile-name> \
                     --dsn "<host>:<port>/<service>" \
                     --user <username>
```

You will be prompted for the password interactively. The connection is tested before the profile is saved.

**Common options:**

| Flag | Description |
|---|---|
| `--name <name>` | Unique profile name used with `-p` everywhere |
| `--dsn <dsn>` | Oracle EZConnect string: `host:port/service_name` |
| `--user <user>` | Oracle username |
| `--sysdba` | Connect as SYSDBA |
| `--sysoper` | Connect as SYSOPER |
| `--wallet-path <path>` | Path to Oracle Wallet directory (for ADB / mTLS) |
| `--policy <preset>` | Safety policy preset (see below); default `global` |

**Policy presets:**

| Preset | Behaviour |
|---|---|
| `global` | Use the application-wide safety policy (default) |
| `open` | All statements execute without confirmation |
| `confirm-writes` | DML and DDL require confirmation; destructive require approval |
| `plan-approval` | Everything above WRITE requires an explicit approval step |

**Examples:**

```bash
# Standard Oracle Database connection
quinsql connect-save --name prod-hr \
                     --dsn "db.example.com:1521/HRPDB" \
                     --user HR

# Connect as SYSDBA
quinsql connect-save --name sys-admin \
                     --dsn "db.example.com:1521/HRPDB" \
                     --user SYS \
                     --sysdba \
                     --policy plan-approval

# Oracle Autonomous Database with Wallet
quinsql connect-save --name adb-prod \
                     --dsn "adb.example.com:1522/myatp_high" \
                     --user ADMIN \
                     --wallet-path ~/wallets/adb-prod
```

### Connecting

```bash
# Connect using a saved profile
quinsql connect -p prod-hr

# Launch with a profile picker (if no profile is specified)
quinsql
```

When launched without a profile, QuinSQL displays an interactive profile picker where you can
select a saved profile with the arrow keys and press Enter.

### Deleting a profile

```bash
quinsql connect-delete prod-hr
```

This removes the profile, its stored password, catalog snapshot, and local history.

---

## Modes of Operation

[^ top](#table-of-contents)

QuinSQL has two modes. Both use the same session and execution pipeline:

| Mode | Description | Details |
|---|---|---|
| **CLI / headless** | Run a SQL statement or script from the command line; exit with a POSIX code | [CLI Guide](USERGUIDE-CLI.md) |
| **TUI / interactive** | Full-screen terminal UI; interactive REPL with completion and slash-commands | [TUI Guide](USERGUIDE-TUI.md) |

Data import and export (LOAD / UNLOAD) works in both modes:

| Reference | Description |
|---|---|
| [LOAD / UNLOAD Guide](USERGUIDE-LOAD-UNLOAD.md) | Import from CSV / Excel; export to CSV, JSON, Parquet, Arrow |

---

## Administration

[^ top](#table-of-contents)

### Admin password

QuinSQL has an optional application-level admin password that gates privileged operations
such as bulk profile deletion, audit log export, and configuration import.

```bash
# Set or change the admin password
quinsql admin-password set

# Reset the admin password (requires the current password)
quinsql admin-password reset
```

### Export and import

Export your QuinSQL configuration — profiles, history, and optionally the catalog cache and
audit journal — to a portable ZIP file:

```bash
# Minimal export (profiles + config)
quinsql export quinsql-backup.zip

# Include the schema catalog snapshot
quinsql export quinsql-backup.zip --include-catalog

# Include the full audit journal
quinsql export quinsql-backup.zip --include-audit
```

Restore from an export file on another machine or after reinstallation:

```bash
# Restore (will not overwrite existing profiles by default)
quinsql import quinsql-backup.zip

# Overwrite existing profiles
quinsql import quinsql-backup.zip --overwrite

# Restore to a specific data directory
quinsql import quinsql-backup.zip --data-dir /opt/quinsql-data
```

---

## Further Reading

[^ top](#table-of-contents)

| Guide | Contents |
|---|---|
| [CLI Guide](USERGUIDE-CLI.md) | Headless mode, `exec`, `file`, output formats, piping |
| [TUI Guide](USERGUIDE-TUI.md) | Interactive REPL, slash-commands, scroll mode, SQL*Plus compat |
| [LOAD / UNLOAD Guide](USERGUIDE-LOAD-UNLOAD.md) | Data import/export, Parquet, Arrow, all format options |
