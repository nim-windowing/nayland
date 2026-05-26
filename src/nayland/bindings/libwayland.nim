## Low-level, handrolled libwayland-client bindings
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak at disroot dot org)
import std/strutils

type ConstCStr* {.importc: "const char *".} = distinct cstring
proc `$`*(cstr: ConstCStr): string {.borrow.}

const
  LibwaylandCflags* = gorge("pkg-config --cflags wayland-client").strip()
  LibwaylandLibs* = gorge("pkg-config --libs wayland-client").strip()

{.passC: LibwaylandCflags.}
{.passL: LibwaylandLibs.}

{.push header: "<wayland-util.h>".}

type
  wl_object* {.importc: "struct $1".} = object
  wl_message* {.importc: "struct $1".} = object
    name*: cstring
    signature*: cstring
    types*: ptr UncheckedArray[wl_interface]

  wl_interface* {.importc: "struct $1".} = object
    name*: cstring
    version*: int32
    methodCount*: int32
    methods*: ptr wl_message
    eventCount*: int32
    events*: ptr wl_message

  wl_fixed* {.importc: "wl_fixed_t".} = int32

  wl_array* {.importc: "struct $1".} = object
    size*, alloc*: uint64
    data*: pointer

  wl_argument* {.importc: "union $1", union.} = object
    i*: int32
    u*: uint32
    f*: wl_fixed
    s*: cstring
    o*: ptr wl_object
    n*: uint32
    a*: ptr wl_array
    h*: int32

{.push importc.}
let WL_MAX_MESSAGE_SIZE*: int32
{.pop.}

{.pop.}

{.push header: "<wayland-client.h>".}

type
  wl_proxy* {.importc: "struct $1".} = object
  wl_display* {.importc: "struct $1".} = pointer
  wl_event_queue* {.importc: "struct $1".} = object

{.push importc.}
let WL_MARSHAL_FLAG_DESTROY*: uint32

proc wl_event_queue_destroy*(queue: ptr wl_event_queue): void
proc wl_proxy_marshal_flags*(
  proxy: ptr wl_proxy,
  opcode: uint32,
  iface: ptr wl_interface,
  version: uint32,
  flags: uint32,
): ptr wl_proxy {.varargs, discardable.}

proc wl_proxy_destroy*(proxy: ptr wl_proxy)

proc wl_proxy_marshal_array_flags*(
  proxy: ptr wl_proxy,
  opcode: uint32,
  iface: ptr wl_interface,
  version, flags: uint32,
  args: ptr UncheckedArray[wl_argument],
): ptr wl_proxy

proc wl_proxy_add_listener*(
  proxy: ptr wl_proxy, impl: ptr proc() {.cdecl.}, data: pointer
): int32

proc wl_proxy_set_user_data*(proxy: ptr wl_proxy, data: pointer)
proc wl_proxy_get_user_data*(proxy: ptr wl_proxy): pointer
proc wl_proxy_get_version*(proxy: ptr wl_proxy): uint32

proc wl_display_connect*(name: cstring): ptr wl_display
proc wl_display_connect_to_fd*(fd: int32): ptr wl_display
proc wl_display_disconnect*(d: ptr wl_display)
proc wl_display_get_fd*(d: ptr wl_display): int32
proc wl_display_dispatch*(d: ptr wl_display)
proc wl_display_get_error*(d: ptr wl_display): int32
proc wl_display_get_protocol_error*(d: ptr wl_display): uint32
proc wl_display_flush*(d: ptr wl_display): int32
proc wl_display_roundtrip_queue*(d: ptr wl_display, queue: ptr wl_event_queue): int32
proc wl_display_roundtrip*(d: ptr wl_display): int32
proc wl_display_create_queue*(d: ptr wl_display): ptr wl_event_queue
proc wl_display_create_queue_with_name*(
  d: ptr wl_display, name: cstring
): ptr wl_event_queue

{.pop.}

{.pop.}
