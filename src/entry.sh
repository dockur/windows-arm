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
. balloon.sh    # Initialize ballooning
. config.sh     # Configure arguments
. finish.sh     # Finish initialization

trap - ERR

version=$(qemu-system-aarch64 --version | head -n 1 | cut -d '(' -f 1 | awk '{ print $NF }')
info "Booting ${APP}${BOOT_DESC} using QEMU v$version..."

if [[ "$SHUTDOWN" != [Yy1]* ]]; then
  if [ -z "$CPU_PIN" ]; then
    exec qemu-system-aarch64 ${ARGS:+ $ARGS}
  else    
    exec taskset -c "$CPU_PIN" qemu-system-aarch64 ${ARGS:+ $ARGS}
  fi
fi

qemu() {
  if [ -z "$CPU_PIN" ]; then
    qemu-system-aarch64 ${ARGS:+ $ARGS} > >(
        tee "$QEMU_PTY" | \
        sed -u \
        -e 's/\x1B\[[=0-9;]*[a-z]//gi' \
        -e 's/\x1B\x63//g' \
        -e 's/\x1B\[[=?]7l//g' \
        -e '/^$/d' \
        -e 's/\x44\x53\x73//g' \
        -e 's/failed to load Boot/skipped Boot/g' \
        -e 's/0): Not Found/0)/g' ) &
  else    
    taskset -c "$CPU_PIN" qemu-system-aarch64 ${ARGS:+ $ARGS} > >(
        tee "$QEMU_PTY" | \
        sed -u \
        -e 's/\x1B\[[=0-9;]*[a-z]//gi' \
        -e 's/\x1B\x63//g' \
        -e 's/\x1B\[[=?]7l//g' \
        -e '/^$/d' \
        -e 's/\x44\x53\x73//g' \
        -e 's/failed to load Boot/skipped Boot/g' \
        -e 's/0): Not Found/0)/g' ) &
  fi
}

if [ ! -t 1 ] || [ ! -c /dev/tty ]; then
    qemu &
else
    qemu </dev/tty >/dev/tty &
fi

pid=$!
( sleep 30; boot ) &

rc=0
wait "$pid" || rc=$?
[ -f "$QEMU_END" ] && exit "$rc"

sleep 1 & wait $!
finish "$rc"
