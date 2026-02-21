## Wrapper around `zxdg_decoration_manager_v1`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/xdg_decoration_unstable_v1
import
  pkg/nayland/types/protocols/xdg_shell/xdg_toplevel,
  pkg/nayland/types/protocols/xdg_decoration/toplevel_decoration

type
  XDGDecorationManagerObj = object
    handle*: ptr zxdg_decoration_manager_v1

  XDGDecorationManager* = ref XDGDecorationManagerObj

proc `=destroy`*(manager: XDGDecorationManagerObj) =
  zxdg_decoration_manager_v1_destroy(manager.handle)

proc getToplevelDecoration*(
    manager: XDGDecorationManager, toplevel: XDGToplevel
): XDGToplevelDecoration =
  newXDGToplevelDecoration(
    zxdg_decoration_manager_v1_get_toplevel_decoration(manager.handle, toplevel.handle)
  )

func initXDGDecorationManager*(handle: pointer): XDGDecorationManager =
  XDGDecorationManager(handle: cast[ptr zxdg_decoration_manager_v1](handle))
