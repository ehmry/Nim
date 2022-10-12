type
  EntrypointObj {.
    importcpp: "Genode::Entrypoint",
    header: "<base/entrypoint.h>",
    pure.} = object
  Entrypoint* = ptr EntrypointObj
    ## Opaque Entrypoint object.

proc ep*(env: GenodeEnvPtr): Entrypoint {.
  importcpp: "(&#->ep())".}

proc wait_and_dispatch_one_io_signal*(ep: Entrypoint) {.importcpp.}

proc dispatch_pending_io_signal*(ep: Entrypoint): bool {.importcpp.}
