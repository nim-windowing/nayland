## Checks whether global wl objects with identical interface names are being registered.
import std/[unittest, sequtils]
import pkg/nayland/types/protocols/core/registry

suite "registry: multiple globals of the same interface":
  test "two wl_output globals":
    var state: RegistryState
    state.registerGlobal(3'u32, "wl_output", 4'u32)
    state.registerGlobal(1'u32, "wl_compositor", 5'u32)
    state.registerGlobal(7'u32, "wl_output", 4'u32)

    let outputs = state.all("wl_output")

    check outputs.len == 2
    check outputs.mapIt(it.name) == @[3'u32, 7'u32]

    check state.all("wl_compositor").len == 1
    check state.all("wl_compositor")[0].name == 1'u32

  test "multiple globals are reachable":
    var state: RegistryState
    state.registerGlobal(3'u32, "wl_output", 4'u32)
    state.registerGlobal(7'u32, "wl_output", 4'u32)

    check "wl_output" in state
    check state.all("wl_output").len == 2
    check state.all("wl_output")[0].name == 3'u32

  test "global_remove":
    var state: RegistryState
    state.registerGlobal(3'u32, "wl_output", 4'u32)
    state.registerGlobal(7'u32, "wl_output", 4'u32)

    state.unregisterGlobal(3'u32)

    let remaining = state.all("wl_output")
    check remaining.len == 1
    check remaining[0].name == 7'u32

    state.unregisterGlobal(7'u32)
    check "wl_output" notin state
