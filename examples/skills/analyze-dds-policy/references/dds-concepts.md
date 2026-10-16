# Deep Data Security — how to read the dictionary

Source: *Oracle Deep Data Security Guide*, Oracle AI Database 26ai
(chapters "Data Grants", "Configure Data Roles", "Audit Oracle Deep Data
Security Operations", "Data Dictionary Views").

## Contents

1. Vocabulary
2. Status of a policy
3. Grantees and holders
4. DDL reconstruction — what is exact, what is not
5. Auditing and sessions
6. Privileges the scripts need

## 1. Vocabulary

- **Policy = data grant.** `CREATE DATA GRANT owner.name AS <privileges> ON
  <table|view|mview> [WHERE predicate] TO <end users | data roles>` — or the
  cross-table form `WHEN <parent privileges> GRANTED ON parent WHERE join`.
  Grants are additive: a user's access is the union of all grants that apply.
- **Privileges** are `SELECT`, `UPDATE`, `INSERT`, `DELETE`; the first three
  may be column-scoped (`(col, ...)` or `(ALL COLUMNS EXCEPT col, ...)`);
  `DELETE` is always row-level. Unauthorised cells read as `NULL`.
- **Data role** — a role that only Deep Sec grants can target. *Local* roles
  are granted with `GRANT DATA ROLE`; *external* roles (`MAPPED TO
  'AZURE_ROLE=...'`, `'IAM_GROUP_NAME=...'`, …) activate from the IAM token
  and cannot be granted locally. `ENABLED_BY_DEFAULT = FALSE` means an
  application must enable the role explicitly (privilege elevation).
- **End user** — a Deep Sec identity (`CREATE END USER`), not a database
  user. Local end users are in `DBA_END_USERS`; external (IAM) users are not
  in the dictionary at all and appear only in security contexts and audit.
- **MAC / `USE DATA GRANTS ONLY`** — when set on the object, end users reach
  it *only* through data grants, even if they hold `SELECT ANY TABLE`. It is
  an object property, surfaced on every grant row as `USE_DATA_GRANTS_ONLY`.
- **Cross-table grant** — derives access to a *child* object from privileges
  the user already has on a *parent* object; no grantees, no time window.
  `GRANTEE` is `NULL` and `CROSS_TABLE_DATA_GRANT = TRUE`.

## 2. Status of a policy

Data grants have no ENABLE/DISABLE switch. The scripts derive `STATUS`:

| STATUS | Meaning |
|---|---|
| `ACTIVE` | in force now |
| `PENDING` | `START_TIME` is in the future |
| `EXPIRED` | `END_TIME` has passed — the grant still exists but authorises nothing |
| `INVALID` | a column it names was dropped or renamed (`INVALID_COLUMN_NAME`); recreate or drop it |

A grant whose only grantee is an external data role with no token mapping in
use, or a local role nobody holds (`GRANTED_TO` empty), is `ACTIVE` but
reaches no one — worth saying.

## 3. Grantees and holders

- `DBA_DATA_GRANTS` has one row per *privilege × column × grantee*; for
  `ALL COLUMNS EXCEPT` it is one row per *granted* column × *excepted*
  column, with the excepted column in `GRANTED_WITH_ALL_COLUMNS_EXCEPT`.
  `scripts/grant_privileges.sql` collapses this back to the DDL form.
- Effective holders = direct end-user grantees ∪ end users holding a granted
  data role, transitively through role-to-role grants
  (`DBA_DATA_ROLE_GRANTS`, `ROLE_TYPE = 'DATA ROLE'`). Database roles granted
  to a data role (`ROLE_TYPE = 'DATABASE ROLE'`) carry ordinary privileges
  such as `CREATE SESSION`.
- `PUBLIC` is a valid built-in grantee (Oracle uses it for
  `SYS.END_USER_CONTEXT_DEFAULT_GRANT`).

## 4. DDL reconstruction — what is exact, what is not

`scripts/grant_ddl.sql` has been verified to round-trip: executing its output
reproduces the dictionary rows byte for byte for direct, column-scoped,
`ALL COLUMNS EXCEPT`, time-bound and cross-table grants. `DBMS_METADATA` has
no documented `DATA_GRANT` object type, so this is the only way to script a
grant.

Exact: privileges and column lists (ordered by `COLUMN_ID`), predicate,
grantees, `START TIME`/`END TIME` (emitted as `TO_TIMESTAMP_TZ` with an
explicit mask), parent privileges and object, `CREATE DATA ROLE` options,
database roles granted to the roles, `GRANT DATA ROLE` holders,
`SET USE DATA GRANTS ONLY`.

Not reproducible from the dictionary:
- `CREATE END USER` — passwords/MFA are not exposed; the script emits a
  `-- requires end user X` comment instead.
- Validity windows of `GRANT DATA ROLE` — `DBA_DATA_ROLE_GRANTS.START_TIME`
  is a session-NLS-formatted string, so it is emitted as a trailing comment
  to be re-added by hand.
- `CREATE END USER CONTEXT` definitions referenced by predicates
  (`ORA_END_USER_CONTEXT`), and functions/macros used in predicates.

Templates (`.j2`) were considered for the DDL but QuinSQL renders them from
the last result set only, one flat row list, while a grant needs several
differently shaped sets (privileges, parent privileges, roles, holders). The
SQL script assembles the text instead and returns one line per row, so a
4000-character predicate never hits the `VARCHAR2` limit.

## 5. Auditing and sessions

- Deep Sec is audited through Unified Auditing only. Nothing is audited unless
  a policy includes the actions: `CREATE|ALTER|DROP END USER`,
  `CREATE|DROP APPLICATION IDENTITY`, `CREATE|DROP DATA ROLE`,
  `GRANT|REVOKE DATA ROLE`, `CREATE|DROP DATA GRANT`,
  `CREATE|DROP END USER CONTEXT`, and `CREATE END USER SECURITY CONTEXT`
  (the last is excluded from `ACTIONS ALL` and must be named explicitly).
- End-user activity: `UNIFIED_AUDIT_TRAIL.END_USER_NAME` and
  `END_USER_SECURITY_CONTEXT_ID` are filled only for statements run inside an
  end-user security context; configuration statements by DBAs leave them
  `NULL`. `RETURN_CODE <> 0` from an end user usually means a missing grant,
  role or context attribute.
- Sessions: `DBA_END_USER_SECURITY_CONTEXTS` (`USER_TYPE` LOCAL/EXTERNAL,
  `SECURITY_CONTEXT_TYPE` DIRECT_LOGON/THROUGH_APPLICATION, last access,
  inactivity timeout) joined to `DBA_END_USER_SECURITY_CONTEXT_DATA_ROLES`
  gives the roles active in each context; `CONTEXT_ID` is the join key to the
  audit trail. From inside a session, `V$END_USER_DATA_ROLE` shows the roles
  of the current request.
- `scripts/enable_dds_audit_policy.sql` follows the guide's example policy
  and adds `SELECT/INSERT/UPDATE/DELETE ON <protected object>`; it needs the
  `AUDIT_ADMIN` role. Unified audit records can be numerous: mention
  retention (`DBMS_AUDIT_MGMT`) if the user enables object DML auditing on a
  busy table.

## 6. Privileges the scripts need

`SELECT` on the `DBA_*` Deep Sec views (any DBA, or `SELECT_CATALOG_ROLE`),
`AUDIT_VIEWER` for `UNIFIED_AUDIT_TRAIL` and the `AUDIT_UNIFIED_*` views,
`AUDIT_ADMIN` for step 6. `dds_check.sql` only needs `PUBLIC` access.
