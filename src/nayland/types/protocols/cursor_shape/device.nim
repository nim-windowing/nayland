## Wrapper around `wp_cursor_shape_device_v1`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/cursor_shape_v1

type
  CursorShapeDeviceObj = object
    handle: ptr wp_cursor_shape_device_v1

  CursorShape* {.pure, size: sizeof(uint32).} = enum
    ## Cursor Shapes
    ##
    ## The names are taken from the CSS W3C specification: https://w3c.github.io/csswg-drafts/css-ui/#cursor with a few additions.
    ##
    ## Note that there are some groups of cursor shapes that are related: The first group is drag-and-drop cursors which are used to indicate the selected action during dnd operations. The second group is resize cursors which are used to indicate resizing and moving possibilities on window borders. It is recommended that the shapes in these groups should use visually compatible images and metaphors.
    Default = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_DEFAULT
    ContextMenu = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_CONTEXT_MENU
    Help = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_HELP
    Pointer = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_POINTER
    Progress = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_PROGRESS
    Wait = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_WAIT
    Cell = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_CELL
    Crosshair = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_CROSSHAIR
    Text = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_TEXT
    VerticalText = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_VERTICAL_TEXT
    Alias = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_ALIAS
    Copy = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_COPY
    Move = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_MOVE
    NoDrop = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NO_DROP
    NotAllowed = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NOT_ALLOWED
    Grab = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_GRAB
    Grabbing = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_GRABBING
    EastResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_E_RESIZE
    NorthResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_N_RESIZE
    NorthEastResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NE_RESIZE
    NorthWestResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NW_RESIZE
    SouthResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_S_RESIZE
    SouthEastResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_SE_RESIZE
    SouthWestResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_SW_RESIZE
    WestResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_W_RESIZE
    EastWestResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_EW_RESIZE
    NorthSouthResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NS_RESIZE
    NorthEastSouthWestResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NESW_RESIZE
    NorthWestSouthEastResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NWSE_RESIZE
    ColumnResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_COL_RESIZE
    RowResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_ROW_RESIZE
    AllScroll = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_ALL_SCROLL
    ZoomIn = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_ZOOM_IN
    ZoomOut = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_ZOOM_OUT
    DNDAsk = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_DND_ASK
    AllResize = WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_ALL_RESIZE

  CursorShapeDevice* = ref CursorShapeDeviceObj

proc `=destroy`*(dev: CursorShapeDeviceObj) =
  wp_cursor_shape_device_v1_destroy(dev.handle)

proc setShape*(dev: CursorShapeDevice, serial: uint32, shape: CursorShape) =
  wp_cursor_shape_device_v1_set_shape(dev.handle, serial, cast[uint32](shape))

proc newCursorShapeDevice*(handle: ptr wp_cursor_shape_device_v1): CursorShapeDevice =
  CursorShapeDevice(handle: handle)
