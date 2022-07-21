
# ws_heartbeat

A simple REST API heartbeat service

## Options

* status : reply should be 'Okay'
* exit   : stops the services and should reply 'Stopped'
* info   : reply is a JSON string.

**NOTE:** The 'info' request can also take a parameter of 'db' and it will attempt to connect to that database, ie:

## Examples

https://_server_/_gas alias_/ws/r/ws_heartbeat/HeartBeat/info
```
{
  "server": "neilm-Predator",
  "pid": "386749",
  "service_ver": "1.0",
  "statDesc": "Okay",
  "server_date": "2022-07-21",
  "server_time": "10:16:24",
  "genero_ver": "32016",
  "info": {
    "def_dbdriver": "dbmdefault",
    "db_name": "No Database Name"
  }
}
```


https://_server_/_gas alias_/ws/r/ws_heartbeat/HeartBeat/info**?db=test**
```
{
  "server": "ubuntu",
  "pid": "50990",
  "service_ver": "1.0",
  "statDesc": "Okay",
  "server_date": "2022-07-21",
  "server_time": "10:41:11",
  "genero_ver": "32016",
  "info": {
    "def_dbdriver": "dbmpgs",
    "db_driver": "Not defined in fglprofile",
    "db_name": "test",
    "db_status": "FATAL:  database \"test\" does not exist"
  }
}
```


https://_server_/_gas alias_/ws/r/ws_heartbeat/HeartBeat/info**?db=njm_demo310**
```
{
  "server": "ubuntu",
  "pid": "50990",
  "service_ver": "1.0",
  "statDesc": "Okay",
  "server_date": "2022-07-21",
  "server_time": "10:39:44",
  "genero_ver": "32016",
  "info": {
    "def_dbdriver": "dbmpgs",
    "db_driver": "Not defined in fglprofile",
    "db_name": "njm_demo310",
    "db_status": "Okay"
  }
}
```
