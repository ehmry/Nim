import ./entrypoints, ./constructibles

type SignalContextCapability* {.
  importcpp: "Genode::Signal_context_capability",
  header: "<base/signal.h>", pure.} = object
  ## Capability to an asynchronous signal context.

proc isValid*(cap: SignalContextCapability): bool {.
  importcpp: "#.valid()", tags: [IOEffect].}

{.emit: """
#include <libc/component.h>
#include <base/signal.h>
#include <util/reconstructible.h>

/* Symbol for calling back into Nim */
extern "C" void nimHandleSignal(void *arg);

namespace Nim { struct SignalDispatcher; }

struct Nim::SignalDispatcher
{
	/**
	 * Pointer to a Nim type
	 */
	void *arg;

	/**
	 * Call Nim with dispatcher argument
	 */
	void handle_signal() {
		Libc::with_libc([this] () { nimHandleSignal(arg); }); }

	Genode::Signal_handler<SignalDispatcher> handler;

	SignalDispatcher(Genode::Entrypoint *ep, void *arg)
	: arg(arg), handler(*ep, *this, &SignalDispatcher::handle_signal) { }

	Genode::Signal_context_capability cap() {
		return handler; }
};

""".}


type
  HandlerProc = proc () {.closure, gcsafe.}

  SignalDispatcherBase {.
    importcpp: "Nim::SignalDispatcher", pure.} = object

  SignalDispatcherCpp = Constructible[SignalDispatcherBase]

  SignalDispatcherObj = object
    cpp: SignalDispatcherCpp
    cb: HandlerProc
      ## Signal handling procedure called during dispatch.

  SignalHandler* = ref SignalDispatcherObj
    ## Nim object enclosing a Genode signal handler.

{.deprecated: [SignalDispatcher: SignalHandler].}

proc construct(cpp: SignalDispatcherCpp; ep: Entrypoint; sh: SignalHandler) {.importcpp.}

proc cap(cpp: SignalDispatcherCpp): SignalContextCapability {.
    importcpp: "#->cap()".}

proc newSignalHandler*(ep: Entrypoint; cb: HandlerProc): SignalHandler =
  ## Create a new signal handler. A label is recommended for
  ## debugging purposes. A signal handler will not be garbage
  ## collected until after it has been dissolved.
  assert(not cb.isNil)
  result = SignalHandler(cb: cb)
  result.cpp.construct(ep, result)
  GCref result
  assert(not result.cb.isNil)

proc dissolve*(sig: SignalHandler) =
  ## Dissolve signal dispatcher from entrypoint.
  destruct sig.cpp
  GCunref sig

proc cap*(sig: SignalHandler): SignalContextCapability =
  ## Signal context capability. Can be delegated to external components.
  assert(not sig.cb.isNil)
  sig.cpp.cap

proc nimHandleSignal(p: pointer) {.exportc.} =
  ## C symbol invoked by entrypoint during signal dispatch.
  let dispatch = cast[SignalDispatcher](p)
  doAssert(not dispatch.cb.isNil)
  dispatch.cb()
