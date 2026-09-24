# QuinSQL — TUI / Interactive Mode

[← Back to User Guide](USERGUIDE.md)

---

## Table of Contents

- [Overview](#overview)
- [Launching the TUI](#launching-the-tui)
- [Screen Layout](#screen-layout)
- [Profile Picker](#profile-picker)
- [The REPL Prompt](#the-repl-prompt)
  - [Entering SQL](#entering-sql)
  - [Submitting a statement](#submitting-a-statement)
  - [Editing shortcuts](#editing-shortcuts)
  - [History navigation](#history-navigation)
  - [Autocompletion](#autocompletion)
- [The Scrollback Area](#the-scrollback-area)
  - [Scroll mode](#scroll-mode)
- [Output Formats](#output-formats)
- [SQL\*Plus Commands in the TUI](#sqlplus-commands-in-the-tui)
  - [Substitution variables and prompts](#substitution-variables-and-prompts)
- [Slash Commands](#slash-commands)
  - [/help](#help)
  - [/connect](#connect)
  - [/profile](#profile)
  - [/format](#format)
  - [/clear](#clear)
  - [/history](#history)
  - [/edit](#edit)
  - [/catalog](#catalog)
  - [/graph](#graph)
  - [/audit](#audit)
  - [/schedule](#schedule)
  - [/quit](#quit)

---

## Overview

[^ top](#table-of-contents)

The TUI (Terminal User Interface) is the interactive mode of QuinSQL. It provides a full-screen
terminal experience with a multi-line SQL editor, live schema-aware completion, result display,
and a persistent scrollback area that keeps the full session history visible.

---

## Launching the TUI

[^ top](#table-of-contents)

```bash
# Pick a profile interactively
quinsql

# Connect directly to a saved profile
quinsql connect -p dev-hr
quinsql -p dev-hr          # shorthand
```

---

## Screen Layout

[^ top](#table-of-contents)

```
┌──────────────────────────────────────────────────────────────────────┐
│  Status bar — profile, connection state, blast-radius indicator      │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Scrollback area — all previous output for this session              │
│  (query results, messages, errors, SQL*Plus output)                  │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│  Hint / key-binding bar                                              │
├──────────────────────────────────────────────────────────────────────┤
│  HR@dev-hr ▸ _   (REPL prompt + input area)                          │
└──────────────────────────────────────────────────────────────────────┘
```

**Status bar** — shows the current user, profile name, connection string, and a
color-coded blast-radius indicator for the last classified statement:

| Color | Classification |
|---|---|
| Green | READ (SELECT) |
| Yellow | WRITE (INSERT / UPDATE / DELETE / MERGE) |
| Blue | DDL (CREATE / ALTER / DROP / ...) |
| Red | DESTRUCTIVE or UNKNOWN |

**Scrollback area** — all output since connecting accumulates here. Scroll up to review earlier
results without losing your current input.

**Input area** — the REPL prompt at the bottom where you type SQL and slash-commands.

---

## Profile Picker

[^ top](#table-of-contents)

When QuinSQL starts without a profile argument, it shows the interactive profile picker:

```
┌─ Select a profile ─────────────────────────────────────────┐
│                                                            │
│   ▶  dev-hr         HR@localhost:1521/XEPDB1               │
│      prod-hr        HR@db.prod.example.com:1521/HRPDB      │
│      sys-dba        SYS@db.example.com:1521/CDB1 [SYSDBA]  │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

| Key | Action |
|---|---|
| `↑` / `↓` | Move selection |
| `Enter` | Connect to selected profile |
| `Esc` | Exit |

---

## The REPL Prompt

[^ top](#table-of-contents)

### Entering SQL

[^ top](#table-of-contents)

Type SQL directly at the prompt. Multi-line SQL is supported: press `Enter` to continue on
the next line without submitting.

```sql
HR@dev-hr ▸ SELECT employee_id,
              last_name,
              salary
            FROM employees
            WHERE department_id = 90;
```

### Submitting a statement

[^ top](#table-of-contents)

| Method | Use case |
|---|---|
| `;` at the end of the last line + `Enter` | SQL statements |
| `/` on its own line + `Enter` | SQL statements or PL/SQL blocks |
| `Enter` on a completed PL/SQL block ending with `/` | PL/SQL procedures, functions, packages |

**Examples:**

```sql
-- Submit with semicolon
SELECT SYSDATE FROM dual;

-- Submit PL/SQL block with slash terminator
BEGIN
  DBMS_OUTPUT.PUT_LINE('Hello, QuinSQL');
END;
/
```

### Editing shortcuts

[^ top](#table-of-contents)

| Key | Action |
|---|---|
| `Ctrl+C` | Clear the current input buffer |
| `Ctrl+D` | Exit QuinSQL |
| `Ctrl+U` | Delete from cursor to start of line |
| `Ctrl+K` | Delete from cursor to end of line |
| `Ctrl+L` | Clear the scrollback area |
| `Home` | Move cursor to start of current line |
| `End` | Move cursor to end of current line |
| `Ctrl+H` | Move cursor to start of current line |
| `Ctrl+E` | Move cursor to end of current line |
| `Left` / `Right` | Move cursor one character |
| `Backspace` / `Delete` | Delete character |
| `Shift+Tab` | Enter scroll mode (see below) |

### History navigation

[^ top](#table-of-contents)

Press `↑` or `↓` when the cursor is at position 0 (start of the input area) to cycle through
previously executed statements. Moving the cursor right even one character puts you in edit mode,
where `↑` / `↓` instead move within the current multi-line statement.

Use `/history` for full search and management of the history — see [/history](#history).

### Autocompletion

[^ top](#table-of-contents)

Autocompletion is **type-sensitive** — the popup opens automatically as you type and narrows
in real time to match what you have entered so far. You do not need to press `Tab` to open it.

**How it works:**

1. Start typing at the prompt. As soon as QuinSQL recognises a prefix that could match a schema,
   table, column, keyword, or command, a popup appears above the input line listing all candidates
   that start with the characters you have typed.

   ```
   HR@dev-hr ▸ SELECT * FROM HE
                              ┌─────────────────────────┐
                              │ HEALTH                  │
                              │ HEALTH_ARCHIVE          │
                              │ HELPDESK                │
                              └─────────────────────────┘
   ```

2. Use `↑` / `↓` to move through the popup, then press `Tab` to accept the highlighted
   candidate. The text is inserted at the cursor.

3. After completing a **schema name**, QuinSQL automatically appends a `.` separator and the
   popup refreshes to show the objects available inside that schema:

   ```
   HR@dev-hr ▸ SELECT * FROM HEALTH.
                                     ┌──────────────────────────┐
                                     │ APPOINTMENTS             │
                                     │ DOCTORS                  │
                                     │ PATIENTS                 │
                                     │ PROCEDURES               │
                                     └──────────────────────────┘
   ```

4. Select a table and press `Tab` again. The full `SCHEMA.TABLE` name is inserted at the prompt
   and the popup closes.

The same drill-down behaviour applies anywhere object names are expected — `FROM`, `JOIN`,
`INSERT INTO`, `UPDATE`, `DESCRIBE`, and so on.

**What is completed:**

| Context | Candidates shown |
|---|---|
| After `FROM`, `JOIN`, `UPDATE`, etc. | Schemas, then tables/views/synonyms within a schema |
| After `SELECT`, `WHERE`, `ORDER BY` | Column names scoped to tables already in the query |
| Table alias prefix (`a.`) | Columns of the aliased table — e.g. `FROM hr.employees a` then `a.` shows `EMPLOYEE_ID`, `LAST_NAME`, … |
| Package calls | Package names, then procedures/functions within a package |
| SQL keywords | Oracle SQL reserved words and functions (`SELECT`, `FROM`, `WHERE`, `SET`, `CREATE`, `INSERT`, `UPDATE`, `DELETE`, …) |
| `/` at prompt start | QuinSQL slash-commands |
| `SET <option>` values | `ON` / `OFF` for `SERVEROUTPUT`, `FEEDBACK`, `HEADING`, `ECHO`, `TIMING`, `VERIFY`, etc. |
| SQL\*Plus commands | `DESCRIBE`, `SPOOL`, `DEFINE`, `UNDEFINE`, `PROMPT`, `PAUSE`, `ACCEPT`, `VARIABLE`, `PRINT`, `EXECUTE`, `WHENEVER`, `COLUMN`, `LOAD`, `UNLOAD` |

**Popup controls:**

| Key | Action |
|---|---|
| _(type characters)_ | Open / narrow the popup automatically |
| `↑` / `↓` | Move selection up / down |
| `Tab` | Accept selected candidate and insert at cursor |
| `Esc` | Dismiss the popup without inserting |

Autocompletion works from the local schema catalog. If the catalog has not been loaded yet,
run `/catalog load` first (see [/catalog](#catalog)).

---

## The Scrollback Area

[^ top](#table-of-contents)

Every query result, message, and error produced during the session is appended to the
scrollback area. The scrollback is preserved for the duration of the session, up to a
configurable cap — the oldest lines are dropped past the limit:

| `config.toml` key (`[ui]` section) | Default | Effect |
|---|---|---|
| `scrollback_lines` | `100000` | Maximum scrollback lines kept (`0` = unlimited) |
| `frame_interval_ms` | `16` | Minimum ms between screen redraws while a script or pasted batch is running (interactive input always redraws immediately) |

### Scroll mode

[^ top](#table-of-contents)

When a query returns many rows, the result is displayed in the scrollback area and the prompt
returns immediately. To scroll up and review earlier output:

Press `Shift+Tab` to enter **scroll mode**. The hint bar changes to show the available keys:

```
scroll mode  ↑↓ scroll · PgUp/PgDn page · Home/^H top · End/^E bottom · ←→ pan · ^C/Esc exit
```

| Key | Action |
|---|---|
| `↑` / `↓` | Scroll 3 lines up / down |
| `PageUp` / `PageDown` | Scroll 10 lines up / down |
| `Home` or `Ctrl+H` | Jump to the oldest output (top of scrollback) |
| `End` or `Ctrl+E` | Jump to the newest output (bottom / current prompt) |
| `←` / `→` | Pan horizontally (wide output) |
| `Ctrl+C` or `Esc` | Exit scroll mode and return to the prompt |

> **Tip:** Holding `↑` fills the key buffer with repeated scroll events. Press `Ctrl+C` to
> interrupt immediately — QuinSQL clears the buffer and exits scroll mode at once.

Press `Shift+Tab` again or `Ctrl+C` / `Esc` to return to the input prompt.

---

## Output Formats

[^ top](#table-of-contents)

Change the display format for `SELECT` results at any time using `/format`:

| Format | Command | Description |
|---|---|---|
| Table | `/format table` | Aligned, box-drawn grid (default) |
| CSV | `/format csv` | Comma-separated values |
| JSON | `/format json` | JSON array of objects |
| Markdown | `/format md` | Markdown table |

The format persists for the current session. Reset with `/format table`.

---

## SQL\*Plus Commands in the TUI

[^ top](#table-of-contents)

All SQL\*Plus-compatible commands work in the TUI the same way as in CLI script mode.
Type them at the prompt and press Enter:

```sql
SET FEEDBACK OFF
SET LINESIZE 200
SET PAGESIZE 50
SET SERVEROUTPUT ON

DESCRIBE employees

SPOOL /tmp/output.log
SELECT * FROM employees WHERE rownum <= 10;
SPOOL OFF
```

`SPOOL <file>` accepts an optional `CREATE` / `REPLACE` (default) / `APPEND`
mode and quoted paths (`SPOOL "C:\temp\my file.out" REPLACE`); `.lst` is
appended when the file name has no extension.  In scripts (`@file`,
`quinsql file`, scheduled jobs) `SET TERMOUT OFF` suppresses screen output
while the spool file still receives everything.

### Substitution variables and prompts

`&var` / `&&var` references are expanded on every line before it runs — in SQL, in
`SPOOL`/`@`/`SET`/`COLUMN` arguments, in typed statements and in scripts alike. Script
arguments arrive as `&1 … &n` (`@report.sql 2026 09`), and a single dot ends a variable
name (`&ts..out` → `20260922_151644.out`).

When a statement references a variable that is not defined, the TUI pauses and asks for it
in the scrollback; the next Enter is the answer, not a new statement:

```
system@prod ▸ SELECT * FROM emp WHERE deptno = &dept;
  Enter value for dept:
  10
old   1: SELECT * FROM emp WHERE deptno = &dept
new   1: SELECT * FROM emp WHERE deptno = 10
  …result grid…
```

- `&var` — the value is used for this statement only; the next statement asks again.
- `&&var` — asked once, then kept for the session like `DEFINE`.
- `ACCEPT`, `PAUSE` and `CONNECT user` typed at the prompt pause the same way.
- Inside an `@script` the script resumes at the same statement once you answer.
- `SET VERIFY OFF` hides the `old`/`new` lines; `SET DEFINE OFF` disables expansion
  entirely (for data containing `&`); `SET DEFINE ~` switches the character.

See [SQL\*Plus Script Compatibility](USERGUIDE-CLI.md#sqlplus-script-compatibility) in the
CLI guide for the full list of supported commands.

---

## Slash Commands

[^ top](#table-of-contents)

Slash commands start with `/` and are specific to QuinSQL. They do not go through the Oracle
database — they control the QuinSQL session, catalog, audit, and display.

Type `/` at any time to see the available commands.

---

### /connect

[^ top](#table-of-contents)

Switches to a different connection profile without restarting QuinSQL.

```
/connect <profile-name>
/conn <profile-name>
/connect              (shows the profile picker)
```

**Examples:**

```
/connect prod-hr
/conn dev-hr
/connect              -- opens interactive profile picker
```

---

### /profile

[^ top](#table-of-contents)

Lists saved profiles or views and changes the safety policy for a specific profile.

```
/profile list
/profile policy <name>
/profile policy <name> <preset>
/profile policy <name> <field>=<value>
```

**Policy presets:**

| Preset | Description |
|---|---|
| `global` | Use the application-wide default policy |
| `open` | Allow all statements without confirmation |
| `confirm-writes` | Confirm DML/DDL; approve destructive |
| `plan-approval` | Require approval for everything above READ |

**Individual policy fields** (`<field>=<value>`):

| Field | Controls |
|---|---|
| `read` | SELECT statements |
| `write` | INSERT / UPDATE / DELETE / MERGE |
| `ddl` | CREATE / ALTER / DROP / TRUNCATE |
| `destructive` | DROP TABLE, TRUNCATE with data loss risk |
| `session` | ALTER SESSION, SET ROLE |
| `unknown` | Unclassified statements (defaults to most restrictive) |

**Values for each field:** `allow` · `confirm` · `plan` · `deny`

**Examples:**

```
/profile list
/profile policy dev-hr
/profile policy dev-hr open
/profile policy prod-hr confirm-writes
/profile policy prod-hr destructive=plan
/profile policy dev-hr write=allow ddl=confirm
```

---

### /format

[^ top](#table-of-contents)

Changes the output format for `SELECT` results in the current session.

```
/format <fmt>
/f <fmt>
```

| Value | Description |
|---|---|
| `table` | Aligned grid (default) |
| `csv` | Comma-separated values |
| `json` | JSON array of objects |
| `md` | Markdown table |

**Examples:**

```
/format json
/f csv
/format table
```

---

### /clear

[^ top](#table-of-contents)

Clears the scrollback area and redraws the QuinSQL banner.

```
/clear
```

---

### /history

[^ top](#table-of-contents)

Shows, searches, and manages the command history for the current profile.

```
/history
/history <search-term>
/history filter <search-term>
/history delete <id>
/history delete <range>
/history delete <list>
/history clear
```

| Subcommand | Description |
|---|---|
| _(none)_ | Show all history entries with IDs |
| `<text>` | Show entries matching `<text>` |
| `filter <text>` | Same as above |
| `delete <id>` | Remove a single entry by ID |
| `delete <range>` | Remove a range of entries, e.g. `44-48` |
| `delete <list>` | Remove specific entries, e.g. `30,41,48` or `1-3,10,20-22` |
| `clear` | Remove all history for this profile |

**Examples:**

```
/history
/history employees
/history filter CREATE TABLE
/history delete 42
/history delete 44-48
/history delete 30,41,48
/history delete 1-3,10,20-22
/history clear
```

---

### /edit

[^ top](#table-of-contents)

Opens a file in the built-in SQL editor or an external editor.

```
/edit <file>
```

The built-in editor (when `editor = "builtin"` in configuration) opens a Vi-style editor
inside the QuinSQL terminal:

| Key | Action |
|---|---|
| `i` / `a` | Enter insert mode |
| `Esc` | Return to normal mode |
| `hjkl` | Move cursor (normal mode) |
| `w` / `b` | Word forward / backward |
| `gg` / `G` | Jump to top / bottom |
| `dd` | Delete line |
| `u` / `Ctrl+R` | Undo / redo |
| `v` | Visual select |
| `/` | Search forward; `n` / `N` next / previous |
| `Ctrl+S` | Save |
| `Ctrl+Q` | Quit (prompts if unsaved changes) |
| `Ctrl+E` | Open in system `$EDITOR` |

If `editor` is set to an external editor (`vim`, `nano`, `code`, etc.), that editor is launched
in the terminal and control returns to QuinSQL when the editor exits.

**Examples:**

```
/edit /tmp/report.sql
/edit ~/scripts/cleanup.sql
```

---

### /catalog

[^ top](#table-of-contents)

Manages the local schema catalog — a snapshot of the database's objects and privilege graph
stored locally for fast autocompletion, graph analysis, and browsing without round-trips.

```
/catalog status
/catalog load [--schema <schema>]
/catalog load security
/catalog schemas
/catalog tables [--schema <schema>]
/catalog users [--with-access-to <schema>] [--open] [--expired] [--locked]
/catalog roles
/catalog privileges --user <user> [--effective]
/catalog privileges --role <role>
/catalog delete
```

| Subcommand | Description |
|---|---|
| `status` | Show catalog freshness, loaded schemas, last refresh time |
| `load` | Load / refresh all objects for all schemas |
| `load --schema S` | Load / refresh a specific schema |
| `load security` | Load the privilege and role graph |
| `schemas` | List all known schemas |
| `tables` | List tables for all or a specific schema |
| `users` | List database users with optional filters |
| `roles` | List all roles |
| `privileges --user U` | Show privileges granted to a user |
| `privileges --user U --effective` | Show the full privilege set after role expansion |
| `privileges --role R` | Show privileges granted to a role |
| `delete` | Remove the local catalog snapshot |

**Examples:**

```
/catalog status
/catalog load
/catalog load --schema HR
/catalog load security
/catalog schemas
/catalog tables --schema SH
/catalog users --locked
/catalog users --with-access-to HR
/catalog privileges --user SCOTT
/catalog privileges --user SCOTT --effective
/catalog privileges --role DBA
```

---

### /graph

[^ top](#table-of-contents)

Analyzes and visualizes the schema dependency graph and security privilege graph.
The catalog must be loaded before most graph commands work.

```
/graph deps <object> [--depth <n>] [--direction up|down|both]
/graph impact <object> [--depth <n>]
/graph path <from> <to>
/graph metrics [--schema <schema>] [--top <n>] [--orphans]
/graph cycles [--schema <schema>]
/graph coupling [--top <n>]
/graph show [--schema <schema>] [--layout hier|fd]
/graph show security
/graph export [--dot | --json] [--output <file>]
/graph refresh [--scope <schema1,schema2>]
```

| Subcommand | Description |
|---|---|
| `deps <obj>` | Show objects that depend on `<obj>` (default `--direction up`; use `down` for what `<obj>` references) |
| `impact <obj>` | Show objects that depend on `<obj>` (what breaks if it changes) |
| `path <from> <to>` | Find the dependency path between two objects |
| `metrics` | Object centrality, fan-in/fan-out, complexity metrics |
| `cycles` | Detect circular dependencies |
| `coupling` | Most-coupled object pairs |
| `show` | Render an interactive dependency graph in the terminal |
| `show security` | Render the privilege and role graph |
| `export` | Export the graph to DOT or JSON format |
| `refresh` | Reload graph data from the database |

**Direction options for `deps`:**

| Value | Meaning |
|---|---|
| `down` | Objects that `<obj>` references (dependencies) |
| `up` | Objects that reference `<obj>` (dependents) |
| `both` | Both directions |

**Examples:**

```
/graph deps HR.EMPLOYEES
/graph deps HR.EMPLOYEES --depth 3 --direction both
/graph impact HR.DEPARTMENTS
/graph path HR.EMPLOYEES HR.LOCATIONS
/graph cycles --schema SH
/graph metrics --top 10
/graph show --schema HR
/graph show security
/graph export --dot --output /tmp/schema.dot
/graph export --json --output /tmp/schema.json
/graph refresh --scope HR,SH
```

---

### /audit

[^ top](#table-of-contents)

Queries the QuinSQL audit journal — a local log of every statement executed in this session
and previous sessions for the current profile.

By default `/audit` shows the **50 most recent** entries.

```
/audit
/audit --last <n>
/audit --actor <source>
/audit --radius <read|write|ddl|destructive>
/audit --since <timestamp>
/audit --search <text>
/audit --export <file>
```

| Option | Description |
|---|---|
| _(none)_ | Show the 50 most recent entries (default) |
| `--last <n>` | Show the last `n` entries |
| `--actor <source>` | Filter by initiator type (see SOURCE column below) |
| `--radius <level>` | Filter by blast-radius classification |
| `--since <timestamp>` | Show entries after a specific time (ISO 8601) |
| `--search <text>` | Full-text search in the SQL text |
| `--export <file>` | Export the full journal to a JSONL file |

**Output columns:**

| Column | Description |
|---|---|
| `#` | Row number within the current result set |
| `DATE/TIME` | Date and time the statement was executed (`YYYY-MM-DD HH:MM:SS`) |
| `SOURCE` | Who initiated the statement — see values below |
| `RADIUS` | Blast-radius classification: `read`, `write`, `ddl`, `destructive` |
| `STATEMENT` | First 52 characters of the SQL text |
| `OUTCOME` | `✔ success`, `✘ error`, or `⊘ cancelled/denied` |

**SOURCE values:**

| Value | Meaning |
|---|---|
| `user` | Typed interactively at the REPL prompt |
| `ai-ask` | Generated by `/ask` (AI natural language query) |
| `agent` | Generated by `/agent` (AI plan/approve workflow) |
| `script:name` | Executed from a SQL script file |
| `mcp:tool` | Called via an MCP tool |

> The Oracle database username is not stored in the SOURCE column — it is determined by the
> connection profile used for the session.

**Examples:**

```
/audit
/audit --last 20
/audit --radius destructive
/audit --actor user
/audit --actor script:sh_install.sql
/audit --since 2025-01-01
/audit --search "DROP TABLE"
/audit --export /tmp/audit-export.jsonl
/audit --last 100 --search "DELETE"
```

---

### /schedule

[^ top](#table-of-contents)

Manages scheduled jobs — `.sql` scripts run by the **operating system's own
scheduler** (systemd user timers on Linux, launchd on macOS, Task Scheduler
on Windows).  No QuinSQL daemon is needed: at each fire time the OS launches
`quinsql job <ID>`, which runs the script through the normal QuinSQL
pipeline — same policy gates, same audit journal, persistent run history in
`schedule.db`.

```
/schedule                      # same as /schedule new
/schedule new                  # open the job editor popup
/schedule list [all|enabled|disabled|<text>]
/schedule edit [<id>]          # picker when no id is given; Save enables the job
/schedule run <id>             # run the script now, interactively (a failed run's first error lands in /schedule history)
/schedule cancel <id>          # stop the run in progress
/schedule enable <id>          # register/enable the OS timer
/schedule disable <id>         # pause the OS timer
/schedule delete <id>          # remove the job (run history is kept)
/schedule history <id> [n]     # last n runs (default 10)
/schedule smtp-password        # store the [smtp] password in credentials.enc
```

Job ids look like `j-0143`.  `/schedule list` shows STATE (`enabled`,
`disabled`, `orphan`, `partial`, `running`, `pending`, `creds missing`),
the next local fire time, and the last run's result.  An `orphan` state means
the OS registration is gone (e.g. the binary moved) — `/schedule enable`
repairs it.

#### The job popup (`/schedule new` / `/schedule edit`)

Fields, in Tab order:

| Field | Editing |
|---|---|
| `SCRIPT` | Path to a `.sql` file (`~` expanded; relative paths are anchored to the current directory).  A `recent:` row offers the last-used scripts — ←→ to choose, Enter to pick |
| `RUNS AS` | Saved-profile selector: ←→ cycles profiles (defaults to the connected one).  Shows `user@profile · <policy>` |
| `START DATE` | First eligible day, `YYYY-MM-DD` |
| `TIMES` | `HH:MM` chips.  Type a time + Enter (or `+ add`) to add; ↑↓←→ select a chip, Enter/Backspace/Delete removes it.  At least one required |
| `RECURRENCE` | `once` / `daily` / `weekly` / `monthly` — ←→ or Space to switch.  `weekly` reveals a `mon`…`sun` day row (Space toggles); `monthly` reveals `days of month:` |
| `MAX RUNTIME` | `HH:MM`, `30m`, `2h`, or bare minutes.  Empty = unlimited.  A job that exceeds it ends `cancelled (timeout)` |
| `NOTIFICATION` | `[x] on error` / `[x] on completion` toggles (Space), a comma-separated e-mail list, and `[ send test email ]`.  Requires `[smtp]` in config.toml + `/schedule smtp-password` — otherwise the section shows `smtp not configured` |
| `NEXT RUNS` | Read-only preview of the next fire times in the local zone |

`Tab` / `Shift+Tab` move between fields and on to the footer buttons
`Create Job (Enter)` / `Save Job (Enter)` and `Cancel (Esc)`; `Esc` (or
`Ctrl+C`) cancels from anywhere.  The text cursor appears only in editable
fields; chips and buttons show focus by highlight.  Validation errors appear
in red on the offending field's label row and clear as soon as you edit it.
Saving a job — new or edited — always enables it and registers the OS
timer; use `/schedule disable` to pause.

#### Behaviour details

- **Times are local wall-clock** on the machine the job runs on — a `02:00`
  job fires at 02:00 local, DST-aware.
- **`once` jobs**: the popup refuses a `once` job whose date and times are
  all already in the past (`that time has already passed`).  After the last
  time of the day has run, the job is retired (OS registration removed, job
  disabled); its run history stays in `/schedule history`.
- **Unattended policy**: scheduled runs never prompt.  A statement that the
  profile's policy would gate on (confirm / plan-approval) is *parked*: the
  run stops, ends `pending_approval`, and the job auto-disables.
  `/schedule run <id>` runs the script interactively — prompts are answered
  at the keyboard — and a successful run re-enables the job.
- **Credentials**: saving a job copies the selected profile's DB password
  (and wallet password, if any) into `credentials.enc` — the runner never
  touches the OS keyring, which may be locked when the timer fires.
  Interactive sessions are unaffected.
- **`/schedule cancel`** is staged: first it asks the runner to cancel
  (reported as `cancelled (user)` within seconds); if the run is still alive
  ~10 s later it issues `ALTER SYSTEM DISCONNECT SESSION` through the normal
  gated pipeline, then ~10 s after that kills the runner process.  Worst case
  is about 25 s to report; on Windows the last stage is always a hard kill.
- **Linux/systemd**: enable lingering so user timers fire while logged out —
  `loginctl enable-linger <user>`.  Runner output goes to the systemd
  journal, not a TTY: `journalctl --user -u native-cron-quinsql-jN-t0`
  (native-cron writes one unit per job time; its `StandardOutput` handling
  redirects to the journal — check there when a runner misbehaves).
  Per-run logs are also kept in `~/.quinsql/schedule/logs/`.
- **Windows**: tasks are registered with the S4U logon type (`schtasks /np`)
  so they fire whether or not you are logged on.  Windows only lets
  administrators create such tasks, so **run QuinSQL from a terminal started
  as Administrator** whenever you create, edit or enable a job — otherwise
  Save fails with `OS registration failed: … ERROR: Access is denied.` (a
  new job is not created; an edited or imported job keeps its stored
  definition and can be enabled later from an elevated session).  Listing
  jobs, viewing history and `/schedule run` do not need elevation.
  **macOS**: jobs are `launchd` user agents.

---

### /quit

[^ top](#table-of-contents)

Exits the QuinSQL TUI cleanly.

```
/quit
/exit
/q
```

Keyboard equivalent: `Ctrl+D`.
