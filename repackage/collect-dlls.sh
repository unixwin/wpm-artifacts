#!/usr/bin/env bash
# 从 MSYS2 sysroot(/mingw64/bin)收集 dist 内 exe 所需的非系统 DLL,复制到 dist。
# 用法: bash collect-dlls.sh <dist-dir>
set -euo pipefail

DIST="${1:?usage: collect-dlls.sh <dist-dir>}"
SYSROOT="${MINGW_PREFIX:-/mingw64}/bin"

SYSTEM_DLLS='^(kernel32|user32|advapi32|ws2_32|wsock32|ntdll|shell32|ole32|oleaut32|gdi32|comdlg32|winmm|imm32|version|shlwapi|uuid|iphlpapi|psapi|userenv|crypt32|secur32|dnsapi|wintrust|setupapi|rpcrt4|normaliz|bcrypt|ncrypt|cfgmgr32|powrprof|dbghelp|msvcrt|ucrtbase)\.dll$'

collect_one() {
  local exe="$1"
  for dll in $(objdump -p "$exe" | awk '/DLL Name/{print $3}'); do
    low=$(echo "$dll" | tr '[:upper:]' '[:lower:]')
    echo "$low" | grep -qiE "$SYSTEM_DLLS" && continue
    [ -f "$DIST/$dll" ] && { collect_one "$DIST/$dll"; continue; }
    if [ -f "$SYSROOT/$dll" ]; then
      cp "$SYSROOT/$dll" "$DIST/"
      echo "collected: $dll"
      collect_one "$DIST/$dll"
    else
      echo "WARN: $dll not found in $SYSROOT" >&2
    fi
  done
}

shopt -s nullglob
for exe in "$DIST"/*.exe; do
  collect_one "$exe"
done
echo "done"