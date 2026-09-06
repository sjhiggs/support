-- Grant necessary permissions to debezium user for LogMiner CDC
-- This script must run as SYS user

-- Grant system privileges required for LogMiner
GRANT SELECT ON V_$DATABASE TO debezium;
GRANT SELECT ON V_$THREAD TO debezium;
GRANT SELECT ON V_$PARAMETER TO debezium;
GRANT SELECT ON V_$NLS_PARAMETERS TO debezium;
GRANT SELECT ON V_$TIMEZONE_NAMES TO debezium;
GRANT SELECT ON ALL_INDEXES TO debezium;
GRANT SELECT ON ALL_OBJECTS TO debezium;
GRANT SELECT ON ALL_USERS TO debezium;
GRANT SELECT ON ALL_CATALOG TO debezium;
GRANT SELECT ON ALL_CONSTRAINTS TO debezium;
GRANT SELECT ON ALL_CONS_COLUMNS TO debezium;
GRANT SELECT ON ALL_TAB_COLS TO debezium;
GRANT SELECT ON ALL_IND_COLUMNS TO debezium;
GRANT SELECT ON ALL_ENCRYPTED_COLUMNS TO debezium;
GRANT SELECT ON ALL_LOG_GROUPS TO debezium;
GRANT SELECT ON ALL_TAB_PARTITIONS TO debezium;
GRANT SELECT ON DBA_TABLESPACES TO debezium;
GRANT SELECT ON DBA_OBJECTS TO debezium;
GRANT SELECT ON USER_TABLES TO debezium;

-- Grant LogMiner specific permissions
GRANT SELECT ON V_$LOG TO debezium;
GRANT SELECT ON V_$LOG_HISTORY TO debezium;
GRANT SELECT ON V_$LOGMNR_LOGS TO debezium;
GRANT SELECT ON V_$LOGMNR_CONTENTS TO debezium;
GRANT SELECT ON V_$LOGMNR_PARAMETERS TO debezium;
GRANT SELECT ON V_$LOGFILE TO debezium;
GRANT SELECT ON V_$ARCHIVED_LOG TO debezium;
GRANT SELECT ON V_$ARCHIVE_DEST_STATUS TO debezium;
GRANT SELECT ON V_$TRANSACTION TO debezium;

-- Grant execute permissions for LogMiner packages
GRANT EXECUTE ON DBMS_LOGMNR TO debezium;
GRANT EXECUTE ON DBMS_LOGMNR_D TO debezium;

-- Grant table-level permissions
GRANT SELECT ANY TABLE TO debezium;
GRANT FLASHBACK ANY TABLE TO debezium;

-- Grant privileges for LogMiner session management
GRANT CREATE SESSION TO debezium;
GRANT SET CONTAINER TO debezium;
GRANT SELECT ANY TRANSACTION TO debezium;
GRANT LOGMINING TO debezium;

-- Grant SELECT_CATALOG_ROLE (contains many required permissions)
GRANT SELECT_CATALOG_ROLE TO debezium;

-- Display granted permissions
SELECT 'Debezium permissions granted successfully!' as status FROM dual;
