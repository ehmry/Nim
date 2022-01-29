## Solo5 glue.
# (c) 2024 Emery Heminyway

{.pragma: solo5, importc, header: "solo5.h".}

type
  Solo5Result* {.solo5, importc: "solo5_result_t".} = enum
    SOLO5_R_OK,
    SOLO5_R_AGAIN,
    SOLO5_R_EINVAL,
    SOLO5_R_EUNSPEC

  Solo5StartInfo* {.solo5, importc: "solo5_start_info".} = object
    cmdline*: cstring
    heap_start*: pointer
    heap_size*: csize_t

  Solo5Time* = distinct uint64
    ## Type for time values, with nanosecond precision.

  NetHandle* = distinct uint64
  BlkHandle* = distinct uint64
    ## Types for I/O handles.

  HandleSet* = distinct uint64
    ## Type for sets of up to 64 Net device handles.

proc `<`*(a, b: Solo5Time): bool {.borrow.}
proc `<=`*(a, b: Solo5Time): bool {.borrow.}
proc `+`*(a, b: Solo5Time): Solo5Time {.borrow.}
proc `-`*(a, b: Solo5Time): Solo5Time {.borrow.}
proc `cmp`*(a, b: Solo5Time): int = a.int - b.int

proc `==`*(x, y: Solo5Time): bool {.borrow.}
proc `==`*(x, y: NetHandle): bool {.borrow.}
proc `==`*(x, y: BlkHandle): bool {.borrow.}

iterator items*(hs: HandleSet): NetHandle =
  var
    hs = hs.uint64 shr 1
    i = 1
  while hs != 0 and i < 64:
    if (hs and 1) == 1:
      yield NetHandle(i)
    hs = hs shr 1
    inc i

const
  SOLO5_EXIT_SUCCESS* = 0
  SOLO5_EXIT_FAILURE* = 1
  SOLO5_EXIT_ABORT* = 255

let solo5_start_info* {.importc: "_solo5_start_info", nodecl.}: ptr Solo5StartInfo

proc solo5_exit*(status: cint) {.solo5, noreturn.}

proc solo5_abort*() {.solo5, noreturn.}

proc solo5_set_tls_base*(base: pointer): Solo5Result {.solo5.}

proc solo5_clock_monotonic*(): Solo5Time {.solo5.}

proc solo5_clock_wall*(): Solo5Time {.solo5.}

proc solo5_yield*(deadline: Solo5Time; ready_set: ptr HandleSet = nil) {.solo5, tags: [TimeEffect].}

proc solo5_console_write*(buf: cstring; size: csize_t) {.solo5, tags: [WriteIOEffect].}

proc solo5_console_write*(s: static[string]) = solo5_console_write(s.cstring, s.len)

const
  SOLO5_NET_ALEN* = 6
  SOLO5_NET_HLEN* = 14

type
  MacAddress* = array[SOLO5_NET_ALEN, uint8]

  NetInfo* {.solo5, importc: "struct solo5_net_info", pure.} = object
    mac_address*: MacAddress
    mtu*: csize_t ##  Not including Ethernet header

proc `$`*(mac: MacAddress): string =
  result.setLen(17)
  var j: int
  for b in mac:
    var n = b shr 4
    result[j] = char(if n < 10: n + ord('0') else: n - 10 + ord('A'))
    inc j
    n = b and 0xf
    result[j] = char(if n < 10: n + ord('0') else: n - 10 + ord('A'))
    inc j
    if j < result.len:
      result[j] = '-'
      inc j

proc solo5_net_acquire(name: cstring; handle: ptr NetHandle;
    info: ptr NetInfo): Solo5Result {.solo5.}

proc net_acquire*(name: string): (NetHandle, NetInfo) =
  let res = solo5_net_acquire(name, addr result[0], addr result[1])
  if res != SOLO5_R_OK:
    raise newException(AccessViolationDefect, $res)

proc solo5_net_write*(handle: NetHandle; buf: ptr uint8; size: csize_t): Solo5Result {.
  solo5, tags: [WriteIOEffect].}

proc write*(handle: NetHandle; buf: openarray[byte]) =
  let res = solo5_net_write(handle, unsafeAddr buf[0], csize_t buf.len)
  if res != SOLO5_R_OK: raise newException(IOError, $res)

proc solo5_net_read*(handle: NetHandle; buf: ptr uint8; size: csize_t; read_size: ptr csize_t): Solo5Result {.
  solo5, tags: [ReadIOEffect].}

proc read*(handle: NetHandle; buf: var openarray[byte]): int =
  var n: csize_t
  let res = solo5_net_read(handle, unsafeAddr buf[0], csize_t buf.len, addr n)
  if res != SOLO5_R_OK: raise newException(IOError, $res)
  int n

type
  OffInt* = uint64
  BlockInfo* {.solo5, importc: "struct solo5_block_info", pure.} = object
    capacity*: OffInt   ##  Capacity of block device, bytes
    block_size*: OffInt ##  Minimum I/O unit (block size), bytes

proc solo5_block_acquire(name: cstring; handle: ptr BlkHandle;
                   info: ptr BlockInfo): Solo5Result {.solo5.}

proc block_acquire*(name: string): (BlkHandle, BlockInfo) =
  let res = solo5_block_acquire(name, addr result[0], addr result[1])
  if res != SOLO5_R_OK:
    raise newException(AccessViolationDefect, $res)

proc solo5_block_write*(handle: BlkHandle; offset: OffInt; buf: ptr uint8; size: csize_t): Solo5Result {.
    solo5, tags: [WriteIOEffect].}
  ## Writes data of `size` bytes from the buffer `buf` to the block device
  ## identified by `handle`, starting at byte `offset`. Data is either written in
  ## it's entirety or not at all ("short writes" are not possible).
  ##
  ## Both `size` and `offset` must be a multiple of the block size.

proc write*(handle: BlkHandle; offset: OffInt; buf: openarray[byte]) =
  let res = solo5_block_write(handle, offset, unsafeAddr buf[0], csize_t buf.len)
  if res != SOLO5_R_OK: raise newException(IOError, $res)

proc solo5_block_read*(handle: BlkHandle; offset: OffInt; buf: ptr uint8; size: csize_t): Solo5Result {.
    solo5, tags: [ReadIOEffect].}
  ## Reads data of `size` bytes into the buffer `buf` from the block device
  ## identified by `handle`, starting at byte (offset). Always reads the full
  ## amount of `size` bytes ("short reads" are not possible).
  ##
  ## Both `size` and `offset` must be a multiple of the block size.

proc read*(handle: BlkHandle; offset: OffInt; buf: var openarray[byte]) =
  let res = solo5_block_read(handle, offset, unsafeAddr buf[0], csize_t buf.len)
  if res != SOLO5_R_OK: raise newException(IOError, $res)


type
  DeviceType* = enum blockBasic, netBasic
  ManifestEntry* = tuple[name: string, device: DeviceType]

proc generateMft(devices: openarray[ManifestEntry]): string {.compileTime.} =
  var
    entries: string
    numEntries = 1
  for (name, dev) in devices:
    case dev
    of blockBasic:
      entries.add """, { .name = """" & name & """", .type = MFT_DEV_BLOCK_BASIC }"""
    of netBasic:
      entries.add """, { .name = """" & name & """", .type = MFT_DEV_NET_BASIC }"""
    inc numEntries
  """
#define MFT_ENTRIES """ & $numEntries & """

#include "mft_abi.h"

MFT1_NOTE_DECLARE_BEGIN
{
  .version = MFT_VERSION, .entries = """ & $numEntries & """,
  .e = {
    { .name = "", .type = MFT_RESERVED_FIRST }""" & $entries & """
  }
}
MFT1_NOTE_DECLARE_END
  """

type
  NetInitHook* = proc(name: string; h: NetHandle, ni: NetInfo) {.nimcall.}
  BlkInitHook* = proc(name: string; h: BlkHandle, bi: BlockInfo) {.nimcall.}

proc discardNet(name: string; h: NetHandle, ni: NetInfo) {.nimcall.} = discard
proc discardBlk(name: string; h: BlkHandle, bi: BlockInfo) {.nimcall.} = discard

template acquireDevices*(
    entries: openArray[ManifestEntry] = [];
    netInit: NetInitHook = discardNet;
    blkInit: BlkInitHook = discardBlk) =
  ## Acquire and initialize Solo5 devices.
  ## This template generates a static ELF note and
  ## therefore must be called at the top-level of a module
  ## and only once per-program.
  {.emit: generateMft(entries).}
  proc initDevices() =
    for (name, dev) in entries:
      case dev
      of blockBasic:
        var (h, bi) = block_acquire(name)
        blkInit(name, h, bi)
      of netBasic:
        var (h, ni) = net_acquire(name)
        netInit(name, h, ni)
  initDevices()
