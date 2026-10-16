---
name: table-stats-health
description: Review optimizer statistics health for the tables of one schema (never analyzed, stale, row counts, last analyzed) and optionally refresh stale statistics with DBMS_STATS — use when the user asks about stale stats, table statistics, ANALYZE, or why the optimizer picks poor plans in a schema.
allowed-tools: catalog sql template
license: MIT
metadata:
  author: quinsql
  version: "1.0"
---

# Table statistics health

Report which tables in a schema have missing or stale optimizer statistics,
and — only when asked — refresh them one table at a time.

## Inputs

- `schema` — the schema to review. Use the schema the user named; if none was
  named, use the current session schema. Plain identifier only (e.g. `HR`),
  never a quoted or dotted name. Ask before proceeding if it is ambiguous.

## Workflow

1. Run `scripts/stats_overview.sql` with binds `{"schema": "<SCHEMA>"}`.
   One row per table: `TABLE_NAME, NUM_ROWS, BLOCKS, LAST_ANALYZED, STALE_STATS, STATUS`
   where `STATUS` is `NEVER` (no statistics), `STALE` or `OK`.
2. Render `templates/stats_report.j2` with vars `{"schema": "<SCHEMA>"}` — it
   formats the rows from step 1 and is displayed to the user by QuinSQL.
3. Answer with two or three sentences only: how many tables are `NEVER`, how
   many `STALE`, and whether action is recommended (see
   `references/stats-guidelines.md` for the thresholds and caveats). Do not
   include a table in your answer — the rendered report is already on screen.
4. **Only if the user asked to refresh, fix or gather statistics:** for each
   table with `STATUS` `NEVER` or `STALE`, run `scripts/gather_table_stats.sql`
   with binds `{"schema": "<SCHEMA>", "table": "<TABLE_NAME>"}`.
   - Each run asks the user for confirmation. If the user declines a table,
     skip it and continue with the next one — never retry a declined table.
   - After the last table, run `scripts/stats_overview.sql` once more with
     `display: true` so the user sees the new state (that script is not
     displayed by default because step 2 renders it as a report), and report
     what changed in one or two sentences (no table).
5. If the user did not ask for a refresh, end after step 3 and offer it.

## Rules

- Never gather statistics on `SYS`, `SYSTEM` or other Oracle-maintained schemas.
- Never run `ANALYZE TABLE`; `DBMS_STATS` is the only supported method.
- Do not invent tables: everything you report must come from step 1.
