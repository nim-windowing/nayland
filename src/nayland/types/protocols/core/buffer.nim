## Wrapper around `wl_buffer`
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak@disroot.org)
import std/options
#!fmt: off
import pkg/nayland/bindings/libwayland,
       pkg/nayland/bindings/protocols/core
#!fmt: on

type
  BufferObj = object
    handle*: ptr wl_buffer

    payload: BufferCallbackPayload

  BufferReleaseCallback* = proc(buffer: Buffer)

  BufferCallbackPObj = object
    obj*: Buffer
    releaseCb*: BufferReleaseCallback

  BufferCallbackPayload* = ref BufferCallbackPObj

  Buffer* = ref BufferObj

let listener = wl_buffer_listener(
  release: proc(data: pointer, buffer: ptr wl_buffer) {.cdecl.} =
    let payload = cast[ptr BufferCallbackPObj](data)
    payload.releaseCb(payload.obj)
)

proc `=destroy`*(buffer: BufferObj) =
  wl_buffer_destroy(buffer.handle)

proc `onRelease=`*(buffer: Buffer, callback: BufferReleaseCallback) =
  buffer.payload.releaseCb = callback

proc attachCallbacks*(buffer: Buffer) =
  discard wl_buffer_add_listener(
    buffer.handle, listener.addr, cast[ptr BufferCallbackPObj](buffer.payload)
  )

func newBuffer*(handle: ptr wl_buffer): Buffer =
  Buffer(handle: handle, payload: BuffercallbackPayload())

func initBuffer*(handle: ptr wl_buffer): Buffer =
  Buffer(handle: handle, payload: BuffercallbackPayload())
