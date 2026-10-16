-- Which unified audit policies would record activity related to one policy:
-- Deep Sec configuration actions (CREATE/DROP DATA GRANT, GRANT DATA ROLE, ...),
-- DML on the protected object, and catch-all ACTIONS ALL policies — with
-- whether each policy is currently enabled.
-- No rows = nothing is audited; see references/dds-concepts.md before offering
-- scripts/enable_dds_audit_policy.sql.
-- @display
-- Binds: &object_owner, &object_name  (the PROTECTED_OBJECT from grant_detail.sql)
WITH opt AS (
  SELECT p.policy_name,
         CASE
           WHEN p.audit_option IN ('CREATE END USER', 'ALTER END USER', 'DROP END USER',
                                   'CREATE APPLICATION IDENTITY', 'DROP APPLICATION IDENTITY',
                                   'CREATE DATA ROLE', 'DROP DATA ROLE',
                                   'GRANT DATA ROLE', 'REVOKE DATA ROLE',
                                   'CREATE DATA GRANT', 'DROP DATA GRANT',
                                   'CREATE END USER CONTEXT', 'DROP END USER CONTEXT',
                                   'CREATE END USER SECURITY CONTEXT')          THEN 'DEEP SEC CONFIG'
           WHEN p.audit_option_type = 'OBJECT ACTION'
            AND p.object_schema = UPPER('&object_owner')
            AND p.object_name   = UPPER('&object_name')                        THEN 'PROTECTED OBJECT'
           WHEN p.audit_option = 'ALL' AND p.audit_option_type = 'STANDARD ACTION' THEN 'ALL ACTIONS'
         END                                                                   AS covers,
         p.audit_option,
         p.oracle_supplied
  FROM   audit_unified_policies p
)
SELECT o.policy_name,
       o.covers,
       LISTAGG(o.audit_option, ', ') WITHIN GROUP (ORDER BY o.audit_option)   AS audited_actions,
       CASE WHEN COUNT(e.policy_name) > 0 THEN 'ENABLED' ELSE 'not enabled' END AS state,
       LISTAGG(DISTINCT NVL2(e.policy_name,
                             e.enabled_option || ' ' || e.entity_name
                             || ' (success=' || e.success || ', failure=' || e.failure || ')',
                             NULL), '; ')
         WITHIN GROUP (ORDER BY e.enabled_option || ' ' || e.entity_name)       AS enabled_for,
       MIN(o.oracle_supplied)                                                  AS oracle_supplied
FROM   opt o
LEFT   JOIN audit_unified_enabled_policies e ON e.policy_name = o.policy_name
WHERE  o.covers IS NOT NULL
GROUP  BY o.policy_name, o.covers
ORDER  BY DECODE(o.covers, 'DEEP SEC CONFIG', 1, 'PROTECTED OBJECT', 2, 3), o.policy_name
