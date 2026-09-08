# QuinSQL

**A next-generation, AI-powered alternative to SQL*Plus and SQLcl.**

> A modern, single-binary command-line workbench for Oracle Databases with built-in AI, safety rails, and a schema-aware terminal experience.<br>
> This is an early **preview**, things might be a little rough around the edges, so please let us know if you spot any bugs<br>
> **Freeware. No JVM. No Oracle Client required.**

## Overview

QuinSQL is a fast, interactive SQL client and agentic workbench for Oracle Databases.
It runs as a single binary with no runtime dependencies, starts in under 100 ms,
and is fully backward-compatible with existing SQL\*Plus scripts.

Whether you are running a quick query, automating a deployment, or asking an AI agent
to explain a slow execution plan — QuinSQL is the same tool, the same session,
the same workflow.

## Screenshots

### Interactive REPL with Schema-Aware Completion

*[ animated GIF — coming soon ]*

### Schema Dependency Graph — `/graph show`

*[ animated GIF — coming soon ]*

## Features

### Terminal Experience

| Feature | Status |
|---|---|
| Rich full-screen TUI — multi-line SQL editor, syntax highlighting | Available |
| Schema-aware autocompletion — tables, columns, views, synonyms, packages | Available |
| SQL\*Plus-compatible prompt, multi-line input with `;` / `/` terminators | Available |
| Persistent history with search | Available |
| Result grid output — table, CSV, JSON, Markdown | Available |
| Column folding and display width control | Available |
| Named connection profiles with OS keychain / encrypted-file secret storage | Available |
| Headless one-shot mode: `quinsql exec "SQL"` / `quinsql file script.sql` | Available |
| POSIX exit codes, pipe-friendly output (`\| jq`) | Available |
| Built-in SQL editor (`/edit`) — Vi navigation, syntax highlighting, search (`/`), `Ctrl+S` save, `Ctrl+Q` quit | Available |
| Client-side result re-sort and filter | Coming soon |

### Data Import / Export — LOAD / UNLOAD

QuinSQL implements the SQLcl `LOAD` and `UNLOAD` commands as client-side extensions
with additional formats beyond the SQLcl baseline.

| Feature | Status |
|---|---|
| `LOAD TABLE t file.csv` — streaming batch INSERT from CSV | Available |
| `LOAD TABLE t file.csv.gz` — transparent gzip decompression | Available |
| `LOAD TABLE t file.xlsx` — load from Excel (`.xlsx`, `.xls`, `.xlsb`, `.ods`) | Available |
| `LOAD … NEW` — infer DDL from file schema, create table, then load | Available |
| `LOAD … SHOW` / `CREATE` — print or execute inferred DDL without loading | Available |
| `SET LOAD BATCH_ROWS n BATCHES_PER_COMMIT n` — tunable commit strategy | Available |
| `SET LOAD ERRORS n` — configurable error tolerance before abort | Available |
| `UNLOAD TABLE t DIR /path` — export to CSV, JSON, INSERT statements, SQL\*Loader | Available |
| `UNLOAD TABLE t DIR /path` — export to Apache Parquet | Available |
| `UNLOAD TABLE t DIR /path` — export to Apache Arrow IPC | Available |
| Oracle-aware Parquet/Arrow schema — `NUMBER(p,s)` → `Decimal128`, `DATE` → `Timestamp[us]`, `CLOB` → `LargeUtf8` | Available |
| Streaming row-group writes — memory use is O(batch size), not O(table size) | Available |
| `UNLOAD … CS oci://bucket/...` — cloud object storage | Planned |

### SQL\*Plus Compatibility

| Feature | Status |
|---|---|
| `SET`, `COLUMN`, `DEFINE`, `SPOOL`, `WHENEVER SQLERROR` | Available |
| Substitution variables (`&var`, `&&var`) | Available |
| `@`, `@@`, `START` — script execution with relative paths | Available |
| `DESC`, `SHOW`, `PROMPT`, `PAUSE`, `ACCEPT`, `VARIABLE`, `PRINT` | Available |
| `EXIT` / `QUIT` with configurable return codes | Available |
| Runs existing SQL\*Plus scripts unmodified | Available |

### Schema Catalog

| Feature | Status |
|---|---|
| Local schema snapshot — objects, columns, types, dependencies, synonyms | Available |
| Security catalog — users, roles, system and object privileges, grant chains | Available |
| `/catalog privileges --user U --effective` — full role-chain expansion | Available |
| `/catalog users`, `/catalog roles`, `/catalog tables` | Available |
| Lazy tiered loading — T0 (schemas) and T1 (objects) load at connect, T2–T4 on demand | Available |
| Background incremental catalog refresh | Available |
| Schema dependency graph — `/graph deps`, `/graph impact`, `/graph cycles` | Available |
| Security privilege graph visualization | Available |

### Safety and Governance

| Feature | Status |
|---|---|
| Statement classification — READ / WRITE / DDL / DESTRUCTIVE | Available |
| Per-profile safety policies — `allow`, `confirm`, `plan` | Available |
| Undo-first execution — flashback / export-before-drop for destructive operations | Coming soon |
| `/audit` — query execution history (actor, blast-radius, outcome, AI rationale) | Partial — command available; full pipeline coverage and JSONL export coming soon |
| Blast-radius color coding in the REPL status bar | Available |

### AI Capabilities

| Feature | Status |
|---|---|
| `/ask` — natural-language to SQL, schema-grounded, shows query before executing | Coming soon |
| ORA-error explain and auto-fix — context-aware, proposes corrected statement | Coming soon |
| `/agent` — plan → diff → approve → execute for multi-step schema changes | Coming soon |
| `/tune` — execution-plan and AWR-aware performance copilot | Coming soon |
| Works with any LLM: Anthropic, OpenAI, Gemini, Groq, OCI GenAI, local Ollama | Coming soon |
| Fully offline when no model is configured | Available |

### Administration

| Feature | Status |
|---|---|
| Administrator credential — QuinSQL-level password stored in OS keychain | Available |
| Export / Import — ZIP-based portable transfer of profiles, history, config | Available |
| `quinsql admin-password set / reset` | Available |

### Connectivity

| Feature | Status |
|---|---|
| MCP server — expose QuinSQL tools to Claude, Copilot, and other agents | Coming soon |
| MCP client — agent can reach Jira, Slack, object storage mid-task | Coming soon |
| Skill system — Markdown-defined runbooks invocable as slash-commands | Coming soon |

## Feature Comparison

SQL\*Plus and SQLcl are both solid tools with long track records, and QuinSQL
respects everything they built. The world of database tooling has simply moved on.

| Capability | SQL\*Plus | SQLcl | QuinSQL |
|---|---|---|---|
| Runs existing SQL\*Plus scripts | Yes | Yes | Yes |
| Startup / footprint | ~1 s, native binary | ~2 s, requires JVM | < 100 ms, single binary |
| Persistent history | No | Yes | Yes |
| SQL syntax highlighting | No | Yes | Yes |
| Schema-aware autocompletion | No | Yes | Yes, richer (columns, packages, synonyms, fuzzy) |
| Multi-format output (CSV / JSON / Markdown / Parquet / Arrow) | Manual workarounds | CSV / JSON / Parquet | Yes — all formats + Arrow IPC |
| LOAD from CSV / Excel | No | Yes (CSV only) | Yes — CSV, gzip CSV, Excel, ODS |
| UNLOAD to CSV / JSON / Parquet / Arrow | No | CSV / JSON / Parquet | Yes — CSV, JSON, INSERT, SQL\*Loader, Parquet, Arrow IPC |
| DDL inference from file (`NEW` / `SHOW` / `CREATE`) | No | Partial | Yes — full type inference with size scanning |
| Full-screen interactive TUI | No | No | Yes |
| Built-in SQL editor (`Ctrl+S` save, `Ctrl+Q` quit, Vi navigation) | No | No | Yes |
| Schema catalog and dependency graph | No | No | Yes |
| Security privilege analysis | No | No | Yes |
| Safety policies and blast-radius gating | No | No | Yes |
| Undo-first execution | No | No | Coming soon |
| Audit journal with AI rationale | No | No | Yes / coming soon |
| Natural-language querying (any LLM) | No | Only via external agent or cloud AI | Coming soon |
| Agentic plan → diff → approve workflow | No | No | Coming soon |
| ORA-error explain and auto-fix | No | No | Coming soon |
| Performance copilot (plan + AWR-aware) | No | No | Coming soon |
| MCP server and client | No | Server only (26.x) | Coming soon (both) |
| License / cost | Free | Free | Free |
| Runtime dependency | Oracle Client (required) | JVM (thin JDBC by default; Oracle Client optional) | None — thin wire protocol; Oracle Client optional |

## Supported Oracle Database Features

QuinSQL connects to Oracle Databases and supports the following database capabilities:

- No Oracle Client libraries required
- Connects to Oracle Database 12, 18, 19, 21, and 26 — on-premises or in the Cloud
- SQL and PL/SQL execution with significant optimizations including compressed fetch, pre-fetching, client and server result set caching, and statement caching with auto-tuning
- Full use of Oracle Network Service infrastructure, including encrypted network traffic and security features
- Extensive Oracle data type support, including VECTOR, JSON, and large object support (CLOB and BLOB)
- Array operations for efficient INSERT, UPDATE, and MERGE execution
- Connection pooling
- Database Resident Connection Pooling (DRCP)
- Privileged connections
- End-to-end monitoring and tracing
- Support for Oracle AI Database 26ai Deep Data Security
- Support for fetching and inserting Arrow arrays

## Installation

### Prerequisites

- Windows 10 / 11 (x86-64), macOS 12+ (arm64), or Oracle/Red Hat Linux 9, Ubuntu 22.04+ (x86-64)
- No Oracle Client libraries required — QuinSQL uses a native driver with built-in Oracle connectivity

### 1 — First-time setup

Run the interactive setup wizard to configure your connection and create the QuinSQL data directory:

```
quinsql setup
```

### 2 — Save a connection profile

Save a named connection so you never type a password in a script or shell history again:

```
quinsql connect-save --name hr-dev --dsn "myhost.example.com:port/FREEPDB1" --user HR
```

You will be prompted for the password once. It is stored in the OS keychain
(macOS Keychain, Windows Credential Manager, Linux Secret Service / encrypted file fallback).

### 3 — Connect

```
quinsql connect -p hr-dev
```

Or connect via profile picker:

```
quinsql
```

### 4 — Run a script (headless mode)

```
quinsql file deploy.sql -p hr-dev
quinsql exec "SELECT COUNT(*) FROM employees" -p hr-dev
```

### 5 — LOAD and UNLOAD data

```bash
# Load a CSV into an existing table
quinsql file <(printf 'LOAD TABLE hr.employees employees.csv') -p hr-dev

# Infer DDL from Excel and create + load in one step
quinsql file <(printf 'LOAD TABLE sh.customers customers.xlsx NEW') -p hr-dev

# Export a table to Parquet
quinsql file <(printf 'SET LOADFORMAT PARQUET
UNLOAD TABLE sh.sales DIR /data/export') -p hr-dev
```

## Documentation

| Guide | Contents |
|---|---|
| [User Guide](USERGUIDE.md) | Overview, installation, platform support, connection profiles |
| [CLI Guide](USERGUIDE-CLI.md) | Headless mode, all CLI commands, output formats, scripting |
| [TUI Guide](USERGUIDE-TUI.md) | Interactive REPL, slash-commands, autocompletion, scroll mode |
| [LOAD / UNLOAD Guide](USERGUIDE-LOAD-UNLOAD.md) | Data import/export, Parquet, Arrow, all format options |

## License

QuinSQL is freeware. See [LICENSE.txt](LICENSE.txt) for full details.

*QuinSQL is under active development. Features marked "coming soon" are planned and tracked in the project roadmap.*
