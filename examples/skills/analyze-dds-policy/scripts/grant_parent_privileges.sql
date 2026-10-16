-- Cross-table policies only: the privileges that must be held on the parent
-- object (WHEN ... GRANTED ON ...) for this grant to authorise the child object.
-- Returns no rows for a direct (non cross-table) grant.
-- @display
-- Binds: &owner, &grant_name  (plain identifiers)
SELECT p.cross_table_object_owner || '.' || p.cross_table_object_name AS parent_object,
       MIN(p.cross_table_object_type)                               AS parent_type,
       p.privilege                                                  AS required_privilege,
       LISTAGG(p.column_name, ', ') WITHIN GROUP (ORDER BY c.column_id, p.column_name) AS parent_columns,
       LISTAGG(p.invalid_column_name, ', ') WITHIN GROUP (ORDER BY p.invalid_column_name) AS invalid_columns
FROM   dba_required_parent_data_privileges p
LEFT   JOIN dba_tab_columns c
       ON  c.owner = p.cross_table_object_owner AND c.table_name = p.cross_table_object_name
       AND c.column_name = p.column_name
WHERE  p.owner      = UPPER('&owner')
AND    p.grant_name = UPPER('&grant_name')
GROUP  BY p.cross_table_object_owner, p.cross_table_object_name, p.privilege
ORDER  BY DECODE(p.privilege, 'SELECT', 1, 'UPDATE', 2, 'INSERT', 3, 'DELETE', 4)
