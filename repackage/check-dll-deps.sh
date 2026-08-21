#!/usr/bin/env bash
# 校验目录内所有 exe 的非系统 DLL 依赖是否齐备(防 socat 式缺 DLL)。
# 用法: bash check-dll-deps.sh <dir>
set -euo pipefail

DIR="${1:?usage: check-dll-deps.sh <dir>}"
DIR=$(cd "$DIR" && pwd)

SYSTEM_DLLS='^(kernel32|user32|advapi32|ws2_32|wsock32|ntdll|shell32|ole32|oleaut32|gdi32|comdlg32|winmm|imm32|version|shlwapi|uuid|iphlpapi|psapi|userenv|crypt32|secur32|dnsapi|wintrust|setupapi|rpcrt4|normaliz|bcrypt|ncrypt|cfgmgr32|powrprof|dbghelp|msvcrt|ucrtbase|ntmarta|windowscodecs|winusb|hid|wbemuuid|fwpuclnt|rasadhlp|mlang|usp10|dwmapi|uxtheme|propsys|apphelp|cryptbase|sspicli|msimg32|winspool\.drv)\.(dll|DRV)$'

fail=0
for exe in "$DIR"/*.exe; do
  [ -e "$exe" ] && break || true
done
shopt -s nullglob
exes=("$DIR"/*.exe)
if [ ${#exes[@]} -eq 0 ]; then
  echo "no exe files in $DIR" >&2
  exit 1
fi

declare -A seen
while :; do
  new=0
  for exe in "${!seen[@]}" "${exes[@]}"; do
    [ -n "${seen[$exe]:-}" ] && continue
    seen[$exe]=1
    new=1
    echo "== $(basename "$exe") =="
    for dll in $(objdump -p "$exe" | awk '/DLL Name/{print $3}'); do
      low=$(echo "$dll" | tr '[:upper:]' '[:lower:]')
      if echo "$low" | grep -qiE "$SYSTEM_DLLS"; then
        continue
      fi
      if [ ! -f "$DIR/$dll" ]; then
        # 大小写不敏感再找一次
        found=$(find "$DIR" -maxdepth 1 -iname "$dll" -print -quit || true)
        if [ -z "$found" ]; then
          echo "MISSING: $dll (required by $(basename "$exe"))"
          fail=1
          continue
        fi
      fi
      # DLL 自身也可能依赖其他 DLL,纳入检查队列
      if [ -f "$DIR/$dll" ] && [ -z "${seen["$DIR/$dll"]:-}" ]; then
        exes+=("$DIR/$dll")
      fi
    done
  done
  [ "$new" -eq 1 ] || break
done

if [ "$fail" -ne 0 ]; then
  echo "FAILED: missing DLL dependencies" >&2
  exit 1
fi
echo "OK: all non-system DLL dependencies present in $DIR"