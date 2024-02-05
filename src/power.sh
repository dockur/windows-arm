#!/usr/bin/env bash
set -Eeuo pipefail

# Configure QEMU for graceful shutdown

QEMU_TERM=""
QEMU_PORT=7100
QEMU_TIMEOUT=110
QEMU_PID="/run/shm/qemu.pid"
QEMU_PTY="/run/shm/qemu.pty"
QEMU_LOG="/run/shm/qemu.log"
QEMU_OUT="/run/shm/qemu.out"
QEMU_END="/run/shm/qemu.end"

BOOT_LINE="Windows Boot Manager"

rm -f /run/shm/qemu.*
touch "$QEMU_LOG"

_trap() {
  func="$1" ; shift
  for sig ; do
    trap "$func $sig" "$sig"
  done
}

finish() {

  local pid
  local reason=$1

  if [ -f "$QEMU_PID" ]; then

    pid=$(<"$QEMU_PID")
    error "Forcefully terminating Windows, reason: $reason..."
    { kill -15 "$pid" || true; } 2>/dev/null

    while isAlive "$pid"; do
      sleep 1
      # Workaround for zombie pid
      [ ! -f "$QEMU_PID" ] && break
    done
  fi

  if [ -f "$STORAGE/$BASE" ] && [ ! -f "$STORAGE/windows.boot" ]; then
    if [ -f "$QEMU_PTY" ]; then
      if grep -Fq "$BOOT_LINE" "$QEMU_PTY"; then
        rm -f "$STORAGE/$BASE"
        touch "$STORAGE/windows.boot"
      fi
    fi
  fi

  pid="/var/run/tpm.pid"
  [ -f "$pid" ] && pKill "$(<"$pid")"

  closeNetwork

  sleep 0.5
  echo "❯ Shutdown completed!"

  exit "$reason"
}

terminal() {

  local dev=""

  if [ -f "$QEMU_OUT" ]; then

    local msg
    msg=$(<"$QEMU_OUT")

    if [ -n "$msg" ]; then

      if [[ "${msg,,}" != "char"* ||  "$msg" != *"serial0)" ]]; then
        echo "$msg"
      fi

      dev="${msg#*/dev/p}"
      dev="/dev/p${dev%% *}"

    fi
  fi

  if [ ! -c "$dev" ]; then
    dev=$(echo 'info chardev' | nc -q 1 -w 1 localhost "$QEMU_PORT" | tr -d '\000')
    dev="${dev#*serial0}"
    dev="${dev#*pty:}"
    dev="${dev%%$'\n'*}"
    dev="${dev%%$'\r'*}"
  fi

  if [ ! -c "$dev" ]; then
    error "Device '$dev' not found!"
    finish 34 && return 34
  fi

  QEMU_TERM="$dev"
  return 0
}

_graceful_shutdown() {

  local code=$?

  set +e

  if [ -f "$QEMU_END" ]; then
    info "Received $1 while already shutting down..."
    return
  fi

  touch "$QEMU_END"
  info "Received $1, sending ACPI shutdown signal..."

  if [ ! -f "$QEMU_PID" ]; then
    error "QEMU PID file does not exist?"
    finish "$code" && return "$code"
  fi

  local pid=""
  pid=$(<"$QEMU_PID")

  if ! isAlive "$pid"; then
    error "QEMU process does not exist?"
    finish "$code" && return "$code"
  fi

  local abort="Cannot send ACPI signal during Windows setup, aborting..."

  if [ -f "$QEMU_PTY" ] && [ ! -f "$STORAGE/windows.boot" ]; then
    if ! grep -Fq "$BOOT_LINE" "$QEMU_PTY"; then
      info "$abort" && finish "$code" && return "$code"
    fi
  fi

  # Send ACPI shutdown signal
  echo 'system_powerdown' | nc -q 1 -w 1 localhost "${QEMU_PORT}" > /dev/null

  local cnt=0
  while [ "$cnt" -lt "$QEMU_TIMEOUT" ]; do

    sleep 1
    cnt=$((cnt+1))

    ! isAlive "$pid" && break
    # Workaround for zombie pid
    [ ! -f "$QEMU_PID" ] && break

    info "Waiting for Windows to shutdown... ($cnt/$QEMU_TIMEOUT)"

    # Send ACPI shutdown signal
    echo 'system_powerdown' | nc -q 1 -w 1 localhost "${QEMU_PORT}" > /dev/null

  done

  if [ "$cnt" -ge "$QEMU_TIMEOUT" ]; then
    error "Shutdown timeout reached, aborting..."
  fi

  finish "$code" && return "$code"
}

SERIAL="pty"
MONITOR="telnet:localhost:$QEMU_PORT,server,nowait,nodelay"
MONITOR="$MONITOR -daemonize -D $QEMU_LOG -pidfile $QEMU_PID"

_trap _graceful_shutdown SIGTERM SIGHUP SIGINT SIGABRT SIGQUIT

return 0
