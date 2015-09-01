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

import genode, times

const
  rtcHeader = "rtc_session/connection.h"

type
  Connection* {.final, byref, header: rtcHeader,
               importcpp: "Rtc::Connection".} = object

  TimeStamp* {.header: rtcHeader, importcpp: "struct Rtc::Timestamp".} = object
    ## Native time format returned by the Rtc session.
    microsecond*: uint
    second*: uint
    minute*: uint
    hour*: uint
    day*: uint
    month*: uint
    year*: uint

proc currentTime*(c: Connection): TimeStamp {.
  tags: [SyncIpcEffect], header: rtcHeader, importcpp: "#.current_time()".}

converter toTimeInfo*(ts: TimeStamp): TimeInfo =
  TimeInfo(
      second: ts.second,
      minute: ts.minute,
        hour: ts.hour,
    monthday: ts.day,
       month: Month(ts.month-1),
        year: int(ts.year))

# Timestamps should always come after 1970 and all
# the fields are unsigned, so the math is simple.

converter toTime*(ts: TimeStamp): Time =
  let
    m = (int(ts.month) + 9) mod 12
    y = int(ts.year) - (m div 10)
  Time(
    int(ts.second) + int(ts.minute)*60 + int(ts.hour)*3600 +
    (365*y + y div 4 - y div 100 + y div 400 + (m*306 + 5) div 10 + (int(ts.day) - 1) - 719468)*86400)

converter toFloat*(ts: TimeStamp): float =
  let
    m = (int(ts.month) + 9) mod 12
    y = int(ts.year) - (m div 10)
  float(ts.microsecond div 1000000) + float(
    int(ts.second) + int(ts.minute)*60 + int(ts.hour)*3600 +
    (365*y + y div 4 - y div 100 + y div 400 + (m*306 + 5) div 10 + (int(ts.day) - 1) - 719468)*86400)

when isMainModule:
  let
    epochTs = TimeStamp(year: 1970, month: 1, day: 1, hour: 0, minute: 0, second: 0)
    epochTime: Time = epochTs
  assert epochTime == Time(0)

  let
    billenniumTs = TimeStamp(year: 2001, month: 9, day: 9, hour: 1, minute: 46, second: 40)
    billenniumTime: Time = billenniumTs
  assert billenniumTime == Time(1000000000)

  let
    f13Ts = TimeStamp(year: 2009, month: 2, day: 13, hour: 23, minute: 31, second: 30)
    f13Time: Time = f13Ts
  assert f13Time == Time(1234567890)

  let
    scudTs = TimeStamp(month: 2, day: 25, year: 1991, hour: 0, minute: 0, second: 0)
    scudTime: Time = scudTs
    patriotTime = Time(667440000)
  assert scudTime == patriotTime
