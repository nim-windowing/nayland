## Wrapper around `wl_data_source`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/core

type
  DataSourceObj = object
    handle*: ptr wl_data_source

  DNDAction* {.pure, size: sizeof(uint32).} = enum
    None = 0
    Copy = 1
    Move = 2
    Ask = 4

  DataSource* = ref DataSourceObj

proc `=destroy`*(source: DataSourceObj) =
  wl_data_source_destroy(source.handle)

proc offer*(source: DataSource, mime: string) =
  wl_data_source_offer(source.handle, cstring(mime))

proc setActions*(source: DataSource, actions: set[DNDAction]) =
  wl_data_source_set_actions(source.handle, cast[uint32](actions))

func newDataSource*(handle: ptr wl_data_source): DataSource =
  DataSource(handle: handle)
