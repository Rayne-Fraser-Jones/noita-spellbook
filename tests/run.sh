#!/bin/sh
# Runs every test against the stand-in Noita API. Needs LuaJIT.
# Usage (from the mod folder): sh tests/run.sh
cd "$(dirname "$0")/.." || exit 1
failed=0
for t in tests/*.lua; do
	case "$t" in tests/stubs.lua|tests/helpers.lua) continue ;; esac
	out=$(luajit "$t" 2>&1)
	if [ $? -eq 0 ]; then
		echo "pass  $t"
	else
		echo "FAIL  $t"
		echo "$out" | grep -E "FAIL|error|attempt" | head -3 | sed 's/^/      /'
		failed=1
	fi
done
exit $failed
