-- Current annotations of a table or view and its columns (23ai+ only:
-- ALL_ANNOTATIONS_USAGE does not exist on older releases).
-- Annotations belong to the schema of the object they describe, so
-- ANNOTATION_OWNER is the object owner.
-- @display  (always shown to the user as a result grid)
-- Binds: &schema, &object  (plain identifiers)
SELECT CASE WHEN a.column_name IS NULL THEN a.object_type ELSE 'COLUMN' END AS target,
       NVL(a.column_name, a.object_name)                                    AS name,
       a.annotation_name,
       a.annotation_value
FROM   all_annotations_usage a
WHERE  a.annotation_owner = UPPER('&schema')
AND    a.object_name = UPPER('&object')
AND    a.object_type IN ('TABLE', 'VIEW')
ORDER  BY CASE WHEN a.column_name IS NULL THEN 0 ELSE 1 END,
          (SELECT c.column_id
           FROM   all_tab_columns c
           WHERE  c.owner = a.annotation_owner
           AND    c.table_name = a.object_name
           AND    c.column_name = a.column_name),
          a.annotation_name
