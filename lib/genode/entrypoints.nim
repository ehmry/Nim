type
  EntrypointObj {.
    importcpp: "Genode::Entrypoint",
    header: "<base/entrypoint.h>",
    pure.} = object
  Entrypoint* = ptr EntrypointObj
    ## Opaque Entrypoint object.

proc ep*(env: GenodeEnvPtr): Entrypoint {.
  importcpp: "(&#->ep())".}
