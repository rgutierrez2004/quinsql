-- Privileges granted by one policy, one row per privilege, with the column
-- scope reconstructed the way CREATE DATA GRANT expresses it.
-- DBA_DATA_GRANTS stores column privileges expanded: one row per granted column
-- (times one row per excepted column for ALL COLUMNS EXCEPT, times one row per
-- grantee), so everything is collapsed here with DISTINCT.
-- @display
-- Binds: &owner, &grant_name  (plain identifiers)
WITH g AS (
  SELECT d.privilege, d.column_name, d.granted_with_all_columns_except AS except_col,
         d.invalid_column_name, c.column_id, e.column_id AS except_id
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
cols AS (
  SELECT privilege, LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_id, column_name) AS lst,
         COUNT(*) AS n
  FROM   (SELECT DISTINCT privilege, column_name, column_id FROM g WHERE column_name IS NOT NULL)
  GROUP  BY privilege
),
excs AS (
  SELECT privilege, LISTAGG(except_col, ', ') WITHIN GROUP (ORDER BY except_id, except_col) AS lst,
         COUNT(*) AS n
  FROM   (SELECT DISTINCT privilege, except_col, except_id FROM g WHERE except_col IS NOT NULL)
  GROUP  BY privilege
),
inv AS (
  SELECT privilege, LISTAGG(invalid_column_name, ', ') WITHIN GROUP (ORDER BY invalid_column_name) AS lst
  FROM   (SELECT DISTINCT privilege, invalid_column_name FROM g WHERE invalid_column_name IS NOT NULL)
  GROUP  BY privilege
)
SELECT p.privilege,
       CASE
         WHEN e.lst IS NOT NULL THEN 'ALL COLUMNS EXCEPT'
         WHEN c.lst IS NOT NULL THEN 'COLUMN LIST'
         ELSE 'ALL COLUMNS'
       END                                   AS scope,
       CASE
         WHEN e.lst IS NOT NULL THEN e.lst
         ELSE c.lst
       END                                   AS columns,
       CASE
         WHEN e.lst IS NOT NULL THEN c.n
         WHEN c.lst IS NOT NULL THEN c.n
       END                                   AS granted_column_count,
       i.lst                                 AS invalid_columns
FROM   (SELECT DISTINCT privilege FROM g) p
LEFT   JOIN cols c ON c.privilege = p.privilege
LEFT   JOIN excs e ON e.privilege = p.privilege
LEFT   JOIN inv  i ON i.privilege = p.privilege
ORDER  BY DECODE(p.privilege, 'SELECT', 1, 'UPDATE', 2, 'INSERT', 3, 'DELETE', 4)
