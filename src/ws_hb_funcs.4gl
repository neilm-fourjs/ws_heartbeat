IMPORT FGL logging
IMPORT FGL ws_lib
IMPORT util
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
		db_name   STRING,
		db_status STRING
	END RECORD
	CALL logging.logIt("info", "Returning information.")
	IF l_db IS NULL THEN
		LET l_ret.db_name = "No Database Name"
	ELSE
		LET l_ret.db_name = l_db
		TRY
			DATABASE l_db
		CATCH
			LET l_ret.db_status = SQLERRMESSAGE
		END TRY
	END IF
	RETURN ws_lib.service_reply("info", "Okay", util.JSON.stringify(l_ret))
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Just exit the service
FUNCTION exit() ATTRIBUTES(WSGet, WSPath = "/exit", WSDescription = "Exit the service") RETURNS STRING
	CALL logging.logIt("exit", "Stoping service.")
	LET ws_lib.m_stop = TRUE
	RETURN service_reply("exit", "Stopped", NULL)
END FUNCTION
