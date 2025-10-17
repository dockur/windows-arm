#!/usr/bin/env bash
set -Eeuo pipefail

: "${APP:="Windows"}"
: "${MACHINE:="virt"}"
: "${PLATFORM:="arm64"}"
: "${BOOT_MODE:="windows"}"
: "${SUPPORT:="https://github.com/dockur/windows-arm"}"

cd /run

. start.sh      # Startup hook
. utils.sh      # Load functions
. reset.sh      # Initialize system
. server.sh     # Start webserver
. define.sh     # Define versions
. mido.sh       # Download Windows
. install.sh    # Run installation
. disk.sh       # Initialize disks
. display.sh    # Initialize graphics
. network.sh    # Initialize network
. samba.sh      # Configure samba
. boot.sh       # Configure boot
. proc.sh       # Initialize processor
. power.sh      # Configure shutdown
. memory.sh     # Check available memory
. config.sh     # Configure arguments
. finish.sh     # Finish initialization

trap - ERR

version=$(qemu-system-aarch64 --version | head -n 1 | cut -d '(' -f 1 | awk '{ print $NF }')
info "Booting ${APP}${BOOT_DESC} using QEMU v$version..."

if [ -z "$CPU_PIN" ]; then
  { qemu-system-aarch64 ${ARGS:+ $ARGS} >"$QEMU_OUT" 2>"$QEMU_LOG"; rc=$?; } || :
else
  { taskset -c "$CPU_PIN" qemu-system-aarch64 ${ARGS:+ $ARGS} >"$QEMU_OUT" 2>"$QEMU_LOG"; rc=$?; } || :
fi

(( rc != 0 )) && error "$(<"$QEMU_LOG")" && exit 15

terminal
( sleep 30; boot ) &
tail -fn +0 "$QEMU_LOG" --pid=$$ 2>/dev/null &
cat "$QEMU_TERM" 2> /dev/null | tee "$QEMU_PTY" | \
sed -u -e 's/\x1B\[[=0-9;]*[a-z]//gi' \
-e 's/failed to load Boot/skipped Boot/g' \
-e 's/0): Not Found/0)/g' & wait $! || :

sleep 1 & wait $!
[ ! -f "$QEMU_END" ] && finish 0
