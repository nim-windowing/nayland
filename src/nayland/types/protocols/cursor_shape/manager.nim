## Wrapper around `wp_cursor_shape_manager_v1`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/cursor_shape_v1
import
  pkg/nayland/types/protocols/core/pointer,
  pkg/nayland/types/protocols/cursor_shape/device

type
  CursorShapeManagerObj = object
    handle: ptr wp_cursor_shape_manager_v1

  CursorShapeManager* = ref CursorShapeManagerObj

proc destroy*(mgr: CursorShapeManager) =
  wp_cursor_shape_manager_v1_destroy(mgr.handle)

proc getPointer*(mgr: CursorShapeManager, pntr: Pointer): CursorShapeDevice =
  newCursorShapeDevice(wp_cursor_shape_manager_v1_get_pointer(mgr.handle, pntr.handle))

proc initCursorShapeManager*(handle: pointer): CursorShapeManager =
  CursorShapeManager(handle: cast[ptr wp_cursor_shape_manager_v1](handle))
