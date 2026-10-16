-- Unified audit policy for the `analyze-dds-policy` example skill
-- (examples/skills/analyze-dds-policy/).
--
-- Purpose: Oracle Unified Auditing is always on, but it records NOTHING about
-- Deep Data Security until a policy that names the Deep Sec actions (and the
-- DML on a protected object) exists AND is enabled. Without it the skill's
-- audit steps (audit_config_changes / audit_end_user_activity) are empty.
--
-- Usage (needs the AUDIT_ADMIN role, e.g. as SYSTEM):
--   @examples/skills/demo-data/dds-audit-policy.sql ENABLE  HR_DEMO.EMPLOYEES
--   @examples/skills/demo-data/dds-audit-policy.sql DISABLE HR_DEMO.EMPLOYEES
--
--   arg 1  ENABLE  - create the policy DEEP_SEC_POLICY_AUDIT if it does not
--                    exist and enable it for all users (success and failure)
--          DISABLE - NOAUDIT the policy and drop it (so ENABLE can be re-run
--                    for another object)
--   arg 2  OWNER.OBJECT - the table or view protected by the data grants
--                    whose SELECT/INSERT/UPDATE/DELETE should be audited
--
-- The policy also audits CREATE END USER SECURITY CONTEXT, which is excluded
-- from ACTIONS ALL and is what links audit rows to end-user sessions; it writes
-- one record per end-user logon, so drop the policy when the demo is over.
-- Check the result with:
--   SELECT * FROM audit_unified_enabled_policies WHERE policy_name = 'DEEP_SEC_POLICY_AUDIT';

SET SERVEROUTPUT ON

DECLARE
  c_policy  CONSTANT VARCHAR2(128) := 'DEEP_SEC_POLICY_AUDIT';
  l_mode    VARCHAR2(10)  := UPPER(TRIM('&1'));
  l_object  VARCHAR2(261) := UPPER(TRIM('&2'));
  l_owner   VARCHAR2(128);
  l_name    VARCHAR2(128);
  l_exists  PLS_INTEGER;
  l_enabled PLS_INTEGER;
BEGIN
  IF l_mode NOT IN ('ENABLE', 'DISABLE') THEN
    RAISE_APPLICATION_ERROR(-20001, 'first argument must be ENABLE or DISABLE, got "' || l_mode || '"');
  END IF;
  IF INSTR(l_object, '.') = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'second argument must be OWNER.OBJECT, got "' || l_object || '"');
  END IF;
  l_owner := DBMS_ASSERT.SIMPLE_SQL_NAME(SUBSTR(l_object, 1, INSTR(l_object, '.') - 1));
  l_name  := DBMS_ASSERT.SIMPLE_SQL_NAME(SUBSTR(l_object, INSTR(l_object, '.') + 1));

  SELECT COUNT(*) INTO l_exists
  FROM   audit_unified_policies WHERE policy_name = c_policy AND ROWNUM = 1;
  SELECT COUNT(*) INTO l_enabled
  FROM   audit_unified_enabled_policies WHERE policy_name = c_policy;

  IF l_mode = 'ENABLE' THEN
    IF l_exists = 0 THEN
      EXECUTE IMMEDIATE
        'CREATE AUDIT POLICY ' || c_policy || '
           ACTIONS CREATE END USER, ALTER END USER, DROP END USER,
                   CREATE APPLICATION IDENTITY, DROP APPLICATION IDENTITY,
                   CREATE DATA ROLE, DROP DATA ROLE,
                   GRANT DATA ROLE, REVOKE DATA ROLE,
                   CREATE DATA GRANT, DROP DATA GRANT,
                   CREATE END USER CONTEXT, DROP END USER CONTEXT,
                   CREATE END USER SECURITY CONTEXT,
                   SELECT ON ' || l_owner || '.' || l_name || ',
                   INSERT ON ' || l_owner || '.' || l_name || ',
                   UPDATE ON ' || l_owner || '.' || l_name || ',
                   DELETE ON ' || l_owner || '.' || l_name;
      DBMS_OUTPUT.PUT_LINE('created audit policy ' || c_policy || ' (Deep Sec actions + DML on ' || l_owner || '.' || l_name || ')');
    ELSE
      DBMS_OUTPUT.PUT_LINE('audit policy ' || c_policy || ' already exists - run DISABLE first to change the audited object');
    END IF;
    IF l_enabled = 0 THEN
      EXECUTE IMMEDIATE 'AUDIT POLICY ' || c_policy;
      DBMS_OUTPUT.PUT_LINE('enabled ' || c_policy || ' for all users (success and failure)');
    ELSE
      DBMS_OUTPUT.PUT_LINE(c_policy || ' is already enabled');
    END IF;
  ELSE
    IF l_enabled > 0 THEN
      EXECUTE IMMEDIATE 'NOAUDIT POLICY ' || c_policy;
      DBMS_OUTPUT.PUT_LINE('disabled ' || c_policy);
    END IF;
    IF l_exists > 0 THEN
      EXECUTE IMMEDIATE 'DROP AUDIT POLICY ' || c_policy;
      DBMS_OUTPUT.PUT_LINE('dropped ' || c_policy);
    ELSE
      DBMS_OUTPUT.PUT_LINE(c_policy || ' does not exist - nothing to do');
    END IF;
  END IF;
END;
/
