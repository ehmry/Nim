/*
 *
 *           Nim's Runtime Library
 *       (c) Copyright 2017 Emery Hemingway
 *
 *   See the file "copying.txt", included in this
 *   distribution, for details about the copyright.
 *
 */


#ifndef _GENODE_CPP__SIGNALS_H_
#define _GENODE_CPP__SIGNALS_H_

#include <libc/component.h>
#include <base/signal.h>
#include <util/reconstructible.h>

extern "C" void nimHandleSignal(void *arg);
extern "C" int dispatchSuspend(void *arg);

struct SignalDispatcher
{
	struct _Dispatcher : Genode::Signal_dispatcher_base
	{
		void *arg;

		void dispatch(unsigned num) override {
			nimHandleSignal(arg); }

		_Dispatcher(void *arg) : arg(arg) {
			 Genode::Signal_context::_level = Genode::Signal_context::Level::Io; }
	};

	Genode::Constructible<_Dispatcher> _dispatcher;
	Genode::Entrypoint                 *entrypoint;
	Genode::Signal_context_capability   cap;

	void initSignalDispatcher(Genode::Entrypoint *ep, void *arg)
	{
		_dispatcher.construct(arg);
		entrypoint = ep;
		cap = entrypoint->manage(*_dispatcher);
	}

	void deinitSignalDispatcher()
	{
		entrypoint->dissolve(*_dispatcher);
		_dispatcher.destruct();
	}
};


struct DispatchSuspendFunctor : Libc::Suspend_functor
{
	void *arg;

	bool suspend() override {
		return dispatchSuspend(arg); }
};

#endif
