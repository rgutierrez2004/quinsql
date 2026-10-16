-- One row per column of a table or view: type, nullability, key role,
-- optimizer column statistics (if gathered) and the existing comment.
-- Works on any supported Oracle release (no annotation views used here).
-- Binds: &schema, &object  (plain identifiers)
SELECT c.column_id,
       c.column_name,
       c.data_type
       || CASE
            WHEN c.data_type IN ('VARCHAR2', 'CHAR', 'NVARCHAR2', 'NCHAR')
              THEN '(' || c.char_length || ')'
            WHEN c.data_type = 'NUMBER' AND c.data_precision IS NOT NULL
              THEN '(' || c.data_precision
                   || CASE WHEN c.data_scale > 0 THEN ',' || c.data_scale END || ')'
            ELSE ''
          END                                                      AS data_type,
       c.nullable,
       (SELECT LISTAGG(
                 CASE k.constraint_type
                   WHEN 'P' THEN 'PK'
                   WHEN 'U' THEN 'UNIQUE'
                   WHEN 'R' THEN 'FK -> ' || p.owner || '.' || p.table_name
                                 || '(' || pc.column_name || ')'
                 END, ', ') WITHIN GROUP (ORDER BY k.constraint_type)
        FROM   all_cons_columns kc
        JOIN   all_constraints  k
               ON  k.owner = kc.owner
               AND k.constraint_name = kc.constraint_name
               AND k.constraint_type IN ('P', 'U', 'R')
        LEFT   JOIN all_constraints p
               ON  p.owner = k.r_owner
               AND p.constraint_name = k.r_constraint_name
        LEFT   JOIN all_cons_columns pc
               ON  pc.owner = p.owner
               AND pc.constraint_name = p.constraint_name
               AND pc.position = kc.position
        WHERE  kc.owner = c.owner
        AND    kc.table_name = c.table_name
        AND    kc.column_name = c.column_name)                      AS keys,
       s.num_distinct,
       s.num_nulls,
       cm.comments
FROM   all_tab_columns c
LEFT   JOIN all_tab_col_statistics s
       ON  s.owner = c.owner
       AND s.table_name = c.table_name
       AND s.column_name = c.column_name
LEFT   JOIN all_col_comments cm
       ON  cm.owner = c.owner
       AND cm.table_name = c.table_name
       AND cm.column_name = c.column_name
WHERE  c.owner = UPPER('&schema')
AND    c.table_name = UPPER('&object')
ORDER  BY c.column_id
