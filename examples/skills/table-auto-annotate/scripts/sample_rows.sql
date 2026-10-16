-- A small random sample of rows, used only as evidence of what the columns
-- mean. Works for tables and views alike (no SAMPLE clause).
-- Binds: &schema, &object (plain identifiers), &sample_size (e.g. 15)
SELECT *
FROM   (SELECT * FROM &schema.&object ORDER BY DBMS_RANDOM.VALUE)
WHERE  ROWNUM <= &sample_size
