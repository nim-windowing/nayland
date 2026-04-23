## Wrapper around `wl_pointer`
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak@disroot.org)
import
  pkg/nayland/bindings/libwayland,
  pkg/nayland/bindings/protocols/core,
  pkg/nayland/types/protocols/core/surface

type
  PointerObj = object
    handle*: ptr wl_pointer

    callbacks: PointerCallbackPRef

  PointerCallbackPayload = object
    obj: Pointer

    enterCb: PointerEnterCallback
    leaveCb: PointerLeaveCallback
    motionCb: PointerMotionCallback
    frameCb: PointerFrameCallback
    axisCb: PointerAxisCallback
    axisSourceCb: PointerAxisSourceCallback
    axisStopCb: PointerAxisStopCallback
    axisDiscreteCb: PointerAxisDiscreteCallback
    axisValue120Cb: PointerAxisValue120Callback
    axisRelativeDirection: PointerAxisRelativeDirectionCallback
    buttonCb: PointerButtonCallback

  PointerCallbackPRef = ref PointerCallbackPayload

  PointerEnterCallback* =
    proc(pntr: Pointer, serial: uint32, surface: Surface, surfaceX, surfaceY: float)

  PointerFrameCallback* = proc(pntr: Pointer)
  PointerAxisCallback* = proc(pntr: Pointer, time, axis: uint32, value: float)

  PointerLeaveCallback* = proc(pntr: Pointer, serial: uint32, surface: Surface)

  PointerMotionCallback* = proc(pntr: Pointer, time: uint32, surfaceX, surfaceY: float)
  PointerAxisSourceCallback* = proc(pntr: Pointer, axisSource: uint32)
  PointerAxisStopCallback* = proc(pntr: Pointer, time, axis: uint32)
  PointerAxisDiscreteCallback* = proc(pntr: Pointer, axis: uint32, discrete: int32)
  PointerAxisValue120Callback* = proc(pntr: Pointer, axis: uint32, value120: int32)
  PointerAxisRelativeDirectionCallback* = proc(pntr: Pointer, axis, direction: uint32)
  PointerButtonCallback* =
    proc(pntr: Pointer, serial, time, button: uint32, state: ButtonState)

  ButtonState* {.pure, size: sizeof(uint32).} = enum
    Released = 0
    Pressed = 1

  Pointer* = ref PointerObj

let listener = wl_pointer_listener(
  enter: proc(
      data: pointer,
      _: ptr wl_pointer,
      serial: uint32,
      surf: ptr wl_surface,
      surfaceX, surfaceY: wl_fixed,
  ) {.cdecl.} =
    let payload = cast[ptr PointerCallbackPayload](data)
    payload.enterCb(
      payload.obj, serial, newSurface(surf), surfaceX.toFloat(), surfaceY.toFloat()
    ),
  leave: proc(
      data: pointer, _: ptr wl_pointer, serial: uint32, surf: ptr wl_surface
  ) {.cdecl.} =
    let payload = cast[ptr PointerCallbackPayload](data)
    payload.leaveCb(payload.obj, serial, newSurface(surf)),
  motion: proc(
      data: pointer, _: ptr wl_pointer, time: uint32, surfaceX, surfaceY: wl_fixed
  ) {.cdecl.} =
    let payload = cast[ptr PointerCallbackPayload](data)
    payload.motionCb(payload.obj, time, surfaceX.toFloat(), surfaceY.toFloat()),
  frame: proc(data: pointer, _: ptr wl_pointer) {.cdecl.} =
    let payload = cast[ptr PointerCallbackPayload](data)
    payload.frameCb(payload.obj),
  axis: proc(
      data: pointer, _: ptr wl_pointer, time, axis: uint32, value: wl_fixed
  ) {.cdecl.} =
    let payload = cast[ptr PointerCallbackPayload](data)
    payload.axisCb(payload.obj, time, axis, toFloat(value)),
  button: proc(
      data: pointer, pntr: ptr wl_pointer, serial, time, button, state: uint32
  ) {.cdecl.} =
    let payload = cast[ptr PointerCallbackPayload](data)
    payload.buttonCb(payload.obj, serial, time, button, cast[ButtonState](state)),
  axis_stop: proc(data: pointer, pntr: ptr wl_pointer, time, axis: uint32) {.cdecl.} =
    let payload = cast[ptr PointerCallbackPayload](data)
    payload.axisStopCb(payload.obj, time, axis),
  axis_discrete: proc(
      data: pointer, pntr: ptr wl_pointer, axis: uint32, discrete: int32
  ) {.cdecl.} =
    let payload = cast[ptr PointerCallbackPayload](data)
    payload.axisDiscreteCb(payload.obj, axis, discrete),
  axis_value120: proc(
      data: pointer, pntr: ptr wl_pointer, axis: uint32, value120: int32
  ) {.cdecl.} =
    let payload = cast[ptr PointerCallbackPayload](data)
    payload.axisValue120Cb(payload.obj, axis, value120),
  axis_source: proc(data: pointer, pntr: ptr wl_pointer, axisSource: uint32) {.cdecl.} =
    let payload = cast[ptr PointerCallbackPayload](data)
    payload.axisSourceCb(payload.obj, axisSource),
  axis_relative_direction: proc(
      data: pointer, pntr: ptr wl_pointer, axis, direction: uint32
  ) {.cdecl.} =
    let payload = cast[ptr PointerCallbackPayload](data)
    payload.axisRelativeDirection(payload.obj, axis, direction),
)

proc release*(pntr: Pointer | PointerObj) =
  wl_pointer_release(pntr.handle)

proc `onEnter=`*(pntr: Pointer, callback: PointerEnterCallback) =
  pntr.callbacks.enterCb = callback

proc `onLeave=`*(pntr: Pointer, callback: PointerLeaveCallback) =
  pntr.callbacks.leaveCb = callback

proc `onMotion=`*(pntr: Pointer, callback: PointerMotionCallback) =
  pntr.callbacks.motionCb = callback

proc `onFrame=`*(pntr: Pointer, callback: PointerFrameCallback) =
  pntr.callbacks.frameCb = callback

proc `onAxis=`*(pntr: Pointer, callback: PointerAxisCallback) =
  pntr.callbacks.axisCb = callback

proc `onAxisSource=`*(pntr: Pointer, callback: PointerAxisSourceCallback) =
  pntr.callbacks.axisSourceCb = callback

proc `onButton=`*(pntr: Pointer, callback: PointerButtonCallback) =
  pntr.callbacks.buttonCb = callback

proc `onAxisStop=`*(pntr: Pointer, callback: PointerAxisStopCallback) =
  pntr.callbacks.axisStopCb = callback

proc `onAxisDiscrete=`*(pntr: Pointer, callback: PointerAxisDiscreteCallback) =
  pntr.callbacks.axisDiscreteCb = callback

proc `onAxisValue120=`*(pntr: Pointer, callback: PointerAxisValue120Callback) =
  pntr.callbacks.axisValue120Cb = callback

proc `onAxisRelativeDirection=`*(
    pntr: Pointer, callback: PointerAxisRelativeDirectionCallback
) =
  pntr.callbacks.axisRelativeDirection = callback

proc attachCallbacks*(pntr: Pointer) =
  pntr.callbacks.obj = pntr

  discard wl_pointer_add_listener(
    pntr.handle, listener.addr, cast[ptr PointerCallbackPayload](pntr.callbacks)
  )

func newPointer*(handle: ptr wl_pointer): Pointer =
  Pointer(handle: handle, callbacks: PointerCallbackPRef())
