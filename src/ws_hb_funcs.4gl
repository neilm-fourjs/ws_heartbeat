IMPORT FGL logging
IMPORT FGL ws_lib
IMPORT util
IMPORT os

CONSTANT C_WS_DATAFILE = "../ws_heartbeat_db_info.json"

TYPE t_db_conn_info RECORD
	dbnam STRING,
	dbdrv STRING,
	dbsrc STRING,
	dbusr STRING,
	dbpas STRING
END RECORD
DEFINE m_db_conn_info t_db_conn_info
--------------------------------------------------------------------------------------
-- Return the status of the service
PUBLIC FUNCTION status() ATTRIBUTES(WSGet, WSPath = "/status", WSDescription = "Returns status of service")
		RETURNS STRING
	CALL logging.logIt("status", "Doing Status checks.")
	RETURN ws_lib.service_reply("status", "Okay", NULL)
END FUNCTION
--------------------------------------------------------------------------------------
-- Return server info
PUBLIC FUNCTION info(l_db STRING ATTRIBUTE(WSQuery, WSOptional, WSName = "db"))
		ATTRIBUTES(WSGet, WSPath = "/info", WSDescription = "Returns information about server") RETURNS STRING
	DEFINE l_ret RECORD
		def_dbdriver STRING,
		db_driver    STRING,
		db_date      STRING,
		db_name      STRING,
		db_source    STRING,
		db_status    STRING,
		db_user      STRING,
		db_connect   STRING,
		db_config    STRING
	END RECORD
	DEFINE l_db_pass STRING

	CALL logging.logIt("info", SFMT("Returning information db='%1'.", l_db))

	LET l_ret.db_date = fgl_getenv("DBDATE")

	IF l_db IS NULL THEN
		LET l_ret.db_name = fgl_getenv("DBNAME")
	ELSE
		LET l_ret.db_name = l_db
	END IF

	LET l_ret.db_user   = fgl_getenv("DBUSER")
	LET l_db_pass       = fgl_getenv("DBPASS")
	LET l_ret.db_source = fgl_getenv("DBSOURCE")
	LET l_ret.db_driver = fgl_getenv("DBDRIVER")

	IF loadDBdets() THEN
		LET l_ret.db_config = "From File"
		LET l_ret.db_name   = m_db_conn_info.dbnam
		LET l_ret.db_driver = m_db_conn_info.dbdrv
		LET l_ret.db_source = m_db_conn_info.dbsrc
		LET l_ret.db_user   = m_db_conn_info.dbusr
		LET l_db_pass       = m_db_conn_info.dbpas
	ELSE
		LET l_ret.db_config = "From Environment"
		LET l_ret.db_driver = fgl_getenv("DBDRIVER")
		LET l_ret.db_source = fgl_getenv("DBSOURCE")
		LET l_ret.db_user   = fgl_getenv("DBUSER")
		LET l_db_pass       = fgl_getenv("DBPASS")
	END IF

	LET l_ret.db_connect = SFMT("%1+driver='%2'", l_ret.db_name, l_ret.db_driver)
	IF l_ret.db_source IS NOT NULL THEN
		LET l_ret.db_connect = l_ret.db_connect.append(SFMT(",source='%1@%2'", l_ret.db_name, l_ret.db_source))
	END IF
	IF l_ret.db_user IS NOT NULL THEN
		LET l_ret.db_connect = l_ret.db_connect.append(SFMT(",username='%1'", l_ret.db_user))
	END IF
	IF l_db_pass IS NOT NULL THEN
		LET l_ret.db_connect = l_ret.db_connect.append(SFMT(",password='%1'", l_db_pass))
	END IF
	TRY
		CONNECT TO l_ret.db_connect
		LET l_ret.db_status = "Okay"
	CATCH
		LET l_ret.db_status = SQLERRMESSAGE
	END TRY

	RETURN ws_lib.service_reply("info", "Okay", util.JSON.stringify(l_ret))
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Just exit the service
FUNCTION configureDatabase( l_db_info t_db_conn_info)
		ATTRIBUTES(WSPost, WSPath = "/configureDatabase", WSDescription = "Set database configurate details.") RETURNS STRING

	LET m_db_conn_info.* = l_db_info.*
	CALL saveDBdets()

	RETURN "Okay"
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Just exit the service
FUNCTION exit() ATTRIBUTES(WSGet, WSPath = "/exit", WSDescription = "Exit the service") RETURNS STRING
	CALL logging.logIt("exit", "Stopping service.")
	LET ws_lib.m_stop = TRUE
	RETURN service_reply("exit", "Stopped", NULL)
END FUNCTION
----------------------------------------------------------------------------------------------------
-- dump the env to the gas vm log
FUNCTION env() ATTRIBUTES(WSGet, WSPath = "/env", WSDescription = "Dump Env") RETURNS STRING
	DEFINE l_log STRING
	DEFINE l_env RECORD
		env DYNAMIC ARRAY OF RECORD
			name  STRING,
			value STRING
		END RECORD
	END RECORD
	DEFINE c      base.Channel
	DEFINE i      SMALLINT = 0
	DEFINE x      SMALLINT
	DEFINE l_line STRING

	CALL logging.logIt("env", "env")
	RUN "env | sort"

	LET c = base.Channel.create()
	CALL c.openPipe("env", "r")
	WHILE NOT c.isEof()
		LET l_line                     = c.readLine()
		LET x                          = l_line.getIndexOf("=", 1)
		LET l_env.env[i := i + 1].name = l_line.subString(1, x - 1)
		LET l_env.env[i].value         = l_line.subString(x + 1, l_line.getLength())
	END WHILE
	CALL c.close()
	CALL l_env.env.sort("name", FALSE)
	-- I assume it's -0 not sure how to pickup the number if there are multiple instances running!
	LET l_log = SFMT("vm-%1-0.log", fgl_getenv("FGL_VMPROXY_SESSION_ID"))
	RETURN service_reply("env", SFMT("Env Dumped to '%1'", l_log), util.JSON.stringify(l_env))
END FUNCTION
--------------------------------------------------------------------------------------------------------------
PRIVATE FUNCTION saveDBdets() RETURNS()
	DEFINE l_data TEXT
	LOCATE l_data IN FILE C_WS_DATAFILE
	LET l_data = util.JSON.stringify(m_db_conn_info)
END FUNCTION
--------------------------------------------------------------------------------------------------------------
PRIVATE FUNCTION loadDBdets() RETURNS BOOLEAN
	DEFINE l_data TEXT
	DEFINE l_stat INT
	IF NOT os.Path.exists(C_WS_DATAFILE) THEN
		CALL logging.logIt(0, SFMT("No json datafile '%1'", C_WS_DATAFILE))
		RETURN FALSE
	END IF

	LOCATE l_data IN FILE C_WS_DATAFILE
	TRY
		CALL util.JSON.parse(l_data, m_db_conn_info)
	CATCH
		LET l_stat = STATUS
		CALL logging.logIt(0, SFMT("Failed to parse '%1' %2 %3", C_WS_DATAFILE, l_stat, err_get(l_stat)))
	END TRY
	RETURN TRUE
END FUNCTION
