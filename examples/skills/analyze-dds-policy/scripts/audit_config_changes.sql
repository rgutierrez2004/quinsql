-- Administrative changes recorded in UNIFIED_AUDIT_TRAIL for one policy: the
-- data grant itself and every data role / end user it names (CREATE/DROP DATA
-- GRANT, GRANT/REVOKE DATA ROLE, CREATE/ALTER/DROP END USER, ...).
-- Empty when no audit policy covers these actions (see audit_coverage.sql).
-- @display
-- Binds: &owner, &grant_name (plain identifiers), &days (look-back window, e.g. 30)
WITH names AS (
  SELECT UPPER('&grant_name') AS n FROM dual
  UNION
  SELECT DISTINCT grantee
  FROM   dba_data_grants
  WHERE  owner = UPPER('&owner') AND grant_name = UPPER('&grant_name') AND grantee IS NOT NULL
)
SELECT TO_CHAR(a.event_timestamp, 'YYYY-MM-DD HH24:MI:SS')          AS event_time,
       a.action_name,
       a.dbusername                                                  AS admin_user,
       a.object_schema || NVL2(a.object_name, '.' || a.object_name, '') AS target,
       a.return_code,
       a.client_program_name,
       a.unified_audit_policies,
       SUBSTR(a.sql_text, 1, 300)                                    AS sql_text
FROM   unified_audit_trail a
WHERE  a.event_timestamp >= SYSTIMESTAMP - NUMTODSINTERVAL(&days, 'DAY')
AND    a.action_name IN ('CREATE DATA GRANT', 'DROP DATA GRANT',
                         'CREATE DATA ROLE', 'DROP DATA ROLE',
                         'GRANT DATA ROLE', 'REVOKE DATA ROLE',
                         'CREATE END USER', 'ALTER END USER', 'DROP END USER',
                         'CREATE APPLICATION IDENTITY', 'DROP APPLICATION IDENTITY',
                         'SET USE DATA GRANTS ONLY')
AND    EXISTS (SELECT 1 FROM names
               WHERE  a.object_name = names.n
               OR     UPPER(a.sql_text) LIKE '%' || names.n || '%')
ORDER  BY a.event_timestamp DESC
