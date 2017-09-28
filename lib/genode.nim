#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when not defined(genode) or defined(nimdoc):
  {.error: "Genode only module".}

#
# Signals
#

type SignalContextCapability* {.
  importcpp: "Genode::Signal_context_capability",
  header: "<base/signal.h>", final, pure.} = object
  ## Capability to an asynchronous signal context.
