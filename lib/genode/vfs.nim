#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

include genode/env

const vfsHeader = "<vfs/file_system.h>"

from strutils import rsplit
const vfsPath = currentSourcePath.rsplit("/", 1)[0]
const vfsH = vfsPath & "/vfs.h"

import std/deques, std/locks, std/os

type
  FileSize* = culonglong

  VfsHandleObj {.
    importcpp: "Vfs::Vfs_handle", header: "vfs/vfs_handle.h", final, pure.} = object

  VfsHandle* = ptr VfsHandleObj
    ## VFS handles are pointers to file-system specific
    ## objects with a common Vfs_handle base class.

  QueueState = enum qIdle, qRead, qSync
    ## Handle states.

  VfsContext* = ref VfsContextObj
  VfsCallback* = proc (ctx: VfsContext) {.closure, gcsafe.}
  VfsContextObj {.pure, final.} = object
    x, y, z: int
      ## TODO: padding to allow the object to be cast as a
      ## Genode::List<>::Element and inserting into a list.
      ## I am a bad person that should feel bad about this.
    handle*: VfsHandle
    handler*: VfsCallback
    queue: QueueState
      ## Queuing state of the handle.

proc close(h: VfsHandle) {.importcpp.}

proc close*(ctx: VfsContext) {.tags: [IOEffect].} =
  ## Close a VFS handle context
  close ctx.handle
  reset ctx.handle

proc seek*(ctx: VfsContext): FileSize =
  ## Return seek offset in bytes.
  proc seek(h: VfsHandle): FileSize {.importcpp.}
  assert(ctx.queue == qIdle, "cannot seek VFS context while an operation is queued")
  ctx.handle.seek

proc seek*(ctx: VfsContext; n: FileSize) =
  ## Set seek offset in bytes.
  proc seek(ctx: VfsHandle; n: FileSize) {.importcpp.}
  ctx.handle.seek(n)

proc advanceSeek*(ctx: VfsContext; incr: FileSize) =
  ## Advance seek offset by 'incr' bytes.
  proc advance_seek(h: VfsHandle; incr: FileSize) {.importcpp.}
  ctx.handle.advance_seek(incr)

proc readQueued*(ctx: VfsContext): bool = ctx.queue == qRead
  ## Check if the context is ready for `completeRead`.
proc syncQueued*(ctx: VfsContext): bool = ctx.queue == qSync
  ## Check if the context is ready for `completeSync`.

proc onIOResponse*(ctx: VfsContext; cb: VfsCallback) {.gcsafe.} =
  ## Add a callback to handle an I/O response for the
  ## given context.
  assert(not ctx.handle.isNil)
  assert(ctx.handler.isNil,
    "cannot register multiple I/O response handlers on a single VFS context")
  ctx.handler = cb

type Directory_service {.
  importcpp: "Vfs::Directory_service", header: "vfs/directory_service.h".} = object
  ## Directory traversal subset of file-system interface.

type File_io_service {.
  importcpp: "Vfs::File_io_service", header: "vfs/file_io_service.h".} = object
  ## File I/O subset of file-system interface.

proc ds(h: VfsHandle): DirectoryService {.importcpp.}
  ## Access the directory backend of a handle.

proc fs(h: VfsHandle): FileIoService {.importcpp.}
  ## Access the file I/O backend of a handle.

type Constructible* {.
  importcpp: "Genode::Constructible",
  header: "<util/reconstructible.h>", final, pure.} [T] = object

proc construct*[T](x: Constructible[T]) {.importcpp.}
  ## Construct a constructible C++ object.

proc destruct*[T](x: Constructible[T]) {.importcpp.}
  ## Destruct a constructible C++ object.

type
  AppPair = tuple[cb: VfsCallback; ctx: VfsContext]
  VfsEnvImpl {.
    importcpp: "Nim::VfsEnv", header: vfsH, final, pure.} = object
  VfsEnvObj = Constructible[VfsEnvImpl]
  VfsEnv = object
    cpp: VfsEnvObj
    callbacks: Deque[AppPair]
    ep: Entrypoint

proc construct(ve: VfsEnvObj, ge: GenodeEnvPtr) {.importcpp.}

proc ds(veo: VfsEnvObj): DirectoryService {.importcpp.}
template ds(ve: VfsEnv): DirectoryService = ve.cpp.ds
  ## Access the VFS directory interface.

proc fs(veo: VfsEnvObj): FileIoService {.importcpp.}
template fs(ve: VfsEnv): FileIoService = ve.cpp.fs
  ## Access the VFS I/O interface.

var
  gVfslock*: Lock
  gVfsEnv {.guard: gVfsLock.}: VfsEnv

proc initVfs*(ge: GenodeEnvPtr) =
  ## Initialize the Nim global VFS instance.
  withLock gVfsLock:
    construct(gVfsEnv.cpp, ge)
    gVfsEnv.callbacks = initDeque[AppPair](64)
    gVfsEnv.ep = ge.ep

type Stat* {.importcpp: "Vfs::Directory_service::Stat", header: vfsHeader, final, pure.} = object
      size*: csize
      inode*: culong
      device*: culong

proc isFile*(stat: Stat): bool {.importcpp:
  "(#.type == CONTINUOUS_FILE || #.type == TRANSACTIONAL_FILE)".}

proc isDir*(stat: Stat): bool {.importcpp:
  "(#.type == DIRECTORY)".}

proc isSymlink*(stat: Stat): bool {.importcpp:
  "(#.type == SYMLINK)".}

proc readable*(stat: Stat): bool {.
  importcpp: "#.rwx.readable".}

proc writeable*(stat: Stat): bool {.
  importcpp: "#.rwx.writeable".}

proc executable*(stat: Stat): bool {.
  importcpp: "#.rwx.executable".}

proc getLastModificationTime*(stat: Stat): clonglong {.
  importcpp: "#.modification_time.value".}

proc stat*(path: string): Stat =
  type
    Stat_result {.importcpp: "Vfs::Directory_service::Stat_result", pure.} = enum
      STAT_ERR_NO_ENTRY, STAT_ERR_NO_PERM, STAT_OK
  proc stat(ds: DirectoryService; path: cstring; st: var Stat): Stat_result {.
    importcpp, tags: [IOEffect].}
  var
    buf: Stat
    r: Stat_result
  withLock gVfsLock:
    r = gVfsEnv.ds.stat(path, buf)
  if r != STAT_OK:
    raise newException(OSError, $r)
  buf

type Unlink_result* {.importcpp: "Vfs::Directory_service::Unlink_result", pure.} = enum
  UNLINK_ERR_NO_ENTRY, UNLINK_ERR_NO_PERM,
  UNLINK_ERR_NOT_EMPTY, UNLINK_OK

proc unlink*(path: string): Unlink_result =
  proc unlink(ds: DirectoryService; path: cstring): Unlink_result {.importcpp.}
  withLock gVfsLock:
    result = gVfsEnv.ds.unlink(path)

type Rename_result* {.importcpp: "Vfs::Directory_service::Rename_result", pure.} = enum
  RENAME_ERR_NO_ENTRY, RENAME_ERR_CROSS_FS,
  RENAME_ERR_NO_PERM, RENAME_OK

proc rename*(source, dest: string): Rename_result =
  proc rename(ds: DirectoryService; source, dest: cstring): Rename_result {.importcpp.}
  withLock gVfsLock:
    result = gVfsEnv.ds.rename(source, dest)

type Opendir_result* {.importcpp: "Vfs::Directory_service::Opendir_result", pure.} = enum
  OPENDIR_ERR_LOOKUP_FAILED, OPENDIR_ERR_NAME_TOO_LONG,
  OPENDIR_ERR_NODE_ALREADY_EXISTS, OPENDIR_ERR_NO_SPACE,
  OPENDIR_ERR_OUT_OF_RAM, OPENDIR_ERR_OUT_OF_CAPS,
  OPENDIR_ERR_PERMISSION_DENIED, OPENDIR_OK

proc createDir*(path: string): Opendir_result =
  proc openDir(
      ve: VfsEnvObj; path: cstring; create: bool;
      handle: var VfsHandle; arg: pointer): Opendir_result {.
    importcpp: "#->openDir(#, #, &#, #)", tags: [IOEffect].}
  var handle: VfsHandle
  withLock gVfsLock:
    result = gVfsEnv.cpp.openDir(path, create=true, handle, nil)
    if result == OPENDIR_OK:
      close(handle)

type Openlink_result* {.importcpp: "Vfs::Directory_service::Openlink_result", pure.} = enum
  OPENLINK_ERR_LOOKUP_FAILED, OPENLINK_ERR_NAME_TOO_LONG,
  OPENLINK_ERR_NODE_ALREADY_EXISTS, OPENLINK_ERR_NO_SPACE,
  OPENLINK_ERR_OUT_OF_RAM, OPENLINK_ERR_OUT_OF_CAPS,
  OPENLINK_ERR_PERMISSION_DENIED, OPENLINK_OK

proc notifyReadReady*(ctx: VfsContext): bool =
  ## Explicitly indicate interest in read-ready notifications for a context.
  assert(not ctx.handle.isNil)
  proc notify_read_ready(fs: FileIoService; h: VfsHandle): bool {.
    importcpp, tags: [IOEffect].}
  withLock gVfsLock:
    result = ctx.handle.fs.notify_read_ready(ctx.handle)

proc readReady*(ctx: VfsContext): bool =
  ## Return true if the handle can be meaningfully read.
  assert(not ctx.handle.isNil)
  proc read_ready(fs: FileIoService; h: VfsHandle): bool {.
    importcpp, tags: [IOEffect].}
  withLock gVfsLock:
    result = ctx.handle.fs.read_ready(ctx.handle)

proc queueRead*(ctx: VfsContext; size: FileSize) =
  ## Return false if handle read queue is full.
  assert(not ctx.handle.isNil)
  proc queue_read(fs: FileIoService; h: VfsHandle; size: FileSize): bool {.
    importcpp, tags: [IOEffect].}
  assert(ctx.queue == qIdle, "VFS context is already queued")
  withLock gVfsLock:
    if ctx.handle.fs.queue_read(ctx.handle, size):
      ctx.queue = qRead

proc completeRead*(ctx: VfsContext; buf: pointer; size: FileSize): FileSize =
  ## Complete a queued read into a buffer.
  assert(not ctx.handle.isNil)
  assert(ctx.queue == qRead)
  type ReadResult {.importcpp: "Vfs::File_io_service::Read_result", pure.} = enum
    READ_ERR_AGAIN, READ_ERR_WOULD_BLOCK, READ_ERR_INVALID,
    READ_ERR_IO, READ_ERR_INTERRUPT, READ_QUEUED,
    READ_OK
  proc complete_read(
      fs: FileIoService; h: VfsHandle;
      buf: pointer; len: FileSize; outLen: var FileSize): ReadResult {.
    importcpp, tags: [ReadIOEffect].}
  var
    err: ReadResult
  withLock gVfsLock:
    err = ctx.handle.fs.completeRead(ctx.handle, buf, size, result)
  case err
  of READ_QUEUED: discard
  of READ_OK:
    ctx.queue = qIdle
  else:
    ctx.queue = qIdle
    raise newException(IOError, $err)

proc write*(ctx: VfsContext; buf: pointer; len: Natural): FileSize =
  ## Write data to a handle. Writes return immediately, use `completeSync`
  ## to check for errors.
  assert(not ctx.handle.isNil)
  type Result {.importcpp: "Vfs::File_io_service::Write_result", pure.} = enum
    WRITE_ERR_AGAIN, WRITE_ERR_WOULD_BLOCK, WRITE_ERR_INVALID
    WRITE_ERR_IO, WRITE_ERR_INTERRUPT, WRITE_OK
  proc write(
      fs: FileIoService; h: VfsHandle;
      buf: pointer; len: FileSize; outLen: var FileSize): Result {.
    importcpp, tags: [WriteIOEffect].}
  var err: Result
  withLock gVfsLock:
    err = ctx.handle.fs.write(ctx.handle, buf, len.FileSize, result)
  case err
  of WRITE_OK: discard
  else:
    raise newException(IOError, $err)

proc queueSync*(ctx: VfsContext; len: Natural) =
  ## Return true if a sync can be queued at the handle context.
  assert(not ctx.handle.isNil)
  proc queue_sync(fs: FileIoService; h: VfsHandle): bool {.
    importcpp, tags: [IOEffect].}
  assert(ctx.queue == qIdle, "VFS context is already queued")
  withLock gVfsLock:
    if ctx.handle.fs.queue_sync(ctx.handle):
      ctx.queue = qSync

proc completeSync*(ctx: VfsContext): bool =
  ## Return true if a sync can be completed.
  assert(not ctx.handle.isNil)
  assert(ctx.queue == qSync)
  type Result {.importcpp: "Vfs::File_io_service::Sync_result", pure.} = enum
    SYNC_QUEUED, SYNC_ERR_INVALID, SYNC_OK
  proc complete_sync(fs: FileIoService; h: VfsHandle): Result {.
    importcpp, tags: [IOEffect].}
  var err: Result
  withLock gVfsLock:
    err = ctx.handle.fs.complete_sync(ctx.handle)
  case err
  of SYNC_OK:
    ctx.queue = qIdle
    result = true
  of SYNC_QUEUED: discard
  else:
    ctx.queue = qIdle
    raise newException(IOError, $err)

proc truncate*(ctx: VfsContext; len: Natural) {.tags: [WriteIOEffect].} =
  ## Truncate or expand a file. Handle must be idle.
  assert(ctx.queue == qIdle)
  type Result {.importcpp: "Vfs::File_io_service::Ftruncate_result", pure.} = enum
    FTRUNCATE_ERR_NO_PERM, FTRUNCATE_ERR_INTERRUPT,
    FTRUNCATE_ERR_NO_SPACE, FTRUNCATE_OK
  proc ftruncate(fs: FileIoService; h: VfsHandle; len: FileSize): Result {.importcpp.}
  var err: Result
  withLock gVfsLock:
    err = ctx.handle.fs.ftruncate(ctx.handle, len.FileSize)
  if err != FTRUNCATE_OK:
    raise newException(IOError, $err)

proc openDirContext*(path: string): VfsContext =
  ## Open a VFS directory context.
  proc openDir(
      ve: VfsEnvObj; path: cstring;
      handle: var VfsHandle; arg: pointer): Opendir_result {.
    importcpp: "#->openDir(#, &#, #)", tags: [IOEffect].}

  var
    ctx = VfsContext(queue: qIdle)
    res: Opendir_result
  withLock gVfsLock:
    res = gVfsEnv.cpp.openDir(path, ctx.handle, cast[pointer](ctx))
  if res != OPENDIR_OK:
    raise newException(IOError, $res)
  assert(not ctx.handle.isNil)
  ctx

proc openFileContext*(path: string; fm: FileMode): VfsContext =
  ## Open a VFS handle context.
  type
    Result {.importcpp: "Vfs::Directory_service::Open_result", pure.} = enum
      OPEN_ERR_UNACCESSIBLE, OPEN_ERR_NO_PERM, OPEN_ERR_EXISTS
      OPEN_ERR_NAME_TOO_LONG, OPEN_ERR_NO_SPACE,
      OPEN_ERR_OUT_OF_RAM, OPEN_ERR_OUT_OF_CAPS,
      OPEN_OK
  proc openFile(
      ve: VfsEnvObj; path: cstring; mode: cuint;
      handle: var VfsHandle; arg: pointer): Result {.
    importcpp: "#->openFile(#, #, &#, #)", tags: [IOEffect].}

  var ctx = VfsContext(queue: qIdle)
  proc op(mode: cuint): Result {.gcsafe.} =
    ## Helper to retry open.
    withLock gVfsLock:
      result = gVfsEnv.cpp.openFile(path, mode, ctx.handle, cast[pointer](ctx))

  const
    RDONLY = 0
    WRONLY = 1
    RDWR = 2
    CREATE = 0x0800

  var err: Result
  block:
    case fm
    of fmRead:
      err = op(RDONLY)
    of fmWrite:
      err = op(WRONLY)
      if err == OPEN_ERR_UNACCESSIBLE:
        err = op(WRONLY or CREATE)
      else: discard
    of fmReadWrite:
      err = op(RDWR)
      if err == OPEN_ERR_UNACCESSIBLE:
        err = op(RDWR or CREATE)
    of fmReadWriteExisting:
      err = op(RDWR)
    of fmAppend:
      err = op(WRONLY)
  if err != OPEN_OK:
    raise newException(IOError, $err)
  assert(not ctx.handle.isNil)
  if fm in {fmWrite, fmReadWrite}:
    ctx.truncate(0)
  if fm in {fmRead, fmReadWrite, fmReadWriteExisting}:
    discard ctx.notifyReadReady()
  ctx

proc nim_handle_vfs_io_response(p: pointer) {.exportc.} =
  let ctx = cast[VfsContext](p)
  if (not ctx.isNil) and (not ctx.handler.isNil):
    debugEcho "got a vfs context"
    if not ctx.handler.isNil:
      let handler = ctx.handler
      reset ctx.handler # do not call handler recursively
      handler(ctx)
      #withLock gVfsLock:
      #  debugEcho "add VFS callback to resume queue"
      #  gVfsEnv.callbacks.addLast((handler, ctx))
  else:
    debugEcho "no handler set on VFS context"

#[
proc nim_resume_vfs_application() {.exportc.} =
  echo "nim_resume_vfs_application"
  var pair: AppPair
  while true:
    withLock gVfsLock:
      echo "callback queue is ", gVfsEnv.callbacks.len
      if gVfsEnv.callbacks.len < 1:
        break;
      pair = gVfsEnv.callbacks.popFirst()
    echo "call callback with context"
    pair.cb(pair.ctx)
]#

import std/asyncfutures

proc waitFor*[T](fut: Future[T]): T =
  ## **Blocks** the current thread until the specified future completes.
  var ep: Entrypoint
  withLock gVfsLock:
    ep = gVfsEnv.ep
  while not fut.finished:
    ep.waitAndDispatchOneIoSignal()
  fut.read
