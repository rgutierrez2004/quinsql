# Optimizer statistics — guidelines

## What the statuses mean

- **NEVER** — `LAST_ANALYZED` is null. The optimizer uses dynamic sampling or
  defaults; plans on anything beyond a few thousand rows are unreliable.
  Always worth fixing.
- **STALE** — `ALL_TAB_STATISTICS.STALE_STATS = 'YES'`: more than
  `STALE_PERCENT` (default 10%) of the rows changed since the last gather.
  Worth fixing for tables that are queried, harmless to leave on scratch tables.
- **OK** — statistics exist and are within the staleness threshold.

## Before recommending a refresh

- The automatic statistics job (`auto optimizer stats collection`) normally
  runs in the maintenance window. If most tables are stale, the job may be
  disabled or the window too short — mention that instead of gathering
  everything by hand.
- Gathering on a very large table takes time and I/O. For tables above
  ~10M rows suggest running it in the maintenance window rather than now.
- `cascade => TRUE` also refreshes index statistics; this is the default
  recommendation.
- Never gather statistics on Oracle-maintained schemas (`SYS`, `SYSTEM`,
  `XDB`, `MDSYS`, …): use `DBMS_STATS.GATHER_DICTIONARY_STATS` for those,
  and only when a DBA asks for it explicitly.
- `ANALYZE TABLE ... COMPUTE STATISTICS` is deprecated for optimizer
  statistics; do not propose it.
