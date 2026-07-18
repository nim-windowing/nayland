## Wrapper for `wl_touch`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/core, pkg/nayland/bindings/libwayland
import pkg/nayland/types/protocols/core/[surface]

type
  TouchObj = object
    handle*: ptr wl_touch
    payload: TouchCallbacksPayload

  TouchDownCallback =
    proc(touch: Touch, serial, time: uint32, surface: Surface, id: int32, x, y: float)
  TouchUpCallback = proc(touch: Touch, serial, time: uint32, id: int32)
  TouchMotionCallback = proc(touch: Touch, time: uint32, id: int32, x, y: float)
  TouchFrameCallback = proc(touch: Touch)
  TouchCancelCallback = proc(touch: Touch)
  TouchShapeCallback = proc(touch: Touch, id: int32, major, minor: float)
  TouchOrientationCallback = proc(touch: Touch, id: int32, orientation: float)

  TouchCallbacksPObj = object
    downCb: TouchDownCallback
    upCb: TouchUpCallback
    motionCb: TouchMotionCallback
    frameCb: TouchFrameCallback
    cancelCb: TouchCancelCallback
    shapeCb: TouchShapeCallback
    orientationCb: TouchOrientationCallback

  TouchCallbacksPayload = ref TouchCallbacksPObj

  Touch* = ref TouchObj

proc newTouch*(handle: ptr wl_touch): Touch {.inline.}

let listener = wl_touch_listener(
  down: proc(
      data: pointer,
      touch: ptr wl_touch,
      serial: uint32,
      time: uint32,
      surface: ptr wl_surface,
      id: int32,
      x, y: wl_fixed,
  ) {.cdecl.} =
    let payload = cast[TouchCallbacksPayload](data)
    if payload.downCb != nil:
      payload.downCb(
        newTouch(touch), serial, time, newSurface(surface), id, x.toFloat(), y.toFloat()
      ),
  up: proc(
      data: pointer, touch: ptr wl_touch, serial: uint32, time: uint32, id: int32
  ) {.cdecl.} =
    let payload = cast[TouchCallbacksPayload](data)
    if payload.upCb != nil:
      payload.upCb(newTouch(touch), serial, time, id),
  motion: proc(
      data: pointer, touch: ptr wl_touch, time: uint32, id: int32, x, y: wl_fixed
  ) {.cdecl.} =
    let payload = cast[TouchCallbacksPayload](data)
    if payload.motionCb != nil:
      payload.motionCb(newTouch(touch), time, id, x.toFloat(), y.toFloat()),
  frame: proc(data: pointer, touch: ptr wl_touch) {.cdecl.} =
    let payload = cast[TouchCallbacksPayload](data)
    if payload.frameCb != nil:
      payload.frameCb(newTouch(touch)),
  cancel: proc(data: pointer, touch: ptr wl_touch) {.cdecl.} =
    let payload = cast[TouchCallbacksPayload](data)
    if payload.cancelCb != nil:
      payload.cancelCb(newTouch(touch)),
  shape: proc(
      data: pointer, touch: ptr wl_touch, id: int32, major, minor: wl_fixed
  ) {.cdecl.} =
    let payload = cast[TouchCallbacksPayload](data)
    if payload.shapeCb != nil:
      payload.shapeCb(newTouch(touch), id, major.toFloat(), minor.toFloat()),
  orientation: proc(
      data: pointer, touch: ptr wl_touch, id: int32, orientation: wl_fixed
  ) {.cdecl.} =
    let payload = cast[TouchCallbacksPayload](data)
    if payload.orientationCb != nil:
      payload.orientationCb(newTouch(touch), id, orientation.toFloat()),
)

proc release*(touch: Touch) =
  wl_touch_release(touch.handle)

func `onDown=`*(touch: Touch, cb: TouchDownCallback) =
  touch.payload.downCb = cb

func `onUp=`*(touch: Touch, cb: TouchUpCallback) =
  touch.payload.upCb = cb

func `onMotion=`*(touch: Touch, cb: TouchMotionCallback) =
  touch.payload.motionCb = cb

func `onFrame=`*(touch: Touch, cb: TouchFrameCallback) =
  touch.payload.frameCb = cb

func `onCancel=`*(touch: Touch, cb: TouchCancelCallback) =
  touch.payload.cancelCb = cb

func `onShape=`*(touch: Touch, cb: TouchShapeCallback) =
  touch.payload.shapeCb = cb

func `onOrientation=`*(touch: Touch, cb: TouchOrientationCallback) =
  touch.payload.orientationCb = cb

proc attachCallbacks*(touch: Touch) {.deprecated: "callbacks are attached automatically now; this call is a no-op and safe to remove".} 
  discard

proc newTouch*(handle: ptr wl_touch): Touch {.inline.} =
  result = Touch(handle: handle, payload: TouchCallbacksPayload())
  discard
    wl_touch_add_listener(result.handle, listener.addr, cast[pointer](result.payload))
