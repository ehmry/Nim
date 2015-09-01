#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#        (c) Copyright 2016 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

{.deadCodeElim:on.}

import genode

const
  timerHeader = "timer_session/connection.h"

type
  Connection* {.final, byref, header: timerHeader,
               importcpp: "Timer::Connection".} = object

proc usleep*(timer: Connection, us: uint) {.
  tags: [SyncIpcEffect], header: timerHeader, importcpp: "#.usleep(@)".}
  ## Sleeps for a given amount of microseconds.
  ## Blocks all threads calling sleep from the same Connection.

proc msleep*(timer: Connection, ms: uint) {.
  tags: [SyncIpcEffect], header: timerHeader, importcpp: "#.msleep(@)".}
  ## Sleeps for a given amount of miliseconds.
  ## Blocks all threads calling sleep from the same Connection.

proc elapsedMs*(timer: Connection): uint {.
  tags: [SyncIpcEffect], header: timerHeader, importcpp: "#.elapsed_ms()".}
  ## Lifetime of the Connection in miliseconds.

var global*: Connection
