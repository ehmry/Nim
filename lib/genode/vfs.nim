#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

const vfsHeader = "<vfs/file_system.h>"

type
  Stat* {.importcpp: "Vfs::Directory_service::Stat", header: vfsHeader, final, pure.}
