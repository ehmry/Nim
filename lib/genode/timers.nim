import ./constructibles, ./signals
from times import Duration

const timerHeader = "<timer_session/connection.h>"

type
  ConnectionBase {.importcpp: "Timer::Connection", header: timerHeader.} = object
  TimerConnection* = Constructible[ConnectionBase]

proc construct*(conn: TimerConnection; env: GenodeEnvPtr; label: cstring) {.
  importcpp: "#.construct(*#, @)", tags: [IOEffect].}

proc sigh*(conn: TimerConnection; sigCap: SignalContextCapability) {.
  importcpp: "#->sigh(#)", tags: [IOEffect].}

type
  TimeoutCallback*[T] = proc (state: T; us: uint64) {.cdecl.}
    ## Callback type that accepts at state parameter and the elapsed timout duration in microseconds.
  TimeoutHandler*[T] {.
      importcpp: "Nim::Constructible_timeout_handler<T>",
      header: "genode_cpp/timeouts.h"
    .} = object

proc construct*[T](handler: TimeoutHandler[T]; timer: TimerConnection; state: T; cb: TimeoutCallback) {.
  importcpp: "#.construct(*#, @)".}
  ## Construct a `TimeoutHandler` with a `TimerConnection` and a callback.

proc schedule_us[T](handler: TimeoutHandler[T]; timeout: uint64) {.importcpp.}

proc schedule*[T](handler: TimeoutHandler[T]; timeout: Duration) {.inline.} =
  ## Schedule the handler to be invoked after a timeout.
  let us = timeout.inMicroseconds
  assert(us > 0, "Timeout cannot be less than 1 µs")
  schedule_us(handler, uint64 us)
