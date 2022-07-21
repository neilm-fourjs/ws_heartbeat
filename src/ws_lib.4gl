IMPORT com
IMPORT util
IMPORT FGL logging

CONSTANT C_VER = "1.0"

TYPE t_response RECORD
	server      STRING,
	pid         STRING,
  service_ver STRING,
	statDesc    STRING,
	server_date DATE,
	server_time DATETIME HOUR TO SECOND,
	genero_ver  STRING
END RECORD
PUBLIC DEFINE response t_response
PUBLIC DEFINE m_stop   BOOLEAN = FALSE

DEFINE m_service      STRING
DEFINE m_service_desc STRING
----------------------------------------------------------------------------------------------------
-- Initialize the service - Start the log and connect to database.
FUNCTION init(l_service STRING, l_service_desc STRING) RETURNS BOOLEAN
	DEFINE c base.Channel
	LET m_service       = l_service
	LET m_service_desc  = l_service_desc
	LET response.pid    = fgl_getPID()
	LET response.server = fgl_getEnv("HOSTNAME")
  LET response.service_ver = C_VER
	IF response.server IS NULL THEN
		LET c = base.Channel.create()
		CALL c.openPipe("hostname -f", "r")
		LET response.server = c.readLine()
		CALL c.close()
	END IF
	LET response.genero_ver = fgl_getVersion()
	CALL logging.logIt("init", SFMT("Server: %1", response.server))
	RETURN TRUE
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Start the service loop
FUNCTION process()
	DEFINE l_ret SMALLINT
	DEFINE l_msg STRING

	CALL com.WebServiceEngine.RegisterRestService(m_service, m_service_desc)

	LET l_msg = SFMT("Service '%1' started on '%2'.", m_service, response.server)
	CALL com.WebServiceEngine.Start()
	WHILE TRUE
		CALL logging.logIt("process", l_msg)
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
			WHEN -8
				LET l_msg = "Internal HTTP Error."
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
	CALL logging.logIt("process", "Server stopped.")

END FUNCTION
----------------------------------------------------------------------------------------------------
-- Format the string reply from the service function
FUNCTION service_reply(l_req STRING, l_stat STRING, l_jstr STRING) RETURNS STRING
	DEFINE l_reply STRING
	DEFINE l_json  util.JSONObject
	LET response.server_date = TODAY
	LET response.server_time = CURRENT
	LET response.statDesc    = l_stat

	IF l_req = "info" OR l_req = "env" THEN
		LET l_reply = util.JSON.stringify(response)
	ELSE
		LET l_reply = l_stat
	END IF
	IF l_jstr IS NOT NULL THEN
	  CALL logging.logIt("service_reply", SFMT("json '%1'", l_jstr))
		LET l_json = util.JSONObject.parse(l_reply)
		CALL l_json.put("info", util.JSONObject.parse(l_jstr))
		LET l_reply = l_json.toString()
	END IF
	CALL logging.logIt("service_reply", l_reply)
	RETURN l_reply
END FUNCTION
