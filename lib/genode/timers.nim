import ./constructibles, ./signals

const timerHeader = "<timer_session/connection.h>"

type
  ConnectionBase {.importcpp: "Timer::Connection", header: timerHeader.} = object
  TimerConnection* = Constructible[ConnectionBase]

proc construct*(conn: TimerConnection; env: GenodeEnvPtr; label: cstring) {.
  importcpp: "#.construct(*#, @)", tags: [IOEffect].}

proc sigh*(conn: TimerConnection; sigCap: SignalContextCapability) {.
  importcpp: "#->sigh(#)", tags: [IOEffect].}
