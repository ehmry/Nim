#
#
#            Nim's Runtime Library
#        (c) Copyright 2021 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## http://man.9front.org/2/intro

{.pragma: libc, importc.}
{.pragma: defined, importc, nodecl.}
{.push stackTrace:off.}

# Unless noted otherwise these procedures are defined
# in <libc.h>, which is included by nimbase.h. Plan 9
# headers should only be included once.

type
  cuvlong* = culonglong
  cvlong* = clonglong

  Pid* = distinct cint

  Qid* {.importc, final, pure.} = object
    path*: cuvlong
    vers*: culong
    `type`*: uint8

  Dir* {.importc, final, pure.} = object
    `type`*, dev*: cuint
    qid*: Qid
    mode*, atime*, mtime*: culong
    length*: cvlong
    name*, uid*, gid*, muid*: cstring

# ACCESS

proc access*(name: cstring; mode: cint): cint {.libc.}
  ## http://man.9front.org/2/access
var
  AEXIST* {.defined.}: cint
  AEXEC* {.defined.}: cint
  AWRITE* {.defined.}: cint
  AREAD* {.defined.}: cint

# CHDIR

proc chdir*(dirname: cstring): cint {.libc.}
  ## http://man.9front.org/2/chdir

# CPUTIME

proc times(t: array[4, clong]): clong {.libc.}
  ## http://man.9front.org/2/cputime

proc cputime*(): float64 {.libc.}
  ## http://man.9front.org/2/cputime

proc cycles*(cyclep: ptr cuvlong) {.libc.}
  ## http://man.9front.org/2/cputime
  
# DIAL

type NetConnInfo* {.importc, pure, final.} = object
  dir*: cstring ## connection directory 
  root*: cstring ## network root 
  spec*: cstring ## binding spec 
  lsys*: cstring ## local system 
  lserv*: cstring ## local service
  rsys*: cstring ## remote system 
  rserv*: cstring ## remote service 
  laddr*: cstring ## local address 
  raddr*: cstring ## remote address

proc dial*(address, local, dir: cstring; cfdp: ptr cint): cint {.libc.}
  ## http://man.9front.org/2/dial

proc hangup*(ctl: cint): cint {.libc.}
  ## http://man.9front.org/2/dial

proc announce*(address, dir: cstring): cint {.libc.}
  ## http://man.9front.org/2/dial

proc listen*(dir, newdir: cstring): cint {.libc.}
  ## http://man.9front.org/2/dial

proc accept(ctl: cint; dir: cstring): cint {.libc.}
  ## http://man.9front.org/2/dial

proc reject(ctl: cint; dir, cause: cstring): cint {.libc.}
  ## http://man.9front.org/2/dial

proc netmkaddr*(address, defnet, defservice: cstring): cstring {.libc.}
  ## http://man.9front.org/2/dial

proc setnetmtpt*(`to`: cstring; tolen: cint; `from`: cstring) {.libc.}
  ## http://man.9front.org/2/dial

proc getnetconninfo*(conndir: cstring; fd: cint): ptr NetConnInfo {.libc.}
  ## http://man.9front.org/2/dial

proc freenetconninfo*(info: ptr NetConnInfo) {.libc.}
  ## http://man.9front.org/2/dial


# DIRREAD

proc dirread*(fd: cint, buf: var ptr (ptr Dir)): clong {.libc.}
  ## http://man.9front.org/2/dirread

proc dirreadall*(fd: cint, buf: var ptr UncheckedArray[Dir]): clong {.libc.}
  ## http://man.9front.org/2/dirread

var
  STATMAX* {.defined.}: cint
  DIRMAX* {.defined.}: cint

# DUP

proc dup*(oldfd, newfd: cint): cint {.libc}
  ## http://man.9front.org/2/dup

# ERRSTR

proc errstr*(err: ptr char; nerr: cuint): cint {.libc.}
  ## http://man.9front.org/2/errstr

const ERRMAX* = 128

proc errstr*(): string =
  ## http://man.9front.org/2/errstr
  result.setLen(ERRMAX)
  discard errstr(addr result[0], result.len.cuint)
  for i in 0..result.high:
    if result[i] == '\0':
      result.setLen(i)
      return

# EXEC

proc exec*(name: cstring; argv: cstringArray): cint {.libc.}
  ## http://man.9front.org/2/exec

# EXITS

proc exits*(msg: cstring = nil) {.libc, noreturn.}
  ## http://man.9front.org/2/exits

# FORK

proc fork*(): Pid {.libc.}
  ## http://man.9front.org/2/fork

proc rfork*(flags: cint): Pid {.libc.}
  ## http://man.9front.org/2/fork

# GETPID

proc getpid*(): Pid {.libc.}
  ## http://man.9front.org/2/getpid

# GETWD

proc getwd*(buf: ptr char; size: cint): cstring {.libc.}
  ## http://man.9front.org/2/getwd

# NOTIFY

type
  NotifyHandler* = proc (ureg: pointer; note: cstring) {.cdecl.}
  ANotifyHandler* = proc (ureg: pointer; note: cstring): cint {.cdecl.}

proc notify*(nh: NotifyHandler): cint {.libc.}
  ## http://man.9front.org/2/notify

proc noted*(v: cint): cint {.libc.}
  ## http://man.9front.org/2/notify

proc atnotify*(nh: ANotifyHandler; `in`: cint): cint {.libc.}
  ## http://man.9front.org/2/notify

var
  NCONT* {.defined.}: cint ## continue after note
  NDFLT* {.defined.}: cint ## terminate after note
  NSAVE* {.defined.}: cint ## clear note but hold state
  NRSTR* {.defined.}: cint ## restore saved state

# OPEN

proc open*(file: cstring; omode: cint): cint {.libc.}
  ## http://man.9front.org/2/open

proc create*(file: cstring; omode: cint; perm: culong): cint {.libc.}
  ## http://man.9front.org/2/open

proc close*(fd: cint): cint {.libc.}
  ## http://man.9front.org/2/open

var
  OREAD* {.defined.}: cint
  OWRITE* {.defined.}: cint
  ORDWR* {.defined.}: cint
  OEXEC* {.defined.}: cint
  OTRUNC* {.defined.}: cint
  OCEXEC* {.defined.}: cint
  ORCLOSE* {.defined.}: cint
  ODIRECT* {.defined.}: cint
  ONONBLOCK* {.defined.}: cint
  OEXCL* {.defined.}: cint
  OLOCK* {.defined.}: cint
  OAPPEND* {.defined.}: cint

# PIPE

proc pipe*(fd: ptr array[2, cint]): cint {.libc.}
  ## http://man.9front.org/2/pipe

# REMOVE

proc remove*(file: cstring): cint {.libc.}
  ## http://man.9front.org/2/remove

# Sleep

proc sleep*(millisecs: clong): cint {.libc.}
  ## http://man.9front.org/2/sleep

# STAT

proc dirstat*(name: cstring): ptr Dir {.libc.}
  ## http://man.9front.org/2/stat

proc dirfstat*(fd: cint): ptr Dir {.libc.}
  ## http://man.9front.org/2/stat

var
  QTDIR* {.defined.}: uint8
  QTAPPEND* {.defined.}: uint8
  QTEXCL* {.defined.}: uint8
  QTMOUNT* {.defined.}: uint8
  QTAUTH* {.defined.}: uint8
  QTTMP* {.defined.}: uint8
  QTSYMLINK* {.defined.}: uint8
  QTFILE* {.defined.}: uint8

  DMDIR* {.defined.}: culong
  DMAPPEND* {.defined.}: culong
  DMEXCL* {.defined.}: culong
  DMREAD* {.defined.}: culong
  DMWRITE* {.defined.}: culong
  DMEXEC* {.defined.}: culong

proc dirwstat*(name: cstring; dir: ptr Dir): cint {.libc.}
proc dirwstat*(name: cstring; dir: var Dir): cint = dirwstat(name, addr dir)
  ## http://man.9front.org/2/stat

proc nulldir*(d: ptr Dir) {.libc.}
proc nulldir*(d: var Dir) = nulldir(addr d)
  ## http://man.9front.org/2/stat

# STRCAT

proc strcmp*(s1, s2: cstring): cint {.libc.}

# TIME

proc nsec*(): cvlong {.libc.}
  ## http://man.9front.org/2/time

# WAIT

proc waitpid(): cint {.libc.}
  ## http://man.9front.org/2/wait

proc `==`*(x, y: Pid): bool {.borrow.}
proc `$`*(id: Pid): string {.borrow.}

proc c_free*(p: pointer) {.importc: "free".}

{.pop.}

proc cSystem*(command: string): cint =
  ## TODO
  raiseAssert("c_system not implemented for Plan 9")
