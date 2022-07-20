
IMPORT FGL logging
IMPORT FGL ws_lib
--------------------------------------------------------------------------------------
-- Return the status of the service
PUBLIC FUNCTION status() ATTRIBUTES(WSGet, WSPath = "/status", WSDescription = "Returns status of service")
		RETURNS STRING
	RETURN ws_lib.service_reply("All Good")
END FUNCTION
