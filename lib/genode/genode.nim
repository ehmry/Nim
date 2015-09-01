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

type
  IpcEffect* = object of RootEffect
    ## Genode interproccess communication effect

  SyncIpcEffect* = object of IpcEffect
    ## Synchronous IPC effect

  AsyncIpcEffect* = object of IpcEffect
    ## Asynchronous IPC effect
