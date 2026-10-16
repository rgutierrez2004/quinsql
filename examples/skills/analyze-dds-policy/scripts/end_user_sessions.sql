-- Live end-user security contexts (local or external users, direct logon or
-- through an application) that currently hold this policy: the user is a
-- direct or role-derived holder, or one of the grant's data roles is enabled
-- in the context. Join key for the audit trail: CONTEXT_ID.
-- @display
-- Binds: &owner, &grant_name  (plain identifiers)
WITH gr AS (
  SELECT DISTINCT grantee, grantee_type
  FROM   dba_data_grants
  WHERE  owner = UPPER('&owner') AND grant_name = UPPER('&grant_name') AND grantee IS NOT NULL
),
holders (name, htype, via) AS (
  SELECT grantee, grantee_type, grantee FROM gr
  UNION ALL
  SELECT rg.grantee, rg.grantee_type, h.via
  FROM   holders h
  JOIN   dba_data_role_grants rg
         ON rg.role_type = 'DATA ROLE' AND rg.data_role = h.name
  WHERE  h.htype = 'DATA ROLE'
)
CYCLE name SET is_cycle TO 'Y' DEFAULT 'N',
ctx AS (
  SELECT c.username, c.context_id, c.user_type, c.security_context_type,
         c.created_time, c.last_access_time, c.inactive_timeout_minutes,
         (SELECT LISTAGG(r.data_role, ', ') WITHIN GROUP (ORDER BY r.data_role)
          FROM   dba_end_user_security_context_data_roles r
          WHERE  r.context_id = c.context_id)                        AS enabled_data_roles
  FROM   dba_end_user_security_contexts c
)
SELECT ctx.username,
       ctx.user_type,
       ctx.security_context_type,
       CASE
         WHEN EXISTS (SELECT 1 FROM holders h WHERE h.htype = 'END USER' AND h.name = ctx.username)
           THEN 'end user holds grant'
         WHEN EXISTS (SELECT 1 FROM gr WHERE gr.grantee = 'PUBLIC')
           THEN 'PUBLIC grant'
         ELSE 'data role enabled in context'
       END                                                           AS matched_by,
       ctx.enabled_data_roles,
       TO_CHAR(ctx.created_time,     'YYYY-MM-DD HH24:MI:SS')        AS created,
       TO_CHAR(ctx.last_access_time, 'YYYY-MM-DD HH24:MI:SS')        AS last_access,
       ctx.inactive_timeout_minutes,
       RAWTOHEX(ctx.context_id)                                      AS context_id
FROM   ctx
WHERE  EXISTS (SELECT 1 FROM holders h WHERE h.htype = 'END USER' AND h.name = ctx.username)
OR     EXISTS (SELECT 1 FROM gr WHERE gr.grantee = 'PUBLIC')
OR     EXISTS (SELECT 1
               FROM   dba_end_user_security_context_data_roles r
               JOIN   holders h ON h.htype = 'DATA ROLE' AND h.name = r.data_role
               WHERE  r.context_id = ctx.context_id)
ORDER  BY ctx.last_access_time DESC NULLS LAST, ctx.username
