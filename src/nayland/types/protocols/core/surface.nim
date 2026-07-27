## Wrapper around `wl_surface`
##
## Copyright (C) 2025-2026 Trayambak Rai (xtrayambak@disroot.org)

#!fmt: off
import pkg/nayland/bindings/libwayland,
       pkg/nayland/bindings/protocols/core,
       pkg/nayland/types/protocols/core/[buffer, callback, output]
#!fmt: on

type
  SurfaceEnterCallback* = proc(surface: Surface, output: Output)
  SurfaceLeaveCallback* = proc(surface: Surface, output: Output)
  SurfacePreferredBufferScaleCallback* = proc(surface: Surface, factor: int32)
  SurfacePreferredBufferTransformCallback* =
    proc(surface: Surface, transform: OutputTransform)

  SurfaceCallbackPObj = object
    enterCb: SurfaceEnterCallback
    leaveCb: SurfaceLeaveCallback
    preferredBufferScaleCb: SurfacePreferredBufferScaleCallback
    preferredBufferTransformCb: SurfacePreferredBufferTransformCallback

  SurfaceCallbackPayload = ref SurfaceCallbackPObj

  SurfaceObj = object
    handle*: ptr wl_surface
    payload: SurfaceCallbackPayload

  Surface* = ref SurfaceObj

proc destroy*(surface: Surface) =
  wl_surface_destroy(surface.handle)

proc damage*(surface: Surface, x, y, w, h: int32) =
  wl_surface_damage(surface.handle, x, y, w, h)

proc commit*(surface: Surface) =
  wl_surface_commit(surface.handle)

proc attach*(surface: Surface, buffer: Buffer, x, y: int32) =
  wl_surface_attach(surface.handle, buffer.handle, x, y)

proc frame*(surface: Surface): Callback =
  newCallback(wl_surface_frame(surface.handle))

proc setBufferScale*(surface: Surface, scale: int32) =
  wl_surface_set_buffer_scale(surface.handle, scale)

proc setBufferTransform*(surface: Surface, transform: OutputTransform) =
  wl_surface_set_buffer_transform(surface.handle, cast[int32](transform))

func newSurface*(handle: ptr wl_surface): Surface {.inline.} =
  Surface(handle: handle, payload: SurfaceCallbackPayload())

let listener = wl_surface_listener(
  enter: proc(data: pointer, surf: ptr wl_surface, output: ptr wl_output) {.cdecl.} =
    let payload = cast[SurfaceCallbackPayload](data)
    if payload.enterCb != nil:
      payload.enterCb(newSurface(surf), initOutput(output)),
  leave: proc(data: pointer, surf: ptr wl_surface, output: ptr wl_output) {.cdecl.} =
    let payload = cast[SurfaceCallbackPayload](data)
    if payload.leaveCb != nil:
      payload.leaveCb(newSurface(surf), initOutput(output)),
  preferred_buffer_scale: proc(
      data: pointer, surf: ptr wl_surface, factor: int32
  ) {.cdecl.} =
    let payload = cast[SurfaceCallbackPayload](data)
    if payload.preferredBufferScaleCb != nil:
      payload.preferredBufferScaleCb(newSurface(surf), factor),
  preferred_buffer_transform: proc(
      data: pointer, surf: ptr wl_surface, transform: uint32
  ) {.cdecl.} =
    let payload = cast[SurfaceCallbackPayload](data)
    if payload.preferredBufferTransformCb != nil:
      payload.preferredBufferTransformCb(
        newSurface(surf), cast[OutputTransform](transform)
      ),
)

func `onEnter=`*(surface: Surface, cb: SurfaceEnterCallback) =
  surface.payload.enterCb = cb

func `onLeave=`*(surface: Surface, cb: SurfaceLeaveCallback) =
  surface.payload.leaveCb = cb

func `onPreferredBufferScale=`*(
    surface: Surface, cb: SurfacePreferredBufferScaleCallback
) =
  surface.payload.preferredBufferScaleCb = cb

func `onPreferredBufferTransform=`*(
    surface: Surface, cb: SurfacePreferredBufferTransformCallback
) =
  surface.payload.preferredBufferTransformCb = cb

proc attachCallbacks*(surface: Surface) =
  discard
    wl_surface_add_listener(surface.handle, listener.addr, cast[pointer](surface.payload))
