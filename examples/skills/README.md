# Example skills

Ready-to-use Agent Skills for QuinSQL. Each directory is one skill in the
format described in [USERGUIDE-AI.md](../../USERGUIDE-AI.md#agent-skills).

| Skill | Exercises | Needs |
|---|---|---|
| `table-stats-health` | read SQL with binds → rows returned to the model → `.j2` template → reference file → gated PL/SQL write (`DBMS_STATS`) with confirm/suspend/resume | `SELECT` on `ALL_TABLES`/`ALL_TAB_STATISTICS` (any user); `ANALYZE ANY` or ownership of the schema for the refresh step |
| `table-auto-annotate` | 3 read scripts incl. a dynamic sample → model inference → JSON_TABLE preview grid shown to the user (`display: true`) → single gated PL/SQL write (annotations + `COMMENT ON`, JSON bind) → verification query shown as a grid | Oracle 23ai+ for annotations (falls back to comments); `ALTER`/`COMMENT` privilege on the object |
| `analyze-dds-policy` | version/feature probe → list grid + `.j2` report → multi-script detail (header, privileges, grantees, cross-table parents) → DDL reconstructed from the dictionary one line per row → audit coverage / config changes / end-user activity / live security contexts → one optional gated DDL (unified audit policy) | Oracle AI Database 26ai (23.26.2+) with Deep Data Security; `SELECT` on the `DBA_*` Deep Sec views, `AUDIT_VIEWER` for the audit steps, `AUDIT_ADMIN` for the optional audit-policy step |

## Install

```bash
mkdir -p ~/.quinsql/skills
cp -r examples/skills/table-stats-health ~/.quinsql/skills/
cp -r examples/skills/table-auto-annotate ~/.quinsql/skills/
cp -r examples/skills/analyze-dds-policy ~/.quinsql/skills/
quinsql skills validate            # expect: 0 errors
```

Skills are read at session start; in a running session use `/skills reload`.

## Try it

```
/skills
/skills show table-stats-health
/ask are there stale statistics in HR?                  # steps 1–3: SQL → template → summary
/ask @table-stats-health refresh stale stats in HR      # + step 4: one [Y/n] per table, run continues after y or n
/audit
```

For `table-auto-annotate`, load the demo schema first (it drops/recreates
`XV_ET01`, `XR03`, `XT02`, `XE01`):

```
-- once, as HR: @examples/skills/demo-data/table-auto-annotate.sql
/ask what is table HR.XE01 about?                       # steps 1-5: profile + sample → proposal (no write)
/ask @table-auto-annotate annotate HR.XE01              # + apply: one [Y/n], then current annotations shown
/ask @table-auto-annotate show annotations for HR.XV_ET01
/audit
```

For `analyze-dds-policy` (requires a Deep Data Security policy to exist, e.g.
`HR_DEMO.EMPLOYEE_DIR_ACCESS`). Unified Auditing records nothing about Deep Sec
until a policy naming its actions is enabled, so for the audit step first run,
as a user with `AUDIT_ADMIN` (`DISABLE` drops it again afterwards):

```
-- as SYSTEM: @examples/skills/demo-data/dds-audit-policy.sql ENABLE HR_DEMO.EMPLOYEES
/ask which deep data security policies exist?                       # steps 1-2: probe → list → report
/ask @analyze-dds-policy show policy HR_DEMO.EMPLOYEE_DIR_ACCESS     # step 3: detail grids
/ask @analyze-dds-policy generate the DDL for EMPLOYEE_DIR_ACCESS    # step 4: DDL one line per row
/ask @analyze-dds-policy who used EMPLOYEE_DIR_ACCESS this week?     # step 5: audit + sessions
```

Every SQL step appears in `/audit` as `ai-ask` with rationale `skill:table-stats-health/scripts/...`,
`skill:table-auto-annotate/scripts/...` or `skill:analyze-dds-policy/scripts/...`.
The refresh step is a PL/SQL block, so it is classified `WRITE` and always asks for
confirmation — answer `n` to one table to see the skill skip it and carry on.
