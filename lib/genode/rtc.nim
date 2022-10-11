import ./constructibles

const rtcHeader = "<rtc_session/connection.h>"

type
  ConnectionBase {.importcpp: "Rtc::Connection", header: rtcHeader.} = object
  Connection = Constructible[ConnectionBase]

  Timestamp* {.importcpp: "Rtc::Timestamp", header: rtcHeader.} = object
    microsecond*, second*, minute*, hour*, day*, month*, year*: cuint

proc construct(c: Connection; env: GenodeEnv; label: cstring) {.
    importcpp: "#.construct(*#, @)", tags: [IOEffect].}

proc timestamp*(c: Connection): Timestamp {.
  importcpp: "#->current_time()".}
  # There is an RPC call here but its not listed effect.

proc initRtcConnection*(env: GenodeEnvPtr; label = ""): Connection =
  ## Open a new **RTC** connection.
  result.construct(env, label)
