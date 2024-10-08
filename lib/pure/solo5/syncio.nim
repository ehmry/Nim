## Solo5 glue.
# (c) 2024 Emery Heminyway

import ../solo5

type File* = object
const console = File()
proc stdmsg*: File = console

proc writeLine*[Ty](f: File, x: varargs[Ty, `$`]) {.inline, tags: [WriteIOEffect].} =
  ## Write a line of text to a file, but only if that file is `stdmsg()`.
  if f == console:
    for s in items(x):
      solo5_console_write(s.cstring, s.len.csize_t)
    solo5_console_write("\n")
