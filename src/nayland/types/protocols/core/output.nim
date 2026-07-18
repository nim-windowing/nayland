## Wrapper over `wl_output`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/core, pkg/nayland/bindings/libwayland

type
  OutputObj = object
    handle*: ptr wl_output
    payload: OutputCallbackPayload

  OutputSubpixel* {.pure, size: sizeof(uint32).} = enum
    Unknown = 0
    None = 1
    HorizontalRGB = 2
    HorizontalBGR = 3
    VerticalRGB = 4
    VerticalBGR = 5

  OutputTransform* {.pure, size: sizeof(uint32).} = enum
    Normal = 0
    Deg90 = 1
    Deg180 = 2
    Deg270 = 3
    Flipped = 4
    Flipped90 = 5
    Flipped180 = 6
    Flipped270 = 7

  OutputMode* {.pure, size: sizeof(uint32).} = enum
    Current = 0x1
    Preferred = 0x2

  OutputGeometryCallback = proc(
    output: Output,
    x, y, physicalWidth, physicalHeight: int32,
    subpixel: OutputSubpixel,
    make, model: string,
    transform: OutputTransform,
  )

  OutputModeCallback =
    proc(output: Output, flags: set[OutputMode], width, height, refreshMhz: int32)

  OutputDoneCallback = proc(output: Output)
  OutputScaleCallback = proc(output: Output, factor: int32)
  OutputNameCallback = proc(output: Output, name: string)
  OutputDescriptionCallback = proc(output: Output, description: string)

  OutputCallbackPObj = object
    geometryCb: OutputGeometryCallback
    modeCb: OutputModeCallback
    doneCb: OutputDoneCallback
    scaleCb: OutputScaleCallback
    nameCb: OutputNameCallback
    descriptionCb: OutputDescriptionCallback

  OutputCallbackPayload = ref OutputCallbackPObj

  Output* = ref OutputObj

proc release*(output: Output) =
  wl_output_release(output.handle)

proc initOutput*(handle: pointer | ptr wl_output): Output {.inline.}

let listener = wl_output_listener(
  geometry: proc(
      data: pointer,
      output: ptr wl_output,
      x, y, physicalWidth, physicalHeight, subpixel: int32,
      make, model: ConstCStr,
      transform: int32,
  ) {.cdecl.} =
    let payload = cast[OutputCallbackPayload](data)
    if payload.geometryCb != nil:
      payload.geometryCb(
        initOutput(output),
        x,
        y,
        physicalWidth,
        physicalHeight,
        cast[OutputSubpixel](subpixel),
        $make,
        $model,
        cast[OutputTransform](transform),
      ),
  mode: proc(
      data: pointer, output: ptr wl_output, flags: uint32, width, height, refresh: int32
  ) {.cdecl.} =
    let payload = cast[OutputCallbackPayload](data)
    if payload.modeCb != nil:
      payload.modeCb(
        initOutput(output), cast[set[OutputMode]](flags), width, height, refresh
      ),
  done: proc(data: pointer, output: ptr wl_output) {.cdecl.} =
    let payload = cast[OutputCallbackPayload](data)
    if payload.doneCb != nil:
      payload.doneCb(initOutput(output)),
  scale: proc(data: pointer, output: ptr wl_output, factor: int32) {.cdecl.} =
    let payload = cast[OutputCallbackPayload](data)
    if payload.scaleCb != nil:
      payload.scaleCb(initOutput(output), factor),
  name: proc(data: pointer, output: ptr wl_output, name: ConstCStr) {.cdecl.} =
    let payload = cast[OutputCallbackPayload](data)
    if payload.nameCb != nil:
      payload.nameCb(initOutput(output), $name),
  description: proc(data: pointer, output: ptr wl_output, desc: ConstCStr) {.cdecl.} =
    let payload = cast[OutputCallbackPayload](data)
    if payload.descriptionCb != nil:
      payload.descriptionCb(initOutput(output), $desc),
)

func `onGeometry=`*(output: Output, cb: OutputGeometryCallback) =
  output.payload.geometryCb = cb

func `onMode=`*(output: Output, cb: OutputModeCallback) =
  output.payload.modeCb = cb

func `onDone=`*(output: Output, cb: OutputDoneCallback) =
  output.payload.doneCb = cb

func `onScale=`*(output: Output, cb: OutputScaleCallback) =
  output.payload.scaleCb = cb

func `onName=`*(output: Output, cb: OutputNameCallback) =
  output.payload.nameCb = cb

func `onDescription=`*(output: Output, cb: OutputDescriptionCallback) =
  output.payload.descriptionCb = cb

proc attachCallbacks*(output: Output) {.deprecated: "callbacks are attached automatically now; this call is a no-op and safe to remove".} =
  discard

proc initOutput*(handle: pointer | ptr wl_output): Output {.inline.} =
  result = Output(handle: cast[ptr wl_output](handle), payload: OutputCallbackPayload())
  discard
    wl_output_add_listener(result.handle, listener.addr, cast[pointer](result.payload))
