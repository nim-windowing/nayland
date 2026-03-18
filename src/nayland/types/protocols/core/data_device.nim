## Wrapper around `wl_data_device`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/core, pkg/nayland/bindings/libwayland
import pkg/nayland/types/protocols/core/[data_source, data_offer, surface]

type
  DataDeviceObj = object
    handle: ptr wl_data_device
    payload: DataDevicePayload

  DataDeviceDataOfferCallback = proc(device: DataDevice, offer: DataOffer)
  DataDeviceEnterCallback = proc(
    device: DataDevice, serial: uint32, surface: Surface, x, y: float, offer: DataOffer
  )
  DataDeviceLeaveCallback = proc(device: DataDevice)
  DataDeviceMotionCallback = proc(device: DataDevice, serial: uint32, x, y: float)
  DataDeviceDropCallback = proc(device: DataDevice)
  DataDeviceSelectionCallback = proc(device: DataDevice, offer: DataOffer)

  DataDevicePObj = object
    dataOfferCb*: DataDeviceDataOfferCallback
    enterCb*: DataDeviceEnterCallback
    leaveCb*: DataDeviceLeaveCallback
    motionCb*: DataDeviceMotionCallback
    dropCb*: DataDeviceDropCallback
    selectionCb*: DataDeviceSelectionCallback

  DataDevicePayload = ref DataDevicePObj

  DataDevice* = ref DataDeviceObj

proc `=destroy`*(device: DataDeviceObj) =
  discard # No-op

func newDataDevice*(handle: ptr wl_data_device): DataDevice {.inline.} =
  DataDevice(handle: handle, payload: DataDevicePayload())

let listener = wl_data_device_listener(
  data_offer: proc(
      data: pointer, device: ptr wl_data_device, offer: ptr wl_data_offer
  ) {.cdecl.} =
    let payload = cast[DataDevicePayload](data)
    payload.dataOfferCb(newDataDevice(device), newDataOffer(offer)),
  enter: proc(
      data: pointer,
      device: ptr wl_data_device,
      serial: uint32,
      surface: ptr wl_surface,
      x, y: wl_fixed,
      offer: ptr wl_data_offer,
  ) {.cdecl.} =
    let payload = cast[DataDevicePayload](data)
    payload.enterCb(
      newDataDevice(device),
      serial,
      newSurface(surface),
      x.toFloat(),
      y.toFloat(),
      newDataOffer(offer),
    ),
  leave: proc(data: pointer, device: ptr wl_data_device) {.cdecl.} =
    let payload = cast[DataDevicePayload](data)
    payload.leaveCb(newDataDevice(device)),
  motion: proc(
      data: pointer, source: ptr wl_data_device, serial: uint32, x, y: wl_fixed
  ) {.cdecl.} =
    let payload = cast[DataDevicePayload](data)
    payload.motionCb(newDataDevice(source), serial, x.toFloat(), y.toFloat()),
  drop: proc(data: pointer, source: ptr wl_data_device) {.cdecl.} =
    let payload = cast[DataDevicePayload](data)
    payload.dropCb(newDataDevice(source)),
  selection: proc(
      data: pointer, source: ptr wl_data_device, offer: ptr wl_data_offer
  ) {.cdecl.} =
    let payload = cast[DataDevicePayload](data)
    payload.selectionCb(newDataDevice(source), newDataOffer(offer)),
)

proc startDrag*(
    device: DataDevice, source: DataSource, origin, icon: Surface, serial: uint32
) =
  wl_data_device_start_drag(
    device.handle, source.handle, origin.handle, icon.handle, serial
  )

proc setSelection*(device: DataDevice, source: DataSource, serial: uint32) =
  wl_data_device_set_selection(device.handle, source.handle, serial)

func `onDataOffer=`*(device: DataDevice, cb: DataDeviceDataOfferCallback) =
  device.payload.dataOfferCb = cb

func `onEnter=`*(device: DataDevice, cb: DataDeviceEnterCallback) =
  device.payload.enterCb = cb

func `onLeave=`*(device: DataDevice, cb: DataDeviceLeaveCallback) =
  device.payload.leaveCb = cb

func `onMotion=`*(device: DataDevice, cb: DataDeviceMotionCallback) =
  device.payload.motionCb = cb

func `onDrop=`*(device: DataDevice, cb: DataDeviceDropCallback) =
  device.payload.dropCb = cb

func `onSelection=`*(device: DataDevice, cb: DataDeviceSelectionCallback) =
  device.payload.selectionCb = cb

proc attachCallbacks*(device: DataDevice) =
  discard wl_data_device_add_listener(
    device.handle, listener.addr, cast[pointer](device.payload)
  )

proc release*(device: DataDevice) =
  wl_data_device_release(device.handle)
