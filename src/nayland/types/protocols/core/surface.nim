## Wrapper around `wl_surface`
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak at disroot dot org)

#!fmt: off
import pkg/nayland/bindings/libwayland,
       pkg/nayland/bindings/protocols/core,
       pkg/nayland/types/protocols/core/[buffer, callback]
#!fmt: on

type
  SurfaceObj = object
    handle*: ptr wl_surface

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

proc newSurface*(handle: ptr wl_surface): Surface =
  Surface(handle: handle)
