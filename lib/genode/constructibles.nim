type Constructible*[T] {.
  importcpp: "Genode::Constructible",
  header: "<util/reconstructible.h>", byref, pure.} = object

proc construct*[T](x: Constructible[T]) {.importcpp.}
  ## Construct a constructible C++ object.

proc destruct*[T](x: Constructible[T]) {.importcpp.}
  ## Destruct a constructible C++ object.
