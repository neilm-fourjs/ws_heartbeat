IMPORT FGL ws_lib
IMPORT FGL logging
MAIN

  CALL logging.logIt("Started")

  IF NOT ws_lib.init("ws_hb_funcs","HeartBeat") THEN
    EXIT PROGRAM
  END IF

  CALL ws_lib.start()

  CALL logging.logIt("Finished")
END MAIN