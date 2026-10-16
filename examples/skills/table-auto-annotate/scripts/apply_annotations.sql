-- Apply proposed annotations (and/or comments) to one table or view and its
-- columns in a single step. Classified as a WRITE: QuinSQL asks the user to
-- confirm before running it.
-- Binds:
--   &schema, &object     plain identifiers
--   &object_type         TABLE or VIEW
--   &annotations         Y/N  write ANNOTATIONS (requires Oracle 23ai+)
--   &comments            Y/N  write COMMENT ON from each description
--   &annotations_json    JSON array, one element per object/column:
--     [{"column": null, "display_name": "...", "description": "...", "semantic_type": "..."},
--      {"column": "C1",  "display_name": "...", "description": "...", "semantic_type": "..."}]
--     column = null is the object itself. Values are plain text; the script
--     quotes them.
DECLARE
  v_json        CLOB          := q'[&annotations_json]';
  v_kind        VARCHAR2(5)   := UPPER(TRIM('&object_type'));
  v_do_ann      BOOLEAN       := UPPER(TRIM('&annotations')) = 'Y';
  v_do_cmt      BOOLEAN       := UPPER(TRIM('&comments')) = 'Y';
  v_owner       VARCHAR2(130) := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM('&schema')));
  v_object      VARCHAR2(130) := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM('&object')));
  v_target      VARCHAR2(300) := v_owner || '.' || v_object;
  v_col         VARCHAR2(130);
  v_ann         VARCHAR2(32767);
  v_count       PLS_INTEGER   := 0;

  FUNCTION lit(p_text IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN '''' || REPLACE(p_text, '''', '''''') || '''';
  END;

  PROCEDURE add_ann(p_name IN VARCHAR2, p_value IN VARCHAR2) IS
  BEGIN
    IF p_value IS NULL THEN
      RETURN;
    END IF;
    v_ann := v_ann || CASE WHEN v_ann IS NOT NULL THEN ', ' END
             || 'ADD OR REPLACE ' || p_name || ' ' || lit(SUBSTR(p_value, 1, 4000));
  END;
BEGIN
  IF v_kind NOT IN ('TABLE', 'VIEW') THEN
    RAISE_APPLICATION_ERROR(-20001, 'object_type must be TABLE or VIEW');
  END IF;
  IF v_owner IN ('SYS', 'SYSTEM', 'XDB', 'MDSYS', 'CTXSYS', 'ORDSYS', 'OUTLN', 'DBSNMP') THEN
    RAISE_APPLICATION_ERROR(-20002, 'refusing to annotate Oracle-maintained schema ' || v_owner);
  END IF;

  FOR a IN (SELECT jt.column_name, jt.display_name, jt.description, jt.semantic_type
            FROM   JSON_TABLE(v_json, '$[*]'
                     COLUMNS (column_name   VARCHAR2(128)  PATH '$.column',
                              display_name  VARCHAR2(400)  PATH '$.display_name',
                              description   VARCHAR2(4000) PATH '$.description',
                              semantic_type VARCHAR2(400)  PATH '$.semantic_type')) jt)
  LOOP
    v_col := CASE WHEN a.column_name IS NOT NULL
                  THEN DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM(a.column_name))) END;

    IF v_do_ann THEN
      v_ann := NULL;
      add_ann('display_name',  a.display_name);
      add_ann('description',   a.description);
      add_ann('semantic_type', a.semantic_type);
      IF v_ann IS NOT NULL THEN
        IF v_col IS NULL THEN
          EXECUTE IMMEDIATE 'ALTER ' || v_kind || ' ' || v_target
                            || ' ANNOTATIONS (' || v_ann || ')';
        ELSE
          EXECUTE IMMEDIATE 'ALTER ' || v_kind || ' ' || v_target
                            || ' MODIFY (' || v_col || ' ANNOTATIONS (' || v_ann || '))';
        END IF;
      END IF;
    END IF;

    IF v_do_cmt AND a.description IS NOT NULL THEN
      IF v_col IS NULL THEN
        EXECUTE IMMEDIATE 'COMMENT ON TABLE ' || v_target || ' IS '
                          || lit(SUBSTR(a.description, 1, 4000));
      ELSE
        EXECUTE IMMEDIATE 'COMMENT ON COLUMN ' || v_target || '.' || v_col || ' IS '
                          || lit(SUBSTR(a.description, 1, 4000));
      END IF;
    END IF;

    v_count := v_count + 1;
  END LOOP;

  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20003, 'annotations_json contained no entries');
  END IF;
END;
/
