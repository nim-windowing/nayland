## Wrapper over `wl_callback`
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/libwayland, pkg/nayland/bindings/protocols/core

type
  CallbackObj = object
    handle: ptr wl_callback
    listener: wl_callback_listener

  CallbackCallback* = proc(callback: Callback, obj: pointer, callbackData: uint32)
    ## The ultimate callback. Fear it.
    ##
    ## I should probably rename this to something less nonsensical.

  CallbackPayloadObj = object
    obj*: pointer
    cb*: CallbackCallback

  CallbackPayload* = ref CallbackPayloadObj

  Callback* = ref CallbackObj

proc listen*(callback: Callback, obj: pointer, cb: CallbackCallback) =
  callback.listener.done = proc(
      data: pointer, cb: ptr wl_callback, cbdata: uint32
  ) {.cdecl.} =
    let payload = cast[ptr CallbackPayloadObj](data)
    payload.cb(Callback(handle: cb), payload.obj, cbdata)

  let payload = CallbackPayload(obj: obj, cb: cb)
  discard wl_callback_add_listener(
    callback.handle, callback.listener.addr, cast[ptr CallbackPayloadObj](payload)
  )

proc destroy*(callback: Callback) =
  wl_callback_destroy(callback.handle)

func newCallback*(handle: ptr wl_callback): Callback =
  Callback(handle: handle)
