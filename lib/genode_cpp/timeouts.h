/*
 *
 *           Nim's Runtime Library
 *       (c) Copyright 2022 Emery Hemingway
 *
 *   See the file "copying.txt", included in this
 *   distribution, for details about the copyright.
 *
 */

#ifndef _GENODE_CPP__TIMEOUTS_H_
#define _GENODE_CPP__TIMEOUTS_H_

/* Genode includes */
#include <timer_session/connection.h>

namespace Nim {

	/**
	 * Class for calling a Nim callback from a Genode timer.
	 */
	template <typename STATE>
	struct Timeout_handler
	{
		Timer::One_shot_timeout<Timeout_handler> _timeout;
		STATE                                    _state;
		void(*)(STATE, uint64_t)                 _callback;

		Timeout_handler(Timer::Connection *timer, STATE _state, void(*callback)(STATE, uint64_t))
		: _timeout(*timer, *this, &Timeout_handler::_handle_timeout)
		, _state(state), _callback(callback)
		{ }

		void _handle_timeout(Duration dur) { _callback(_state, dur.trunc_to_plain_us().value); }

		void schedule_us(uint64_t us) { schedule(Duration(Microseconds(us))); }
	};

	template <typename STATE>
	typedef Constructible<Nim::Timeout_handler<STATE>> Nim::Constructible_timeout_handler

}

#endif
