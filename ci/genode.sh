#
# Simple Genode CI Bash script
#
set -e

nim c koch
./koch boot

# Check if things build, but skip the C compilation and linking
nim c --os:genode -d:posix --compileOnly --taintMode:on -d:nimCoroutines tests/testament/tester
