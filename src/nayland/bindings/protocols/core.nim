## Wayland client core protocol bindings
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak at disroot dot org)
import pkg/nayland/bindings/libwayland

{.push header: "<wayland-client-protocol.h>".}

type
  wl_registry* {.importc: "struct $1".} = object
  wl_registry_listener* {.importc: "struct $1".} = object
    global*: proc(
      data: pointer,
      registry: ptr wl_registry,
      name: uint32,
      iface: ConstCStr,
      version: uint32,
    ) {.cdecl.}

    global_remove*:
      proc(data: pointer, registry: ptr wl_registry, name: uint32) {.cdecl.}

  wl_compositor* {.importc: "struct $1".} = object
  wl_surface* {.importc: "struct $1".} = object
  wl_region* {.importc: "struct $1".} = object
  wl_shm* {.importc: "struct $1".} = object
  wl_shm_pool* {.importc: "struct $1".} = object
  wl_buffer* {.importc: "struct $1".} = object
  wl_seat* {.importc: "struct $1".} = object
  wl_output* {.importc: "struct $1".} = object
  wl_pointer* {.importc: "struct $1".} = object
  wl_callback* {.importc: "struct $1".} = object
  wl_keyboard* {.importc: "struct $1".} = object
  wl_data_offer* {.importc: "struct $1".} = object
  wl_data_source* {.importc: "struct $1".} = object
  wl_data_device* {.importc: "struct $1".} = object
  wl_data_device_manager* {.importc: "struct $1".} = object

  wl_pointer_listener* {.importc: "struct $1".} = object
    enter*: proc(
      data: pointer,
      pntr: ptr wl_pointer,
      serial: uint32,
      surf: ptr wl_surface,
      surfaceX, surfaceY: wl_fixed,
    ) {.cdecl.}
    leave*: proc(
      data: pointer, pntr: ptr wl_pointer, serial: uint32, surf: ptr wl_surface
    ) {.cdecl.}
    motion*: proc(
      data: pointer, pntr: ptr wl_pointer, time: uint32, surfaceX, surfaceY: wl_fixed
    ) {.cdecl.}
    button*: proc(
      data: pointer, pntr: ptr wl_pointer, serial, time, button, state: uint32
    ) {.cdecl.}
    axis*: proc(
      data: pointer, pntr: ptr wl_pointer, time, axis: uint32, value: wl_fixed
    ) {.cdecl.}
    frame*: proc(data: pointer, pntr: ptr wl_pointer) {.cdecl.}
    axis_source*:
      proc(data: pointer, pntr: ptr wl_pointer, axisSource: uint32) {.cdecl.}
    axis_stop*: proc(data: pointer, pntr: ptr wl_pointer, time, axis: uint32) {.cdecl.}
    axis_discrete*:
      proc(data: pointer, pntr: ptr wl_pointer, axis: uint32, discrete: int32) {.cdecl.}
    axis_value120*:
      proc(data: pointer, pntr: ptr wl_pointer, axis: uint32, value120: int32) {.cdecl.}
    axis_relative_direction*: proc(
      data: pointer, pntr: ptr wl_pointer, axis: uint32, direction: uint32
    ) {.cdecl.}

  wl_callback_listener* {.importc: "struct $1".} = object
    done*:
      proc(data: pointer, callback: ptr wl_callback, callback_data: uint32) {.cdecl.}

  wl_seat_listener* {.importc: "struct $1".} = object
    capabilities*:
      proc(data: pointer, seat: ptr wl_seat, capabilities: uint32) {.cdecl.}
    name*: proc(data: pointer, seat: ptr wl_seat, name: cstring) {.cdecl.}

  wl_keyboard_listener* {.importc: "struct $1".} = object
    keymap*: proc(
      data: pointer, keyb: ptr wl_keyboard, fmt: uint32, fd: int32, size: uint32
    ) {.cdecl.}
    enter*: proc(
      data: pointer,
      keyb: ptr wl_keyboard,
      serial: uint32,
      surf: ptr wl_surface,
      keys: ptr wl_array,
    ) {.cdecl.}
    leave*: proc(
      data: pointer, keyb: ptr wl_keyboard, serial: uint32, surf: ptr wl_surface
    ) {.cdecl.}
    key*: proc(
      data: pointer,
      keyb: ptr wl_keyboard,
      serial: uint32,
      time: uint32,
      key: uint32,
      state: uint32,
    ) {.cdecl.}
    modifiers*: proc(
      data: pointer,
      keyb: ptr wl_keyboard,
      serial: uint32,
      modsDepressed: uint32,
      modsLatched: uint32,
      modsLocked: uint32,
      group: uint32,
    ) {.cdecl.}
    repeat_info*:
      proc(data: pointer, keyb: ptr wl_keyboard, rate: int32, delay: int32) {.cdecl.}

  wl_buffer_listener* {.importc: "struct $1".} = object
    release*: proc(data: pointer, buffer: ptr wl_buffer) {.cdecl.}

  wl_data_offer_listener* {.importc: "struct $1".} = object
    offer*: proc(data: pointer, offer: ptr wl_data_offer, mimeType: ConstCStr) {.cdecl.}
    source_actions*:
      proc(data: pointer, offer: ptr wl_data_offer, actions: uint32) {.cdecl.}
    action*: proc(data: pointer, offer: ptr wl_data_offer, dndAction: uint32) {.cdecl.}

  wl_data_source_listener* {.importc: "struct $1".} = object
    target*:
      proc(data: pointer, source: ptr wl_data_source, mimeType: ConstCStr) {.cdecl.}
    send*: proc(
      data: pointer, source: ptr wl_data_source, mimeType: ConstCStr, fd: int32
    ) {.cdecl.}
    cancelled*: proc(data: pointer, source: ptr wl_data_source) {.cdecl.}
    dnd_drop_performed*: proc(data: pointer, source: ptr wl_data_source) {.cdecl.}
    dnd_finished*: proc(data: pointer, source: ptr wl_data_source) {.cdecl.}
    action*:
      proc(data: pointer, source: ptr wl_data_source, dndAction: uint32) {.cdecl.}

  wl_data_device_listener* {.importc: "struct $1".} = object
    data_offer*: proc(
      data: pointer, source: ptr wl_data_device, offer: ptr wl_data_offer
    ) {.cdecl.}
    enter*: proc(
      data: pointer,
      source: ptr wl_data_device,
      serial: uint32,
      surface: ptr wl_surface,
      x, y: wl_fixed,
      offer: ptr wl_data_offer,
    ) {.cdecl.}
    leave*: proc(data: pointer, source: ptr wl_data_device) {.cdecl.}
    motion*: proc(
      data: pointer, source: ptr wl_data_device, serial: uint32, x, y: wl_fixed
    ) {.cdecl.}
    drop*: proc(data: pointer, source: ptr wl_data_device) {.cdecl.}
    selection*: proc(
      data: pointer, source: ptr wl_data_device, offer: ptr wl_data_offer
    ) {.cdecl.}

{.push importc.}

let
  WL_REGISTRY_BIND*: int32
  WL_REGISTRY_GLOBAL_SINCE_VERSION*: int32
  WL_REGISTRY_GLOBAL_REMOVE_SINCE_VERSION*: int32
  WL_REGISTRY_BIND_SINCE_VERSION*: int32

# Core Wayland protocol routines
proc wl_display_get_registry*(d: ptr wl_display): ptr wl_registry

proc wl_registry_add_listener*(
  reg: ptr wl_registry, listener: ptr wl_registry_listener, data: pointer
): int32

proc wl_registry_bind*(
  reg: ptr wl_registry, name: uint32, iface: ptr wl_interface, version: uint32
): pointer

proc wl_registry_destroy*(reg: ptr wl_registry)

proc wl_compositor_create_surface*(comp: ptr wl_compositor): ptr wl_surface
proc wl_compositor_create_region*(comp: ptr wl_compositor): ptr wl_region
proc wl_compositor_destroy*(comp: ptr wl_compositor)

proc wl_surface_destroy*(surf: ptr wl_surface)
proc wl_surface_damage*(surf: ptr wl_surface, x, y, w, h: int32)
proc wl_surface_commit*(surf: ptr wl_surface)
proc wl_surface_attach*(surf: ptr wl_surface, buffer: ptr wl_buffer, x, y: int32)
proc wl_surface_frame*(surf: ptr wl_surface): ptr wl_callback

proc wl_region_destroy*(r: ptr wl_region)
proc wl_region_add*(r: ptr wl_region, x, y, w, h: int32)
proc wl_region_subtract*(r: ptr wl_region, x, y, w, h: int32)

proc wl_shm_set_user_data*(s: ptr wl_shm, data: pointer)
proc wl_shm_get_user_data*(s: ptr wl_shm): pointer
proc wl_shm_get_version*(s: ptr wl_shm): uint32
proc wl_shm_destroy*(s: ptr wl_shm)
proc wl_shm_create_pool*(s: ptr wl_shm, fd: int32, size: int32): ptr wl_shm_pool
proc wl_shm_release*(s: ptr wl_shm)

proc wl_shm_pool_set_user_data*(p: ptr wl_shm_pool, data: pointer)
proc wl_shm_pool_get_user_data*(p: ptr wl_shm_pool): pointer
proc wl_shm_pool_get_version*(p: ptr wl_shm_pool): uint32
proc wl_shm_pool_create_buffer*(
  p: ptr wl_shm_pool, offset: int32, width, height: int32, stride: int32, format: uint32
): ptr wl_buffer

proc wl_shm_pool_destroy*(p: ptr wl_shm_pool)
proc wl_shm_pool_resize*(p: ptr wl_shm_pool, size: int32)

proc wl_buffer_destroy*(b: ptr wl_buffer)
proc wl_buffer_add_listener*(
  b: ptr wl_buffer, l: ptr wl_buffer_listener, data: pointer
): int32

proc wl_pointer_add_listener*(
  p: ptr wl_pointer, listener: ptr wl_pointer_listener, data: pointer
): int32

proc wl_pointer_release*(p: ptr wl_pointer)

proc wl_seat_get_pointer*(s: ptr wl_seat): ptr wl_pointer
proc wl_seat_get_keyboard*(s: ptr wl_seat): ptr wl_keyboard
proc wl_seat_release*(s: ptr wl_seat)
proc wl_seat_add_listener*(
  s: ptr wl_seat, listener: ptr wl_seat_listener, data: pointer
): int32

proc wl_callback_add_listener*(
  cb: ptr wl_callback, listener: ptr wl_callback_listener, data: pointer
): int32

proc wl_callback_destroy*(cb: ptr wl_callback)

proc wl_keyboard_release*(keyb: ptr wl_keyboard)
proc wl_keyboard_add_listener*(
  keyb: ptr wl_keyboard, listener: ptr wl_keyboard_listener, data: pointer
): int32

proc wl_data_device_manager_create_data_source*(
  mgr: ptr wl_data_device_manager
): ptr wl_data_source

proc wl_data_device_manager_get_data_device*(
  mgr: ptr wl_data_device_manager, seat: ptr wl_seat
): ptr wl_data_device

proc wl_data_source_destroy*(src: ptr wl_data_source)
proc wl_data_source_offer*(src: ptr wl_data_source, mimeType: cstring)
proc wl_data_source_set_actions*(src: ptr wl_data_source, dndActions: uint32)
proc wl_data_source_add_listener*(
  src: ptr wl_data_source, listener: ptr wl_data_source_listener, cookie: pointer
): int32

proc wl_data_device_start_drag*(
  dev: ptr wl_data_device,
  src: ptr wl_data_source,
  origin, icon: ptr wl_surface,
  serial: uint32,
)

proc wl_data_device_set_selection*(
  dev: ptr wl_data_device, src: ptr wl_data_source, serial: uint32
)

proc wl_data_device_add_listener*(
  o: ptr wl_data_device, l: ptr wl_data_device_listener, data: pointer
): int32

proc wl_data_device_release*(dev: ptr wl_data_device)

proc wl_data_offer_destroy*(offer: ptr wl_data_offer)
proc wl_data_offer_accept*(offer: ptr wl_data_offer, serial: uint32, mime: cstring)
proc wl_data_offer_receive*(offer: ptr wl_data_offer, mime: cstring, fd: int32)
proc wl_data_offer_finish*(offer: ptr wl_data_offer)
proc wl_data_offer_set_actions*(
  offer: ptr wl_data_offer, dndActions, preferredActions: uint32
)

proc wl_data_offer_add_listener*(
  o: ptr wl_data_offer, l: ptr wl_data_offer_listener, data: pointer
): int32

# Core Wayland protocol interfaces
let wl_compositor_interface*: wl_interface
let wl_shm_interface*: wl_interface
let wl_seat_interface*: wl_interface

{.pop.}

{.pop.}

func toInt*(fixed: wl_fixed): int {.inline.} =
  int(fixed / 256)

func toFloat*(fixed: wl_fixed): float {.inline.} =
  fixed / 256

export LibwaylandCflags, LibwaylandLibs
