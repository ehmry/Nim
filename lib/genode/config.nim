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

import xmlparser, xmltree

include genode/env

const romHeader = "<rom_session/connection.h>"

type
  RomConnection {.importcpp: "Genode::Rom_connection", header: romHeader, pure.} = object
  RomDataspaceCapability* {.
    importcpp: "Genode::Rom_dataspace_capability", header: romHeader.} = object

proc initRom(env: GenodeEnvObj; label: cstring): RomConnection {.
      importcpp: "Genode::Rom_connection(*#, #)", constructor.}

proc dataspace(c: RomConnection): RomDataspaceCapability {.importcpp.}
  ## Return the current dataspace capability from the ROM server.

proc attach(env: GenodeEnvPtr; ds: RomDataspaceCapability): pointer {.
  importcpp: "#->rm().attach(@)".}
  ## Attach a dataspace into the component address-space.

proc detach(env: GenodeEnvPtr; p: pointer) {.
  importcpp: "#->rm().detach(@)".}
  ## Detach a dataspace from the component address-space.

when not defined(nimscript):
  proc parseConfigRom*(): XmlNode =
    let
      rom = initRom(runtimeEnv.toObj, "nim -> config")
      ds = rom.dataspace
      data = runtimeEnv.attach(ds)
      config = cast[cstring](data)
    try:
      result = parseXml($config)
    except:
      result = <>config()
    runtimeEnv.detach(data)
