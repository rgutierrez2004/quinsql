-- Refresh optimizer statistics for one table (indexes included).
-- Binds: &schema, &table  (plain identifiers)
-- Classified as a WRITE: QuinSQL asks the user to confirm before running it.
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname => UPPER('&schema'),
    tabname => UPPER('&table'),
    cascade => TRUE);
END;
/
