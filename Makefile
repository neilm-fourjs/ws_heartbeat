
all: distbin/ws_heartbeat320.gar distbin/ws_heartbeat401.gar

distbin/ws_heartbeat320.gar:
	. env320 && gsmake -force-build -t ws_heartbeat320 ws_heartbeat320.4pw

distbin/ws_heartbeat401.gar:
	. env401 && gsmake -force-build -t ws_heartbeat401 ws_heartbeat401.4pw

clean:
	find . -name \*.42? -delete;
	find . -name \*.gar -delete;
