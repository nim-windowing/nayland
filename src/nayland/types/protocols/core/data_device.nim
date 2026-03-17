## Wrapper around `wl_data_device`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/core
import pkg/nayland/types/protocols/core/[data_source, surface]

type
  DataDeviceObj = object
    handle: ptr wl_data_device

  DataDevice* = ref DataDeviceObj

proc `=destroy`*(device: DataDeviceObj) =
  discard # No-op

proc startDrag*(
    device: DataDevice, source: DataSource, origin, icon: Surface, serial: uint32
) =
  wl_data_device_start_drag(
    device.handle, source.handle, origin.handle, icon.handle, serial
  )

proc setSelection*(device: DataDevice, source: DataSource, serial: uint32) =
  wl_data_device_set_selection(device.handle, source.handle, serial)

proc release*(device: DataDevice) =
  wl_data_device_release(device.handle)

func newDataDevice*(handle: ptr wl_data_device): DataDevice =
  DataDevice(handle: handle)
