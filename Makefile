
# local 
#URL=http://localhost:9090/HeartBeat
# pi Genero 3.20
#URL=https://generodemos.dynu.net/z/ws/r/heartbeat/HeartBeat
# pi Genero 4.01
URL=https://generodemos.dynu.net/z/ws/r/heartbeat/HeartBeat

all: distbin/ws_heartbeat320.gar distbin/ws_heartbeat401.gar

distbin/ws_heartbeat320.gar:
	. env320 && gsmake -force-build -t ws_heartbeat320 ws_heartbeat320.4pw

distbin/ws_heartbeat401.gar:
	. env401 && gsmake -force-build -t ws_heartbeat401 ws_heartbeat401.4pw

clean:
	find . -name \*.42? -delete;
	find . -name \*.gar -delete;

post:
	curl -X POST -H "Content-Type: application/json" -d "@test.json" $(URL)/configureDatabase 

get:
	curl -X GET $(URL)/info | jq .

api:
	curl -X GET $(URL)?openapi.json | jq .
