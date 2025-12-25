## Wrapper over `xdg_toplevel`
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/libwayland, pkg/nayland/bindings/protocols/xdg_shell
import
  pkg/nayland/types/protocols/core/surface,
  pkg/nayland/types/protocols/xdg_shell/[xdg_surface]

type
  XDGToplevelObj = object
    handle*: ptr xdg_toplevel

    payload: ToplevelCallbacksPayload

  XDGToplevelConfigureCallback* = proc(toplevel: XDGToplevel, width, height: int32)
  XDGToplevelCloseCallback* = proc(toplevel: XDGToplevel)

  ToplevelCallbacksPObj = object
    obj*: XDGToplevel
    configureCb*: XDGToplevelConfigureCallback
    closeCb*: XDGToplevelCloseCallback

  ToplevelCallbacksPayload = ref ToplevelCallbacksPObj

  XDGToplevel* = ref XDGToplevelObj

let listener = xdg_toplevel_listener(
  configure: proc(
      data: pointer,
      toplevel: ptr xdg_toplevel,
      width, height: int32,
      states: ptr wl_array,
  ) {.cdecl.} =
    let payload = cast[ptr ToplevelCallbacksPObj](data)
    payload.configureCb(payload.obj, width, height),
  close: proc(data: pointer, toplevel: ptr xdg_toplevel) {.cdecl.} =
    let payload = cast[ptr ToplevelCallbacksPObj](data)
    payload.closeCb(payload.obj),
  configure_bounds: proc(
      data: pointer, toplevel: ptr xdg_toplevel, width, height: int32
  ) {.cdecl.} =
    discard,
  wm_capabilities: proc(
      data: pointer, toplevel: ptr xdg_toplevel, capabilities: ptr wl_array
  ) {.cdecl.} =
    discard,
)

proc `onConfigure=`*(toplevel: XDGToplevel, callback: XDGToplevelConfigureCallback) =
  toplevel.payload.configureCb = callback

proc `onClose=`*(toplevel: XDGToplevel, callback: XDGToplevelCloseCallback) =
  toplevel.payload.closeCb = callback

proc attachCallbacks*(toplevel: XDGToplevel) =
  discard xdg_toplevel_add_listener(
    toplevel.handle, listener.addr, cast[ptr ToplevelCallbacksPObj](toplevel.payload)
  )

proc `title=`*(toplevel: XDGToplevel, title: string) =
  xdg_toplevel_set_title(toplevel.handle, title)

proc `appId=`*(toplevel: XDGToplevel, appId: string) =
  xdg_toplevel_set_app_id(toplevel.handle, appId)

#[ proc `fullscreen=`*(toplevel: XDGToplevel, state: bool) =
  if state:
    xdg_toplevel_set_fullscreen(toplevel.handle)
  else:
    xdg_toplevel_unset_fullscreen(toplevel.handle) ]#

proc minimize*(toplevel: XDGToplevel) =
  xdg_toplevel_set_minimized(toplevel.handle)

proc maximize*(toplevel: XDGToplevel) =
  xdg_toplevel_set_maximized(toplevel.handle)

func newXDGToplevel*(handle: ptr xdg_toplevel): XDGToplevel =
  XDGToplevel(handle: handle, payload: ToplevelCallbacksPayload())
