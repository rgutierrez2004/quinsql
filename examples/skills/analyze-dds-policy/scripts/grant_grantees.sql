-- Who receives one policy: direct grantees (end users / data roles), and for
-- each data role its definition, the database roles it carries and everyone
-- who holds it directly (DBA_DATA_ROLE_GRANTS). Cross-table grants have no
-- grantees and return no rows: use grant_parent_privileges.sql for them.
-- @display
-- Binds: &owner, &grant_name  (plain identifiers)
WITH gr AS (
  SELECT DISTINCT grantee, grantee_type
  FROM   dba_data_grants
  WHERE  owner      = UPPER('&owner')
  AND    grant_name = UPPER('&grant_name')
  AND    grantee IS NOT NULL
)
SELECT gr.grantee,
       gr.grantee_type,
       CASE gr.grantee_type
         WHEN 'DATA ROLE' THEN
           CASE
             WHEN r.data_role IS NULL  THEN 'built-in'
             WHEN r.mapped_to IS NOT NULL THEN 'external: ' || r.mapped_to
             WHEN r.enabled_by_default THEN 'local, enabled by default'
             ELSE 'local, DISABLED by default'
           END
         WHEN 'END USER' THEN
           NVL2(u.username, u.account_status || ' / ' || u.authentication_type || ' / schema ' || u.schema,
                'external end user')
       END                                                         AS definition,
       (SELECT LISTAGG(x.data_role, ', ') WITHIN GROUP (ORDER BY x.data_role)
        FROM   (SELECT DISTINCT data_role
                FROM   dba_data_role_grants
                WHERE  role_type = 'DATABASE ROLE'
                AND    grantee_type = 'DATA ROLE'
                AND    grantee = gr.grantee) x)                    AS database_roles,
       (SELECT LISTAGG(x.holder, ', ') WITHIN GROUP (ORDER BY x.holder)
        FROM   (SELECT DISTINCT grantee || ' (' || LOWER(grantee_type) || ')'
                                || CASE WHEN start_time IS NOT NULL OR end_time IS NOT NULL
                                        THEN ' [' || NVL(start_time, '..') || ' -> ' || NVL(end_time, '..') || ']'
                                   END AS holder
                FROM   dba_data_role_grants
                WHERE  role_type = 'DATA ROLE'
                AND    data_role = gr.grantee) x)                  AS granted_to
FROM   gr
LEFT   JOIN dba_data_roles r ON gr.grantee_type = 'DATA ROLE' AND r.data_role = gr.grantee
LEFT   JOIN dba_end_users  u ON gr.grantee_type = 'END USER'  AND u.username  = gr.grantee
ORDER  BY DECODE(gr.grantee_type, 'DATA ROLE', 1, 2), gr.grantee
