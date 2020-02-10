#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when not defined(genode):
  {.error: "Genode only include".}

include genode/env
const timerHeader = "<timer_session/connection.h>"

type
  TimerConnection {.importcpp: "Timer::Connection", header: timerHeader, pure.} = object

proc initTimer(env: GenodeEnvPtr; label: cstring): TimerConnection {.
      importcpp: "Timer::Connection(*#, #)", constructor.}

proc sleep*(milsecs: int) =
  proc usleep(timer: TimerConnection; us: clonglong) {.importcpp: "#.usleep(#)".}
  let timer = initTimer(runtimeEnv, "Nim runtime")
  timer.usleep(milsecs * 1_000)
