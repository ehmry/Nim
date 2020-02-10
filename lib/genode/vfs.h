/*
 *
 *           Nim's Runtime Library
 *       (c) Copyright 2018 Emery Hemingway
 *
 *   See the file "copying.txt", included in this
 *   distribution, for details about the copyright.
 *
 */

#ifndef _GENODE_CPP__VFS_H_
#define _GENODE_CPP__VFS_H_

#include <base/debug.h>

/* Genode includes */
#include <vfs/simple_env.h>
#include <base/heap.h>
#include <base/attached_rom_dataspace.h>
#include <libc/component.h>

extern "C" void nim_handle_vfs_io_response(void*);
extern "C" void nim_resume_vfs_application();

namespace Nim {
	class VfsContext;
	class VfsEnv;
}


class Nim::VfsContext : public Vfs::Io_response_handler
{
	/**
	 * Respond to a resource becoming readable
	 */
	void read_ready_response() override {
		PDBG("Nim runtime receives read_ready_response"); }

	/**
	 * Respond to complete pending I/O
	 */
	void io_progress_response() override {
		PDBG("Nim runtime receives io_progress_response"); }
};


class Nim::VfsEnv : public Vfs::Env
{
	/*
	 * TODO: wrap the Nim heap into a Genode::Allocator
	 */

	private:

		Genode::Env  &_env;
		Genode::Heap _heap { _env.pd(), _env.rm() };

		Vfs::Global_file_system_factory _fs_factory { _heap };

		Genode::Attached_rom_dataspace _config_rom { _env, "config" };

		Vfs::Dir_file_system _root_dir;

		Genode::Xml_node _vfs_config() const
		{
			try {
				return _config_rom.xml().sub_node("vfs");
			} catch (...) {
				return Genode::Xml_node("<vfs/>");
			}
		}

	public:

		VfsEnv(Genode::Env *env)
		:
			_env(*env),
			_root_dir(*this, _vfs_config(), _fs_factory)
		{ }

		void apply_config(Genode::Xml_node const &config)
		{
			_root_dir.apply_config(config);
		}

		Genode::Env       &env()       override { return _env; }
		Genode::Allocator &alloc()     override { return _heap; }
		Vfs::File_system  &root_dir()  override { return _root_dir; }

		Vfs::Directory_service::Opendir_result
		openDir(char const *path, bool create, Vfs::Vfs_handle **handle)
		{
			auto res = _root_dir.opendir(path, create, handle, _heap);
			//if (*handle)
			//	(*handle)->context = arg;
			return res;
		}

		Vfs::Directory_service::Open_result
		openFile(char const *path, unsigned mode, Vfs::Vfs_handle **handle, void *arg)
		{
			auto res = _root_dir.open(path, mode, handle, _heap);
			//if (*handle)
			//	(*handle)->context = arg;
			return res;
		}


};

#endif
