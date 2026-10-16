-- One row per Deep Data Security policy (data grant), with the derived status.
-- Bind: &filter  (LIKE pattern, upper-cased; '%' for everything). It is matched
--       against the grant name, OWNER.GRANT_NAME, the protected OBJECT_OWNER.OBJECT_NAME
--       and every grantee, so "policies on HR.EMPLOYEES" and "policies for
--       role X" both work with the same script.
WITH g AS (
  SELECT owner, grant_name, object_owner, object_name, object_type, privilege,
         grantee, grantee_type, predicate, cross_table_data_grant, use_data_grants_only,
         start_time, end_time, invalid_column_name
  FROM   dba_data_grants
),
hit AS (
  SELECT DISTINCT owner, grant_name
  FROM   g
  WHERE  grant_name                       LIKE UPPER('&filter')
  OR     owner || '.' || grant_name        LIKE UPPER('&filter')
  OR     object_owner || '.' || object_name LIKE UPPER('&filter')
  OR     object_name                      LIKE UPPER('&filter')
  OR     grantee                          LIKE UPPER('&filter')
)
SELECT g.owner,
       g.grant_name,
       g.object_owner || '.' || g.object_name                      AS protected_object,
       MIN(g.object_type)                                          AS object_type,
       LISTAGG(DISTINCT g.privilege, ',')
         WITHIN GROUP (ORDER BY DECODE(g.privilege, 'SELECT', 1, 'UPDATE', 2, 'INSERT', 3, 'DELETE', 4)) AS privileges,
       CASE WHEN MIN(CASE WHEN g.cross_table_data_grant THEN 'Y' ELSE 'N' END) = 'Y'
            THEN 'cross-table'
            ELSE LISTAGG(DISTINCT g.grantee, ',') WITHIN GROUP (ORDER BY g.grantee)
       END                                                         AS grantees,
       CASE WHEN MIN(CASE WHEN g.use_data_grants_only THEN 'Y' ELSE 'N' END) = 'Y' THEN 'YES' ELSE 'NO' END AS mac_only,
       CASE
         WHEN MAX(g.invalid_column_name) IS NOT NULL      THEN 'INVALID'
         WHEN MIN(g.start_time) > SYSTIMESTAMP            THEN 'PENDING'
         WHEN MIN(g.end_time)   < SYSTIMESTAMP            THEN 'EXPIRED'
         ELSE 'ACTIVE'
       END                                                         AS status,
       TO_CHAR(MIN(g.start_time), 'YYYY-MM-DD HH24:MI TZH:TZM')    AS start_time,
       TO_CHAR(MIN(g.end_time),   'YYYY-MM-DD HH24:MI TZH:TZM')    AS end_time
FROM   g
JOIN   hit ON hit.owner = g.owner AND hit.grant_name = g.grant_name
GROUP  BY g.owner, g.grant_name, g.object_owner, g.object_name
ORDER  BY g.owner, g.grant_name
