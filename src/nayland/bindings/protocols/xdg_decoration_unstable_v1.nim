## Minimal bindings for xdg-decoration-unstable-v1.
import pkg/nayland/bindings/protocols/core

# Link private code for protocol
{.compile("private-code/xdg_decoration_unstable_v1.c", core.LibwaylandCflags).}

import
  pkg/nayland/bindings/libwayland,
  pkg/nayland/bindings/protocols/xdg_shell

type
  zxdg_decoration_manager_v1* = object
  zxdg_toplevel_decoration_v1* = object

let zxdg_decoration_manager_v1_interface* {.importc.}: wl_interface
let zxdg_toplevel_decoration_v1_interface* {.importc.}: wl_interface

type
  zxdg_toplevel_decoration_v1_mode* {.size: sizeof(uint32), pure.} = enum
    ZXDG_TOPLEVEL_DECORATION_V1_MODE_CLIENT_SIDE = 1
    ZXDG_TOPLEVEL_DECORATION_V1_MODE_SERVER_SIDE = 2

  zxdg_toplevel_decoration_v1_listener* {.bycopy.} = object
    configure*: proc(
      data: pointer,
      zxdg_toplevel_decoration_v1: ptr zxdg_toplevel_decoration_v1,
      mode: uint32,
    ) {.cdecl.}

const
  ZXDG_DECORATION_MANAGER_V1_DESTROY* = 0
  ZXDG_DECORATION_MANAGER_V1_GET_TOPLEVEL_DECORATION* = 1

  ZXDG_TOPLEVEL_DECORATION_V1_DESTROY* = 0
  ZXDG_TOPLEVEL_DECORATION_V1_SET_MODE* = 1
  ZXDG_TOPLEVEL_DECORATION_V1_UNSET_MODE* = 2

proc zxdg_decoration_manager_v1_set_user_data*(
    manager: ptr zxdg_decoration_manager_v1, user_data: pointer
) {.inline, cdecl.} =
  wl_proxy_set_user_data(cast[ptr wl_proxy](manager), user_data)

proc zxdg_decoration_manager_v1_get_user_data*(
    manager: ptr zxdg_decoration_manager_v1
): pointer {.inline, cdecl.} =
  wl_proxy_get_user_data(cast[ptr wl_proxy](manager))

proc zxdg_decoration_manager_v1_get_version*(
    manager: ptr zxdg_decoration_manager_v1
): uint32 {.inline, cdecl.} =
  wl_proxy_get_version(cast[ptr wl_proxy](manager))

proc zxdg_decoration_manager_v1_destroy*(
    manager: ptr zxdg_decoration_manager_v1
) {.inline, cdecl.} =
  wl_proxy_marshal_flags(
    cast[ptr wl_proxy](manager),
    ZXDG_DECORATION_MANAGER_V1_DESTROY,
    nil,
    wl_proxy_get_version(cast[ptr wl_proxy](manager)),
    WL_MARSHAL_FLAG_DESTROY,
  )

proc zxdg_decoration_manager_v1_get_toplevel_decoration*(
    manager: ptr zxdg_decoration_manager_v1,
    toplevel: ptr xdg_toplevel,
): ptr zxdg_toplevel_decoration_v1 {.inline, cdecl.} =
  var id: ptr wl_proxy
  id = wl_proxy_marshal_flags(
    cast[ptr wl_proxy](manager),
    ZXDG_DECORATION_MANAGER_V1_GET_TOPLEVEL_DECORATION,
    addr(zxdg_toplevel_decoration_v1_interface),
    wl_proxy_get_version(cast[ptr wl_proxy](manager)),
    0,
    nil,
    toplevel,
  )
  cast[ptr zxdg_toplevel_decoration_v1](id)

proc zxdg_toplevel_decoration_v1_add_listener*(
    decoration: ptr zxdg_toplevel_decoration_v1,
    listener: ptr zxdg_toplevel_decoration_v1_listener,
    data: pointer,
): cint {.inline, cdecl.} =
  wl_proxy_add_listener(
    cast[ptr wl_proxy](decoration),
    cast[ptr proc() {.cdecl.}](listener),
    data,
  )

proc zxdg_toplevel_decoration_v1_set_user_data*(
    decoration: ptr zxdg_toplevel_decoration_v1, user_data: pointer
) {.inline, cdecl.} =
  wl_proxy_set_user_data(cast[ptr wl_proxy](decoration), user_data)

proc zxdg_toplevel_decoration_v1_get_user_data*(
    decoration: ptr zxdg_toplevel_decoration_v1
): pointer {.inline, cdecl.} =
  wl_proxy_get_user_data(cast[ptr wl_proxy](decoration))

proc zxdg_toplevel_decoration_v1_get_version*(
    decoration: ptr zxdg_toplevel_decoration_v1
): uint32 {.inline, cdecl.} =
  wl_proxy_get_version(cast[ptr wl_proxy](decoration))

proc zxdg_toplevel_decoration_v1_destroy*(
    decoration: ptr zxdg_toplevel_decoration_v1
) {.inline, cdecl.} =
  wl_proxy_marshal_flags(
    cast[ptr wl_proxy](decoration),
    ZXDG_TOPLEVEL_DECORATION_V1_DESTROY,
    nil,
    wl_proxy_get_version(cast[ptr wl_proxy](decoration)),
    WL_MARSHAL_FLAG_DESTROY,
  )

proc zxdg_toplevel_decoration_v1_set_mode*(
    decoration: ptr zxdg_toplevel_decoration_v1,
    mode: uint32,
) {.inline, cdecl.} =
  wl_proxy_marshal_flags(
    cast[ptr wl_proxy](decoration),
    ZXDG_TOPLEVEL_DECORATION_V1_SET_MODE,
    nil,
    wl_proxy_get_version(cast[ptr wl_proxy](decoration)),
    0,
    mode,
  )

proc zxdg_toplevel_decoration_v1_unset_mode*(
    decoration: ptr zxdg_toplevel_decoration_v1
) {.inline, cdecl.} =
  wl_proxy_marshal_flags(
    cast[ptr wl_proxy](decoration),
    ZXDG_TOPLEVEL_DECORATION_V1_UNSET_MODE,
    nil,
    wl_proxy_get_version(cast[ptr wl_proxy](decoration)),
    0,
  )
