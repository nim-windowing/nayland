## Wrapper around `wl_data_device_manager`
## 
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import
  pkg/nayland/bindings/protocols/core,
  pkg/nayland/types/protocols/core/[data_device, data_source, seat]

type
  DataDeviceManagerObj = object
    handle: ptr wl_data_device_manager

  DataDeviceManager* = ref DataDeviceManagerObj

proc `=destroy`(mgr: DataDeviceManagerObj) =
  discard # No-op

proc createDataSource*(manager: DataDeviceManager): DataSource =
  newDataSource(wl_data_device_manager_create_data_source(manager.handle))

proc getDataDevice*(manager: DataDeviceManager, seat: Seat): DataDevice =
  newDataDevice(wl_data_device_manager_get_data_device(manager.handle, seat.handle))

func initDataDeviceManager*(handle: pointer): DataDeviceManager =
  DataDeviceManager(handle: cast[ptr wl_data_device_manager](handle))
