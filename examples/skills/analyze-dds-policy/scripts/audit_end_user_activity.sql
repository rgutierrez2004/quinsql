-- End-user activity on the object protected by one policy, from
-- UNIFIED_AUDIT_TRAIL (END_USER_NAME / END_USER_SECURITY_CONTEXT_ID are set
-- only for statements run inside an end-user security context).
-- HOLDER tells whether the end user is a resolved local holder of this grant
-- (directly or through data roles); external (IAM) users show as 'unresolved'.
-- Failed statements (RETURN_CODE <> 0) usually mean a missing grant or role.
-- Empty when no audit policy covers DML on the object (see audit_coverage.sql).
-- @display
-- Binds: &owner, &grant_name (plain identifiers), &days (look-back window, e.g. 7)
WITH gr AS (
  SELECT DISTINCT object_owner, object_name, grantee, grantee_type
  FROM   dba_data_grants
  WHERE  owner = UPPER('&owner') AND grant_name = UPPER('&grant_name')
),
holders (name, htype, via) AS (
  SELECT grantee, grantee_type, grantee FROM gr WHERE grantee IS NOT NULL
  UNION ALL
  SELECT rg.grantee, rg.grantee_type, h.via
  FROM   holders h
  JOIN   dba_data_role_grants rg
         ON rg.role_type = 'DATA ROLE' AND rg.data_role = h.name
  WHERE  h.htype = 'DATA ROLE'
)
CYCLE name SET is_cycle TO 'Y' DEFAULT 'N'
SELECT TO_CHAR(a.event_timestamp, 'YYYY-MM-DD HH24:MI:SS')          AS event_time,
       a.end_user_name,
       CASE
         WHEN EXISTS (SELECT 1 FROM holders h WHERE h.htype = 'END USER' AND h.name = a.end_user_name)
           THEN 'yes'
         WHEN EXISTS (SELECT 1 FROM gr WHERE gr.grantee = 'PUBLIC')
           THEN 'yes (PUBLIC)'
         ELSE 'unresolved'
       END                                                           AS holder,
       a.dbusername                                                  AS db_session_user,
       a.action_name,
       a.return_code,
       RAWTOHEX(a.end_user_security_context_id)                      AS context_id,
       a.client_program_name,
       a.unified_audit_policies,
       SUBSTR(a.sql_text, 1, 300)                                    AS sql_text
FROM   unified_audit_trail a
WHERE  a.event_timestamp >= SYSTIMESTAMP - NUMTODSINTERVAL(&days, 'DAY')
AND    a.end_user_name IS NOT NULL
AND    (a.object_schema, a.object_name) IN (SELECT object_owner, object_name FROM gr)
ORDER  BY a.event_timestamp DESC
