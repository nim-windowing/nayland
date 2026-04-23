## ====================
## Cursor Shape Manager
## ====================
## 
## This global offers an alternative, optional way to set cursor images. This new way uses enumerated cursors instead of a wl_surface like wl_pointer.set_cursor does.
## 
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/types/protocols/cursor_shape/[device, manager]
import pkg/nayland/bindings/protocols/tablet_v2

export device, manager
