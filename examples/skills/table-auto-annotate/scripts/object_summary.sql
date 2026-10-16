-- One-row summary of a table or view, plus whether this database supports
-- annotations (Oracle 23ai or later).
-- Binds: &schema, &object  (plain identifiers)
SELECT o.object_type,
       t.num_rows,
       CASE
         WHEN TO_NUMBER(REGEXP_SUBSTR(v.version, '^\d+')) >= 23 THEN 'YES'
         ELSE 'NO'
       END                                   AS annotations_supported,
       c.comments,
       vw.text_vc                            AS view_text
FROM   all_objects o
CROSS  JOIN (SELECT MAX(version) AS version
             FROM   product_component_version
             WHERE  product LIKE 'Oracle%')  v
LEFT   JOIN all_tables t
       ON  t.owner = o.owner AND t.table_name = o.object_name
LEFT   JOIN all_tab_comments c
       ON  c.owner = o.owner AND c.table_name = o.object_name
LEFT   JOIN all_views vw
       ON  vw.owner = o.owner AND vw.view_name = o.object_name
WHERE  o.owner = UPPER('&schema')
AND    o.object_name = UPPER('&object')
AND    o.object_type IN ('TABLE', 'VIEW')
