-- Create and enable a unified audit policy for Deep Sec configuration actions
-- plus DML on one protected object, following the Oracle Deep Data Security
-- Guide ("Create an Audit Policy"). Only run when the user explicitly asks to
-- enable auditing; audit_coverage.sql shows whether it is already covered.
-- Binds: &policy_name (new audit policy name, e.g. DEEP_SEC_POLICY_AUDIT),
--        &object_owner, &object_name (the PROTECTED_OBJECT)
-- Classified as DDL: QuinSQL asks the user to confirm before running it.
-- Needs the AUDIT_ADMIN role.
DECLARE
  l_policy VARCHAR2(128) := UPPER('&policy_name');
BEGIN
  EXECUTE IMMEDIATE
    'CREATE AUDIT POLICY ' || DBMS_ASSERT.SIMPLE_SQL_NAME(l_policy) || '
       ACTIONS CREATE END USER, ALTER END USER, DROP END USER,
               CREATE APPLICATION IDENTITY, DROP APPLICATION IDENTITY,
               CREATE DATA ROLE, DROP DATA ROLE,
               GRANT DATA ROLE, REVOKE DATA ROLE,
               CREATE DATA GRANT, DROP DATA GRANT,
               CREATE END USER CONTEXT, DROP END USER CONTEXT,
               SELECT ON ' || DBMS_ASSERT.ENQUOTE_NAME(UPPER('&object_owner'), FALSE)
                     || '.' || DBMS_ASSERT.ENQUOTE_NAME(UPPER('&object_name'), FALSE) || ',
               INSERT ON ' || DBMS_ASSERT.ENQUOTE_NAME(UPPER('&object_owner'), FALSE)
                     || '.' || DBMS_ASSERT.ENQUOTE_NAME(UPPER('&object_name'), FALSE) || ',
               UPDATE ON ' || DBMS_ASSERT.ENQUOTE_NAME(UPPER('&object_owner'), FALSE)
                     || '.' || DBMS_ASSERT.ENQUOTE_NAME(UPPER('&object_name'), FALSE) || ',
               DELETE ON ' || DBMS_ASSERT.ENQUOTE_NAME(UPPER('&object_owner'), FALSE)
                     || '.' || DBMS_ASSERT.ENQUOTE_NAME(UPPER('&object_name'), FALSE);
  EXECUTE IMMEDIATE 'AUDIT POLICY ' || DBMS_ASSERT.SIMPLE_SQL_NAME(l_policy);
END;
/
