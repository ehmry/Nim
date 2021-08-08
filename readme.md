# Nim - Plan 9 Edition

Building and testing Nim programs on Plan 9 requires a Linux
and Plan 9 host with a shared file-system, and SSH access from
Plan 9 to Linux.

My personal setup is a Linux box with its root exported by 9P
(u9fs) and a common directory in /usr that I bind into Plan 9
namespace.

```
#!/bin/rc
9fs linuxhost
bind -c /n/linuxhost/usr/common /usr/common
```

Now the Linux and Plan 9 namespace share `/usr/common`.
Checkout these sources into `/usr/common` and bootstrap the Linux
compiler:
```
#!/bin/rc
ssh linuxhost nim c /usr/common/nim/koch
ssh linuxhost 'cd /usr/common/nim/; ./koch boot'
```

Bootstrap the [json_to_mk](./tools/json_to_mk.nim) tool:
```
#!/bin/rc
ssh linuxhost /usr/common/nim/bin/nim c /usr/common/nim/tools/json_to_mk
ssh linuxhost /usr/common/nim/bin/nim c \
	--os:plan9 --compileOnly \
	--nimcache:/usr/common/tmp/nimcache/json_to_mk \
	-o:/usr/common/bin/json_to_mk \
	/usr/common/nim/tools/json_to_mk.nim

ssh linuxhost /usr/common/nim/tools/json_to_mk \
	/usr/common/tmp/nimcache/json_to_mk/json_to_mk.json

# Build the utility natively
mk -f /usr/common/tmp/nimcache/json_to_mk/mkfile

# Check that it works
mv /usr/common/tmp/nimcache/json_to_mk/mkfile /usr/common/tmp/nimcache/json_to_mk/mkfile.linux
/usr/common/bin/json_to_mk /usr/common/tmp/nimcache/json_to_mk/json_to_mk.json
cmp /usr/common/tmp/nimcache/json_to_mk/mkfile /usr/common/tmp/nimcache/json_to_mk/mkfile.linux
```

Hopefully you now have a Plan 9 native `json_to_mk` program.
```
#!/bin/rc
# Compile a test
ssh linuxhost /usr/common/nim/bin/nim c \
	--os:plan9 --compileOnly \
	-d:useMalloc \
	--nimcache:/usr/common/tmp/nimcache/tlists \
	-o:/usr/common/bin/tlists \
	/usr/common/nim/tests/gc/tlists.nim

# Build the test
/usr/common/bin/json_to_mk \
	/usr/common/tmp/nimcache/tlists/tlists.json
mk -a -f /usr/common/tmp/nimcache/tlists/mkfile

# Run the test
/usr/common/bin/tlists
```
