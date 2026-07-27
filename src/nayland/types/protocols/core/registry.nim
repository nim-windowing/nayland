## Wrapper around `wl_registry`
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak at disroot dot org)
import std/[options, tables, sequtils]

#!fmt: off
import pkg/nayland/bindings/libwayland,
       pkg/nayland/bindings/protocols/core,
       pkg/nayland/types/display
#!fmt: on

type
  RegistryError* = object of IOError
  CannotGetRegistry* = object of RegistryError

  Interface* = object
    name*: uint32
    version*: uint32

  RegistryState* = object
    interfaces: Table[string, seq[Interface]]
      ## interface name -> every global currently advertised for it.
    ifaceOf: Table[uint32, string]
      ## global id -> interface name, so `unregisterGlobal` (which only
      ## receives the id from `global_remove`) can find its entry

  RegistryObj* = object
    handle*: ptr wl_registry
    state: RegistryState

  Registry* = ref RegistryObj

proc `=destroy`*(reg: RegistryObj) =
  wl_registry_destroy(reg.handle)

proc registerGlobal*(state: var RegistryState, name: uint32, iface: string, version: uint32) =
  ## Adds a newly-announced global.
  state.interfaces.mgetOrPut(iface, @[]).add Interface(name: name, version: version)
  state.ifaceOf[name] = iface

proc unregisterGlobal*(state: var RegistryState, name: uint32) =
  ## Removes a global that the compositor has withdrawn (`global_remove`).
  if name notin state.ifaceOf:
    return
  let iface = state.ifaceOf[name]
  state.ifaceOf.del(name)
  if iface notin state.interfaces:
    return
  state.interfaces[iface].keepItIf(it.name != name)
  if state.interfaces[iface].len == 0:
    state.interfaces.del(iface)

func contains*(state: RegistryState, name: string): bool {.inline, raises: [].} =
  state.interfaces.getOrDefault(name, @[]).len > 0

func all*(state: RegistryState, key: string): seq[Interface] {.inline.} =
  ## Returns every global currently known for this interface name.
  state.interfaces.getOrDefault(key, @[])

iterator pairs*(reg: Registry): tuple[id: string, iface: Interface] =
  for key, values in reg.state.interfaces:
    for value in values:
      yield (id: key, iface: value)

iterator items*(reg: Registry): string =
  for value in reg.state.interfaces.keys:
    yield value

func contains*(reg: Registry, name: string): bool {.inline, raises: [].} =
  name in reg.state

func `[]`*(reg: Registry, key: string): Interface {.inline, raises: [KeyError].} =
  ## Returns the first-announced global for this interface name.
  ##
  ## See also `all`.
  reg.state.interfaces[key][0]

func all*(reg: Registry, key: string): seq[Interface] {.inline.} =
  ## Returns every global currently known for this interface name, e.g.
  ## one entry per connected monitor for `"wl_output"`.
  reg.state.all(key)

func get*(reg: Registry, key: string): Option[Interface] {.inline.} =
  if key in reg:
    return some(reg[key])

  none(Interface)

proc bindInterface*(
    reg: Registry, name: uint32, iface: ptr wl_interface, version: uint32
): pointer =
  wl_registry_bind(reg.handle, name, iface, version)

var listeners = wl_registry_listener(
  global: proc(
      data: pointer,
      reg: ptr wl_registry,
      name: uint32,
      iface: ConstCStr,
      version: uint32,
  ) {.cdecl.} =
    let reg = cast[ptr RegistryObj](data)
    registerGlobal(reg[].state, name, $iface, version),
  global_remove: proc(data: pointer, reg: ptr wl_registry, name: uint32) {.cdecl.} =
    let reg = cast[ptr RegistryObj](data)
    unregisterGlobal(reg[].state, name),
)

proc initRegistry*(display: Display): Registry {.raises: [CannotGetRegistry].} =
  let handle = wl_display_get_registry(display.handle)
  if handle == nil:
    raise newException(CannotGetRegistry, "wl_display_get_registry() returned nil")

  let reg = Registry(handle: handle)
  discard wl_registry_add_listener(handle, listeners.addr, cast[ptr RegistryObj](reg))

  reg
