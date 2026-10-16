-- Review grid of the proposed annotations. Read-only: it only parses the JSON
-- that scripts/apply_annotations.sql will receive, so what the user sees here
-- is exactly what would be written.
-- @display  (always shown to the user as a result grid)
-- Binds: &object_type (TABLE or VIEW), &annotations_json (same JSON as apply)
SELECT NVL(jt.column_name, '(' || LOWER('&object_type') || ')') AS target,
       jt.data_type,
       jt.display_name,
       jt.semantic_type,
       jt.description
FROM   JSON_TABLE(q'[&annotations_json]', '$[*]'
         COLUMNS (seq           FOR ORDINALITY,
                  column_name   VARCHAR2(128)  PATH '$.column',
                  data_type     VARCHAR2(100)  PATH '$.data_type',
                  display_name  VARCHAR2(400)  PATH '$.display_name',
                  semantic_type VARCHAR2(400)  PATH '$.semantic_type',
                  description   VARCHAR2(4000) PATH '$.description')) jt
ORDER  BY jt.seq
