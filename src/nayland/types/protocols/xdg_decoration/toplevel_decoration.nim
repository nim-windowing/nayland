## Wrapper around `zxdg_toplevel_decoration_v1`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/xdg_decoration_unstable_v1

type
  XDGToplevelDecorationObj = object
    handle*: ptr zxdg_toplevel_decoration_v1
    payload: ConfigureCallbackPayload

  XDGToplevelDecorationMode* {.pure, size: sizeof(uint32).} = enum
    ClientSide =
      zxdg_toplevel_decoration_v1_mode.ZXDG_TOPLEVEL_DECORATION_V1_MODE_CLIENT_SIDE
    ServerSide =
      zxdg_toplevel_decoration_v1_mode.ZXDG_TOPLEVEL_DECORATION_V1_MODE_SERVER_SIDE

  ConfigureCallback* =
    proc(decor: XDGToplevelDecoration, mode: XDGToplevelDecorationMode)

  ConfigureCallbackPObj = object
    decor: XDGToplevelDecoration
    confCb: ConfigureCallback

  ConfigureCallbackPayload = ref ConfigureCallbackPObj

  XDGToplevelDecoration* = ref XDGToplevelDecorationObj

let listener = zxdg_toplevel_decoration_v1_listener(
  configure: proc(
      data: pointer, decor: ptr zxdg_toplevel_decoration_v1, mode: uint32
  ) {.cdecl.} =
    let payload = cast[ptr ConfigureCallbackPObj](data)
    payload.confCb(payload.decor, cast[XDGToplevelDecorationMode](mode))
)

proc `=destroy`*(decor: XDGToplevelDecorationObj) =
  zxdg_toplevel_decoration_v1_destroy(decor.handle)

proc setMode*(decor: XDGToplevelDecoration, mode: XDGToplevelDecorationMode) =
  zxdg_toplevel_decoration_v1_set_mode(decor.handle, cast[uint32](mode))

proc version*(decor: XDGToplevelDecoration): uint32 =
  zxdg_toplevel_decoration_v1_get_version(decor.handle)

proc unsetMode*(decor: XDGToplevelDecoration) =
  zxdg_toplevel_decoration_v1_unset_mode(decor.handle)

proc `onConfigure=`*(decor: XDGToplevelDecoration, cb: ConfigureCallback) =
  decor.payload.confCb = cb

proc attachCallbacks*(decor: XDGToplevelDecoration) =
  decor.payload.decor = decor
  discard zxdg_toplevel_decoration_v1_add_listener(
    decor.handle, listener.addr, cast[ptr XDGToplevelDecorationObj](decor.payload)
  )

func newXDGToplevelDecoration*(
    handle: ptr zxdg_toplevel_decoration_v1
): XDGToplevelDecoration =
  XDGToplevelDecoration(handle: handle, payload: ConfigureCallbackPayload())
