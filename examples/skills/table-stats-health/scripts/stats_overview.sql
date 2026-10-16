-- Statistics health for every heap table in one schema.
-- Bind: &schema  (plain identifier, e.g. HR)
SELECT t.table_name,
       t.num_rows,
       t.blocks,
       TO_CHAR(t.last_analyzed, 'YYYY-MM-DD HH24:MI') AS last_analyzed,
       NVL(s.stale_stats, 'NO')                       AS stale_stats,
       CASE
         WHEN t.last_analyzed IS NULL THEN 'NEVER'
         WHEN s.stale_stats = 'YES'   THEN 'STALE'
         ELSE 'OK'
       END                                            AS status
FROM   all_tables t
LEFT   JOIN all_tab_statistics s
       ON  s.owner = t.owner
       AND s.table_name = t.table_name
       AND s.partition_name IS NULL
WHERE  t.owner = UPPER('&schema')
AND    t.temporary = 'N'
AND    t.nested = 'NO'
ORDER  BY CASE
            WHEN t.last_analyzed IS NULL THEN 0
            WHEN s.stale_stats = 'YES'   THEN 1
            ELSE 2
          END,
          t.table_name
