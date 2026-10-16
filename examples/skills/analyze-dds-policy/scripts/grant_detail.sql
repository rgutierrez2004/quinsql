-- Header of one Deep Data Security policy (data grant): protected object, kind,
-- predicate, time window, mandatory-access-control flag and derived status.
-- @display
-- Binds: &owner, &grant_name  (plain identifiers)
SELECT g.owner,
       g.grant_name,
       g.object_owner || '.' || g.object_name                      AS protected_object,
       MIN(g.object_type)                                          AS object_type,
       CASE WHEN MIN(CASE WHEN g.cross_table_data_grant THEN 'Y' ELSE 'N' END) = 'Y'
            THEN 'CROSS-TABLE' ELSE 'DIRECT' END                   AS grant_kind,
       CASE WHEN MIN(CASE WHEN g.use_data_grants_only THEN 'Y' ELSE 'N' END) = 'Y'
            THEN 'YES' ELSE 'NO' END                               AS mac_only,
       CASE
         WHEN MAX(g.invalid_column_name) IS NOT NULL      THEN 'INVALID'
         WHEN MIN(g.start_time) > SYSTIMESTAMP            THEN 'PENDING'
         WHEN MIN(g.end_time)   < SYSTIMESTAMP            THEN 'EXPIRED'
         ELSE 'ACTIVE'
       END                                                         AS status,
       TO_CHAR(MIN(g.start_time), 'YYYY-MM-DD HH24:MI:SS TZH:TZM') AS start_time,
       TO_CHAR(MIN(g.end_time),   'YYYY-MM-DD HH24:MI:SS TZH:TZM') AS end_time,
       LISTAGG(DISTINCT g.invalid_column_name, ',')
         WITHIN GROUP (ORDER BY g.invalid_column_name)             AS invalid_columns,
       MIN(g.predicate)                                            AS predicate
FROM   dba_data_grants g
WHERE  g.owner      = UPPER('&owner')
AND    g.grant_name = UPPER('&grant_name')
GROUP  BY g.owner, g.grant_name, g.object_owner, g.object_name
