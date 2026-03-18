## Wrapper for `xdg-system-bell-v1`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/[core, xdg_system_bell_v1]
import pkg/nayland/types/protocols/core/surface

type
  XDGSystemBellObj = object
    handle: ptr xdg_system_bell_v1

  XDGSystemBell* = ref XDGSystemBellObj
    ## System Bell
    ## This global interface enables clients to ring the system bell.
    ##
    ## Warning! The protocol described in this file is currently in the testing phase. Backward compatible changes may be added together with the corresponding interface version bump. Backward incompatible changes can only be done by creating a new major version of the extension.

proc `=destroy`*(bell: XDGSystemBellObj) =
  xdg_system_bell_v1_destroy(bell.handle)

proc ring*(bell: XDGSystemBell, surface: Surface = nil) =
  xdg_system_bell_v1_ring(bell.handle, if surface != nil: surface.handle else: nil)

func initXDGSystemBell*(handle: pointer): XDGSystemBell {.inline.} =
  XDGSystemBell(handle: cast[ptr xdg_system_bell_v1](handle))
