-- Rebuild the DDL of one Deep Data Security policy from the dictionary:
-- the data roles it names (CREATE DATA ROLE, their database roles and holders),
-- the CREATE OR REPLACE DATA GRANT itself and, if set, SET USE DATA GRANTS ONLY.
-- One row per line of script so a 4000-character predicate still fits;
-- QuinSQL shows the rows as one syntax-highlighted SQL script.
-- Nothing is executed: this is a read of DBA_DATA_GRANTS,
-- DBA_REQUIRED_PARENT_DATA_PRIVILEGES, DBA_DATA_ROLES and DBA_DATA_ROLE_GRANTS.
-- @render sql
-- Binds: &owner, &grant_name  (plain identifiers)
WITH g AS (
  SELECT d.owner, d.grant_name, d.object_owner, d.object_name, d.privilege,
         d.column_name, d.granted_with_all_columns_except AS except_col,
         d.grantee, d.grantee_type, d.predicate, d.cross_table_data_grant,
         d.use_data_grants_only, d.start_time, d.end_time,
         c.column_id, e.column_id AS except_id
  FROM   dba_data_grants d
  LEFT   JOIN dba_tab_columns c
         ON  c.owner = d.object_owner AND c.table_name = d.object_name
         AND c.column_name = d.column_name
  LEFT   JOIN dba_tab_columns e
         ON  e.owner = d.object_owner AND e.table_name = d.object_name
         AND e.column_name = d.granted_with_all_columns_except
  WHERE  d.owner      = UPPER('&owner')
  AND    d.grant_name = UPPER('&grant_name')
),
hdr AS (
  SELECT owner, grant_name, object_owner, object_name, predicate,
         MIN(CASE WHEN cross_table_data_grant THEN 'Y' ELSE 'N' END) AS xtab,
         MIN(CASE WHEN use_data_grants_only  THEN 'Y' ELSE 'N' END) AS mac,
         MIN(start_time) AS start_time, MIN(end_time) AS end_time
  FROM   g
  GROUP  BY owner, grant_name, object_owner, object_name, predicate
),
cols AS (
  SELECT privilege, LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_id, column_name) AS lst
  FROM   (SELECT DISTINCT privilege, column_name, column_id FROM g WHERE column_name IS NOT NULL)
  GROUP  BY privilege
),
excs AS (
  SELECT privilege, LISTAGG(except_col, ', ') WITHIN GROUP (ORDER BY except_id, except_col) AS lst
  FROM   (SELECT DISTINCT privilege, except_col, except_id FROM g WHERE except_col IS NOT NULL)
  GROUP  BY privilege
),
priv_items AS (
  SELECT p.privilege
         || CASE
              WHEN e.lst IS NOT NULL THEN ' (ALL COLUMNS EXCEPT ' || e.lst || ')'
              WHEN c.lst IS NOT NULL THEN ' (' || c.lst || ')'
            END                                                      AS item,
         DECODE(p.privilege, 'SELECT', 1, 'UPDATE', 2, 'INSERT', 3, 'DELETE', 4) AS ord
  FROM   (SELECT DISTINCT privilege FROM g) p
  LEFT   JOIN cols c ON c.privilege = p.privilege
  LEFT   JOIN excs e ON e.privilege = p.privilege
),
priv_list AS (
  SELECT LISTAGG(item, ', ') WITHIN GROUP (ORDER BY ord) AS txt FROM priv_items
),
parent AS (
  SELECT p.cross_table_object_owner AS powner, p.cross_table_object_name AS pname,
         p.privilege,
         LISTAGG(p.column_name, ', ') WITHIN GROUP (ORDER BY c.column_id, p.column_name) AS lst
  FROM   dba_required_parent_data_privileges p
  LEFT   JOIN dba_tab_columns c
         ON  c.owner = p.cross_table_object_owner AND c.table_name = p.cross_table_object_name
         AND c.column_name = p.column_name
  WHERE  p.owner      = UPPER('&owner')
  AND    p.grant_name = UPPER('&grant_name')
  GROUP  BY p.cross_table_object_owner, p.cross_table_object_name, p.privilege
),
parent_list AS (
  SELECT MIN(powner) AS powner, MIN(pname) AS pname,
         LISTAGG(privilege || NVL2(lst, ' (' || lst || ')', ''), ', ')
           WITHIN GROUP (ORDER BY DECODE(privilege, 'SELECT', 1, 'UPDATE', 2, 'INSERT', 3, 'DELETE', 4)) AS txt
  FROM   parent
),
grantees AS (
  SELECT DISTINCT grantee, grantee_type FROM g WHERE grantee IS NOT NULL
),
grantee_list AS (
  SELECT LISTAGG(grantee, ', ') WITHIN GROUP (ORDER BY DECODE(grantee_type, 'DATA ROLE', 1, 2), grantee) AS txt
  FROM   grantees
),
roles AS (
  SELECT gr.grantee AS data_role, r.mapped_to, r.enabled_by_default,
         ROW_NUMBER() OVER (ORDER BY gr.grantee) AS rn
  FROM   grantees gr
  JOIN   dba_data_roles r ON r.data_role = gr.grantee
  WHERE  gr.grantee_type = 'DATA ROLE'
),
lines AS (
  -- 1xxx: data roles named by the grant (skipped when the grantee is an end user or PUBLIC)
  SELECT 1000 + rn * 10 AS seq,
         '-- data role ' || data_role AS line FROM roles
  UNION ALL
  SELECT 1000 + rn * 10 + 1,
         'CREATE DATA ROLE IF NOT EXISTS ' || data_role
         || CASE
              WHEN mapped_to IS NOT NULL THEN ' MAPPED TO ''' || REPLACE(mapped_to, '''', '''''') || ''''
              WHEN NOT enabled_by_default THEN ' DISABLED'
            END || ';'
  FROM   roles
  UNION ALL
  SELECT 1000 + r.rn * 10 + 2,
         'GRANT ' || x.lst || ' TO ' || r.data_role || ';'
  FROM   roles r
  JOIN   (SELECT grantee, LISTAGG(data_role, ', ') WITHIN GROUP (ORDER BY data_role) AS lst
          FROM   (SELECT DISTINCT grantee, data_role FROM dba_data_role_grants
                  WHERE  role_type = 'DATABASE ROLE' AND grantee_type = 'DATA ROLE')
          GROUP  BY grantee) x ON x.grantee = r.data_role
  UNION ALL
  SELECT 1000 + r.rn * 10 + 3 + ROW_NUMBER() OVER (PARTITION BY r.rn ORDER BY h.grantee) / 1000,
         CASE WHEN r.mapped_to IS NOT NULL THEN '-- externally mapped role, cannot be granted: ' ELSE '' END
         || 'GRANT DATA ROLE ' || r.data_role || ' TO ' || h.grantee || ';'
         || CASE WHEN h.start_time IS NOT NULL OR h.end_time IS NOT NULL
                 THEN '  -- add START TIME / END TIME: ' || NVL(h.start_time, '(none)') || ' -> ' || NVL(h.end_time, '(none)')
            END
  FROM   roles r
  JOIN   (SELECT DISTINCT data_role, grantee, start_time, end_time
          FROM   dba_data_role_grants WHERE role_type = 'DATA ROLE') h ON h.data_role = r.data_role
  UNION ALL
  -- 2xxx: end users named directly (accounts are not recreated: passwords are not in the dictionary)
  SELECT 2000 + ROW_NUMBER() OVER (ORDER BY grantee),
         '-- requires end user ' || grantee || ' (CREATE END USER not generated)'
  FROM   grantees WHERE grantee_type = 'END USER'
  UNION ALL
  -- 3xxx: the data grant
  SELECT 3000, 'CREATE OR REPLACE DATA GRANT ' || h.owner || '.' || h.grant_name FROM hdr h
  UNION ALL
  SELECT 3001, '  AS ' || pl.txt FROM priv_list pl
  UNION ALL
  SELECT 3002, '  ON ' || h.object_owner || '.' || h.object_name FROM hdr h
  UNION ALL
  SELECT 3003, '  WHEN ' || pl.txt FROM hdr h CROSS JOIN parent_list pl WHERE h.xtab = 'Y'
  UNION ALL
  SELECT 3004, '  GRANTED ON ' || pl.powner || '.' || pl.pname FROM hdr h CROSS JOIN parent_list pl WHERE h.xtab = 'Y'
  UNION ALL
  SELECT 3005, '  WHERE ' || h.predicate FROM hdr h WHERE h.predicate IS NOT NULL
  UNION ALL
  SELECT 3006, '  TO ' || gl.txt FROM hdr h CROSS JOIN grantee_list gl WHERE h.xtab = 'N'
  UNION ALL
  SELECT 3007, '  START TIME TO_TIMESTAMP_TZ(''' || TO_CHAR(h.start_time, 'YYYY-MM-DD HH24:MI:SS.FF6 TZH:TZM')
               || ''', ''YYYY-MM-DD HH24:MI:SS.FF6 TZH:TZM'')'
  FROM   hdr h WHERE h.start_time IS NOT NULL
  UNION ALL
  SELECT 3008, '  END TIME TO_TIMESTAMP_TZ(''' || TO_CHAR(h.end_time, 'YYYY-MM-DD HH24:MI:SS.FF6 TZH:TZM')
               || ''', ''YYYY-MM-DD HH24:MI:SS.FF6 TZH:TZM'')'
  FROM   hdr h WHERE h.end_time IS NOT NULL
  UNION ALL
  SELECT 3009, ';' FROM hdr
  UNION ALL
  -- 4xxx: mandatory access control on the protected object
  SELECT 4000, 'SET USE DATA GRANTS ONLY ON ' || h.object_owner || '.' || h.object_name || ' ENABLED;'
  FROM   hdr h WHERE h.mac = 'Y'
)
SELECT line AS ddl
FROM   lines
ORDER  BY seq
