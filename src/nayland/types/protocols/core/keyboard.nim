## Wrapper over `wl_keyboard`
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak@disroot.org)
import
  pkg/nayland/bindings/libwayland,
  pkg/nayland/bindings/protocols/core,
  pkg/nayland/types/protocols/core/surface

type
  KeyboardObj = object
    handle*: ptr wl_keyboard
    callbacks: KeyboardCallbacks

  KeyboardKeymapCallback* =
    proc(keyboard: Keyboard, format: uint32, fd: int32, size: uint32)
  KeyboardEnterCallback* =
    proc(keyboard: Keyboard, serial: uint32, surface: Surface, keys: seq[uint32])
  KeyboardLeaveCallback* = proc(keyboard: Keyboard, serial: uint32, surface: Surface)
  KeyboardKeyCallback* =
    proc(keyboard: Keyboard, serial: uint32, time: uint32, key: uint32, state: uint32)

  KeyboardModifiersCallback* = proc(
    keyboard: Keyboard,
    serial: uint32,
    modsDepressed: uint32,
    modsLatched: uint32,
    modsLocked: uint32,
    group: uint32,
  )
  KeyboardRepeatInfoCallback* = proc(keyboard: Keyboard, rate, delay: int32)

  KeyboardCallbacksObj = object
    keymapCb*: KeyboardKeymapCallback
    enterCb*: KeyboardEnterCallback
    leaveCb*: KeyboardLeaveCallback
    keyCb*: KeyboardKeyCallback
    modifiersCb*: KeyboardModifiersCallback
    repeatInfoCb*: KeyboardRepeatInfoCallback

    keyb*: Keyboard

  KeyboardCallbacks = ref KeyboardCallbacksObj

  Keyboard* = ref KeyboardObj

let listener = wl_keyboard_listener(
  keymap: proc(
      data: pointer, keyb: ptr wl_keyboard, fmt: uint32, fd: int32, size: uint32
  ) {.cdecl.} =
    let payload = cast[ptr KeyboardCallbacksObj](data)
    payload.keymapCb(payload.keyb, fmt, fd, size),
  enter: proc(
      data: pointer,
      keyb: ptr wl_keyboard,
      serial: uint32,
      surf: ptr wl_surface,
      keys: ptr wl_array,
  ) {.cdecl.} =
    let numKeys = int(keys.size.int / sizeof(uint32))
    let payload = cast[ptr KeyboardCallbacksObj](data)
    var keysBuff = newSeqOfCap[uint32](numKeys)

    if numKeys > 0:
      copyMem(keysBuff[0].addr, cast[ptr uint32](keys), numKeys)

    payload.enterCb(payload.keyb, serial, newSurface(surf), ensureMove(keysBuff)),
  leave: proc(
      data: pointer, keyb: ptr wl_keyboard, serial: uint32, surf: ptr wl_surface
  ) {.cdecl.} =
    let payload = cast[ptr KeyboardCallbacksObj](data)
    payload.leaveCb(payload.keyb, serial, newSurface(surf)),
  key: proc(
      data: pointer,
      keyb: ptr wl_keyboard,
      serial: uint32,
      time: uint32,
      key: uint32,
      state: uint32,
  ) {.cdecl.} =
    let payload = cast[ptr KeyboardCallbacksObj](data)
    payload.keyCb(payload.keyb, serial, time, key, state),
  modifiers: proc(
      data: pointer,
      keyb: ptr wl_keyboard,
      serial: uint32,
      modsDepressed: uint32,
      modsLatched: uint32,
      modsLocked: uint32,
      group: uint32,
  ) {.cdecl.} =
    let payload = cast[ptr KeyboardCallbacksObj](data)
    payload.modifiersCb(
      payload.keyb, serial, modsDepressed, modsLatched, modsLocked, group
    ),
  repeatInfo: proc(data: pointer, keyb: ptr wl_keyboard, rate, delay: int32) {.cdecl.} =
    let payload = cast[ptr KeyboardCallbacksObj](data)
    payload.repeatInfoCb(payload.keyb, rate, delay),
)

proc release*(keyb: Keyboard) =
  wl_keyboard_release(keyb.handle)

proc `onKeymap=`*(keyb: Keyboard, cb: KeyboardKeymapCallback) =
  keyb.callbacks.keymapCb = cb

proc `onEnter=`*(keyb: Keyboard, cb: KeyboardEnterCallback) =
  keyb.callbacks.enterCb = cb

proc `onLeave=`*(keyb: Keyboard, cb: KeyboardLeaveCallback) =
  keyb.callbacks.leaveCb = cb

proc `onKey=`*(keyb: Keyboard, cb: KeyboardKeyCallback) =
  keyb.callbacks.keyCb = cb

proc `onModifiers=`*(keyb: Keyboard, cb: KeyboardModifiersCallback) =
  keyb.callbacks.modifiersCb = cb

proc `onRepeatInfo=`*(keyb: Keyboard, cb: KeyboardRepeatInfoCallback) =
  keyb.callbacks.repeatInfoCb = cb

proc attachCallbacks*(keyb: Keyboard) =
  discard wl_keyboard_add_listener(
    keyb.handle, listener.addr, cast[ptr KeyboardCallbacksObj](keyb.callbacks)
  )

func newKeyboard*(handle: ptr wl_keyboard): Keyboard =
  Keyboard(handle: handle, callbacks: KeyboardCallbacks())
