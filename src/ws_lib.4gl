IMPORT com
IMPORT util
IMPORT FGL logging
DEFINE m_service       STRING
DEFINE m_service_desc  STRING
PUBLIC DEFINE m_server STRING
PUBLIC DEFINE m_stop   BOOLEAN = FALSE
----------------------------------------------------------------------------------------------------
-- Initialize the service - Start the log and connect to database.
FUNCTION init(l_service STRING, l_service_desc STRING) RETURNS BOOLEAN
	LET m_service      = l_service
	LET m_service_desc = l_service_desc
	LET m_server       = fgl_getEnv("HOSTNAME")
  RETURN TRUE
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Start the service loop
FUNCTION start()
	DEFINE l_ret SMALLINT
	DEFINE l_msg STRING

	CALL com.WebServiceEngine.RegisterRestService(m_service, m_service_desc)

	LET l_msg = SFMT("Service '%1' started on '%2'.", m_service, m_server)
	CALL com.WebServiceEngine.Start()
	WHILE TRUE
		CALL logging.logIt(SFMT("Start: %1", l_msg))
		LET l_ret = com.WebServiceEngine.ProcessServices(-1)
		CASE l_ret
			WHEN 0
				LET l_msg = "Request processed."
			WHEN -1
				LET l_msg = "Timeout reached."
			WHEN -2
				LET l_msg = "Disconnected from application server."
				EXIT WHILE # The Application server has closed the connection
			WHEN -3
				LET l_msg = "Client Connection lost."
			WHEN -4
				LET l_msg = "Server interrupted with Ctrl-C."
			WHEN -9
				LET l_msg = "Unsupported operation."
			WHEN -10
				LET l_msg = "Internal server error."
			WHEN -23
				LET l_msg = "Deserialization error."
			WHEN -35
				LET l_msg = "No such REST operation found."
			WHEN -36
				LET l_msg = "Missing REST parameter."
			OTHERWISE
				LET l_msg = SFMT("Unexpected server error %1.", l_ret)
				EXIT WHILE
		END CASE
		IF int_flag != 0 THEN
			LET l_msg    = "Service interrupted."
			LET int_flag = 0
			EXIT WHILE
		END IF
		IF m_stop THEN
			EXIT WHILE
		END IF
	END WHILE
	CALL logging.logIt(SFMT("Server stopped: %1", l_msg))

END FUNCTION
----------------------------------------------------------------------------------------------------
-- Just exit the service
FUNCTION exit() ATTRIBUTES(WSGet, WSPath = "/exit", WSDescription = "Exit the service") RETURNS STRING
	CALL logging.logIt("Server stopped by 'exit' call")
	LET m_stop = TRUE
	RETURN service_reply("Service Stopped.")
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Format the string reply from the service function
FUNCTION service_reply(l_stat STRING) RETURNS STRING
  DEFINE response RECORD
   server STRING,
   pid string,
	 statDesc STRING,
	 server_date     DATE,
	 server_time     DATETIME HOUR TO SECOND
  END RECORD
  DEFINE l_reply STRING
  LET response.server_date = TODAY
  LET response.server_time = CURRENT
  LET response.statDesc = l_stat
  LET response.pid = fgl_getPID()
  LET response.server = m_server

  LET l_reply = util.JSON.stringify(response)
	CALL logging.logIt(l_reply)
	RETURN l_reply
END FUNCTION
