IMPORT com
IMPORT util
IMPORT os
IMPORT xml
IMPORT FGL logging

CONSTANT C_VER = "1.0"

TYPE t_response RECORD
	server      STRING,
	os_ver      STRING,
	pid         STRING,
	service_ver STRING,
	statDesc    STRING,
	server_date DATE,
	server_time DATETIME HOUR TO SECOND,
	lang        STRING,
	genero_ver  STRING
END RECORD
PUBLIC DEFINE response t_response ATTRIBUTE(XMLName = "info")
PUBLIC DEFINE m_stop   BOOLEAN = FALSE

DEFINE m_service      STRING
DEFINE m_service_desc STRING
----------------------------------------------------------------------------------------------------
-- Initialize the service - Start the log and connect to database.
FUNCTION init(l_service STRING, l_service_desc STRING) RETURNS BOOLEAN
	DEFINE c    base.Channel
	DEFINE l_os STRING
	LET m_service            = l_service
	LET m_service_desc       = l_service_desc
	LET response.pid         = fgl_getPID()
	LET response.server      = fgl_getEnv("HOSTNAME")
	LET response.service_ver = C_VER
	LET response.lang        = fgl_getEnv("LANG")
	IF response.server IS NULL THEN
		LET c = base.Channel.create()
		CALL c.openPipe("hostname -f", "r")
		LET response.server = c.readLine()
		CALL c.close()
	END IF
	IF os.Path.exists("/etc/issue") THEN
		LET l_os = "/etc/issue"
	END IF
	IF os.Path.exists("/etc/redhat-release") THEN
		LET l_os = "/etc/redhat-release"
	END IF
	IF l_os IS NOT NULL THEN
		LET c = base.Channel.create()
		CALL c.openFile(l_os, "r")
		LET response.os_ver = c.readLine()
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
				LET l_msg  = "Disconnected from application server."
				LET m_stop = TRUE # The Application server has closed the connection
			WHEN -3
				LET l_msg = "Client Connection lost."
			WHEN -4
				LET l_msg = "Server interrupted with Ctrl-C."
			WHEN -8
				LET l_msg  = "Internal HTTP Error."
				LET m_stop = TRUE
			WHEN -9
				LET l_msg = "Unsupported operation."
			WHEN -10
				LET l_msg  = "Internal server error."
				LET m_stop = TRUE
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
	CALL logging.logIt("process", SFMT("Server stopped '%1'", l_msg))

END FUNCTION
----------------------------------------------------------------------------------------------------
-- Format the string reply from the service function
FUNCTION service_reply(l_req STRING, l_stat STRING, l_jstr STRING) RETURNS STRING
	DEFINE l_reply   STRING
	DEFINE l_json    util.JSONObject
	DEFINE l_xml_doc xml.DomDocument
	DEFINE l_xml     xml.DomNode -- temp test of XML in JSON

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

		-- temp test of XML in JSON
		LET l_xml_doc = xml.DomDocument.Create()
		LET l_xml     = l_xml_doc.createElement("info")
		CALL xml.Serializer.VariableToDom(response, l_xml)
		LET l_xml = l_xml.getFirstChild()
		CALL l_xml.setAttribute("test", "This is a test")
		CALL l_json.put("xml", l_xml.toString())

		LET l_reply = l_json.toString()
	END IF
	CALL logging.logIt("service_reply", l_reply)
	RETURN l_reply
END FUNCTION
