---
name: analyze-dds-policy
description: Analyze Oracle Deep Data Security (Deep Sec, DDS) policies on Oracle AI Database 26ai - list the data grants, show one policy in full (privileges and column scope, predicate, data roles and their holders, end users, cross-table parent privileges, time window, MAC flag, status), rebuild its CREATE DATA GRANT / CREATE DATA ROLE DDL from the dictionary, and show audit coverage, configuration changes, end-user activity and live end-user sessions linked to it. Use when the user asks about Deep Data Security, DDS, data grants, data roles, end users, row/column-level data authorization, or who can see which rows of a table.
allowed-tools: catalog sql template
license: MIT
metadata:
  author: quinsql
  version: "1.0"
---

# Analyze Deep Data Security policies

In Deep Sec the *policy* is the **data grant** (`CREATE DATA GRANT`): a named
object that gives end users or data roles row/column privileges on one table or
view. Everything here is read-only except step 6, which is optional and gated.
Column and privilege rows in `DBA_DATA_GRANTS` are stored expanded; the scripts
collapse them, so never query that view yourself — use the scripts.

## Inputs

- `owner`, `grant_name` — the policy. Users may say `HR.EMPLOYEES_OWN_RECORD`
  or just `EMPLOYEES_OWN_RECORD`; if the owner is missing, find it in step 2
  and ask only if the name is ambiguous. Plain identifiers, upper-cased.
- `days` — audit look-back window; default `30` for configuration changes
  and `7` for end-user activity unless the user names a period.

## Workflow

1. **Always start** with `scripts/dds_check.sql` (no binds; it is not shown
   to the user). One row: `VERSION_FULL, DDS_SUPPORTED, NOTE`. If
   `DDS_SUPPORTED = 'YES'`, say nothing about it and continue. If `'NO'`,
   stop: tell the user the version and that Deep Data Security needs Oracle
   AI Database 26ai (23.26.2 or later) — do not run any other script.
2. **List.** When no policy is named (or the user asks what exists / what
   protects a table / what a role can do), run `scripts/list_grants.sql` with
   binds `{"filter": "%"}` — or a LIKE pattern such as `"HR.EMPLOYEES"`,
   `"%EMPLOYEES%"` or a role name; it matches grant name, protected object
   and grantees. Then render `templates/grant_list.j2` with vars
   `{"filter": "<the filter>"}` (QuinSQL displays it) and answer in two or
   three sentences: how many policies, which objects, anything `INVALID`,
   `PENDING` or `EXPIRED`. Offer the detail of one policy. Stop here unless a
   policy was named.
3. **Detail** of one policy — run, in this order, with binds
   `{"owner": "<OWNER>", "grant_name": "<GRANT_NAME>"}`; each displays its grid:
   1. `scripts/grant_detail.sql` — header: protected object, `GRANT_KIND`
      (`DIRECT`/`CROSS-TABLE`), `MAC_ONLY`, `STATUS`, time window, predicate.
      No row → the policy does not exist; re-run step 2 with the name as
      filter and stop.
   2. `scripts/grant_privileges.sql` — one row per privilege with `SCOPE`
      (`ALL COLUMNS`, `COLUMN LIST`, `ALL COLUMNS EXCEPT`) and the columns.
   3. `scripts/grant_grantees.sql` — grantees; for each data role its kind
      (local / external mapping), the database roles it carries and who holds
      it (`GRANTED_TO`, with any validity window).
   4. `scripts/grant_parent_privileges.sql` — **only if** `GRANT_KIND` is
      `CROSS-TABLE`: the privileges required on the parent object.
   Then summarise in a few sentences: who can do what on which rows/columns,
   whether the policy is in force (`STATUS`, `MAC_ONLY`), and anything odd
   (invalid columns, disabled role, expired window, external roles with no
   local holders). See `references/dds-concepts.md` for how to read the
   fields.
4. **DDL.** If the user asks to recreate, export, script or see the DDL of a
   policy (or after step 3 if they asked for "everything"), run
   `scripts/grant_ddl.sql` with the same binds. QuinSQL shows its rows to
   the user as one highlighted SQL script: the data roles the grant names (`CREATE DATA
   ROLE IF NOT EXISTS`, their `GRANT <database role>`, `GRANT DATA ROLE`
   holders), the `CREATE OR REPLACE DATA GRANT`, and `SET USE DATA GRANTS
   ONLY` when MAC is on. Point out the two things it cannot reproduce: end
   user accounts (`-- requires end user ...`, passwords are not in the
   dictionary) and validity windows on role grants (emitted as a trailing
   comment because the dictionary exposes them as text). Do not retype the
   DDL in your answer.
5. **Audit / sessions.** Offer this after step 3; run it when the user asks
   about auditing, logging, who used, who accessed, sessions or failed
   access. With `object_owner`/`object_name` = the `PROTECTED_OBJECT` from
   step 3:
   1. `scripts/audit_coverage.sql` binds `{"object_owner": ..., "object_name": ...}` —
      which unified audit policies cover Deep Sec configuration actions, DML
      on the object, or everything, and whether they are enabled. No rows or
      `not enabled` everywhere means the next two scripts will be empty: say
      so, and offer step 6 (or, outside `/ask`, the DBA can run
      `@examples/skills/demo-data/dds-audit-policy.sql ENABLE OWNER.OBJECT`).
   2. `scripts/audit_config_changes.sql` binds `{"owner", "grant_name", "days"}` —
      who created/dropped the grant, granted/revoked its roles, altered its
      end users.
   3. `scripts/audit_end_user_activity.sql` binds `{"owner", "grant_name", "days"}` —
      statements run on the protected object inside an end-user security
      context, with `HOLDER` (resolved local holder or `unresolved` external
      user) and `RETURN_CODE`; call out non-zero return codes (usually a
      missing grant or role).
   4. `scripts/end_user_sessions.sql` binds `{"owner", "grant_name"}` — live
      end-user security contexts (`USER_TYPE` LOCAL/EXTERNAL,
      `SECURITY_CONTEXT_TYPE` DIRECT_LOGON/THROUGH_APPLICATION) that hold the
      policy and the data roles enabled in them; `CONTEXT_ID` matches the
      audit trail.
   Summarise in two or three sentences; do not repeat the grids.
6. **Enable auditing — only when the user explicitly asks to enable, create
   or turn on auditing** for Deep Sec or this policy: run
   `scripts/enable_dds_audit_policy.sql` with binds
   `{"policy_name": "<NAME>", "object_owner": ..., "object_name": ...}`
   (`policy_name` default `DEEP_SEC_POLICY_AUDIT`). QuinSQL asks `[Y/n]`
   before it runs; if declined, stop and say nothing was changed. After
   success re-run step 5.1.

## Rules

- Only `scripts/enable_dds_audit_policy.sql` may change the database, and
  only on explicit request; never write your own `CREATE DATA GRANT`, `GRANT
  DATA ROLE`, `AUDIT` or `SET USE DATA GRANTS ONLY` statements.
- Do not invent grants, roles, users or columns: report only what the scripts
  returned.
- `SYS.END_USER_CONTEXT_DEFAULT_GRANT` (grantee `PUBLIC`) is Oracle-supplied;
  mention it as such and never propose dropping or changing it.
- Predicates may reveal business rules; show them, never paraphrase them as
  facts about the data itself.
