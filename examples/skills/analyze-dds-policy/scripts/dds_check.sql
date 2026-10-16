-- Is Oracle Deep Data Security (Deep Sec) available on this database?
-- Deep Sec ships with Oracle AI Database 26ai (version 23.26.2 and later);
-- the decisive test is whether its dictionary views exist.
-- Not displayed: the result goes to the model only, so the probe stays silent
-- on supported databases; the model reports it when DDS_SUPPORTED = 'NO'.
-- No binds.
SELECT v.version_full,
       CASE WHEN d.cnt > 0 THEN 'YES' ELSE 'NO' END                 AS dds_supported,
       CASE
         WHEN d.cnt > 0                                            THEN 'Deep Data Security views present'
         WHEN TO_NUMBER(REGEXP_SUBSTR(v.version_full, '^\d+')) < 23 THEN 'pre-23ai database: Deep Data Security needs Oracle AI Database 26ai (23.26.2+)'
         ELSE 'DBA_DATA_GRANTS not found: upgrade to Oracle AI Database 26ai (23.26.2+) or check privileges'
       END                                                          AS note
FROM   (SELECT MAX(version_full) AS version_full
        FROM   product_component_version
        WHERE  product LIKE 'Oracle%')                             v
CROSS  JOIN (SELECT COUNT(*) AS cnt
             FROM   all_objects
             WHERE  owner = 'PUBLIC'
             AND    object_type = 'SYNONYM'
             AND    object_name = 'DBA_DATA_GRANTS')               d
