## Wrapper over `wl_callback`
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/libwayland, pkg/nayland/bindings/protocols/core

type
  CallbackObj = object
    handle: ptr wl_callback

  CallbackCallback* =
    proc(callback: Callback, obj: pointer, callbackData: uint32) {.cdecl.}
    ## The ultimate callback. Fear it.
    ##
    ## I should probably rename this to something less nonsensical.

  CallbackPayloadObj = object
    obj*: pointer
    cbObj*: ptr CallbackObj
    cb*: CallbackCallback

  CallbackPayload* = ref CallbackPayloadObj

  Callback* = ref CallbackObj

let listener = wl_callback_listener(
  done: proc(data: pointer, cb: ptr wl_callback, cbdata: uint32) {.cdecl.} =
    let payload = cast[ptr CallbackPayloadObj](data)
    payload.cb(cast[Callback](payload.cbObj), payload.obj, cbdata)
)

proc listen*(callback: Callback, obj: pointer, cb: CallbackCallback) =
  # what in the world is this....
  let payload = cast[ptr CallbackPayloadObj](alloc(sizeof(CallbackPayloadObj)))

  payload.cb = cb
  payload.cbObj = cast[ptr CallbackObj](callback)
  payload.obj = obj

  discard wl_callback_add_listener(callback.handle, listener.addr, payload)

proc destroy*(callback: Callback) =
  wl_callback_destroy(callback.handle)

func newCallback*(handle: ptr wl_callback): Callback =
  Callback(handle: handle)
