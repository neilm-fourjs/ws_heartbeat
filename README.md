
ws_heartbeat

A simple REST API heartbeat service

Options

* status : reply should be 'Okay'
* exit   : stops the services and should reply 'Stopped'
* info   : reply is a JSON string.

The 'info' request can also take a parameter of 'db' and it will attempt to connect to that database, ie:

https://_server_/_gas alias_/ws/r/ws_heartbeat/HeartBeat/info
```
{
  "server": "neilm-Predator",
  "pid": "386749",
  "statDesc": "Okay",
  "server_date": "2022-07-21",
  "server_time": "10:16:24",
  "genero_ver": "32016",
  "default_db": "dbmdefault.so",
  "info": {
    "db_name": "No Database Name"
  }
}
```


https://_server_/_gas alias_/ws/r/ws_heartbeat/HeartBeat/info?db=test
```
{
  "server": "neilm-Predator",
  "pid": "386749",
  "statDesc": "Okay",
  "server_date": "2022-07-21",
  "server_time": "10:17:34",
  "genero_ver": "32016",
  "default_db": "dbmdefault.so",
  "info": {
    "db_name": "test",
    "db_status": "Database not found or no system permission."
  }
}
```
