## Wrapper for `zwp_idle_inhibit_manager_v1`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/idle_inhibit_unstable_v1
import
  pkg/nayland/types/protocols/core/surface,
  pkg/nayland/types/protocols/idle_inhibit/inhibitor

type
  InhibitManagerObj = object
    handle*: ptr zwp_idle_inhibit_manager_v1

  InhibitManager* = ref InhibitManagerObj

proc `=destroy`*(mgr: InhibitManagerObj) =
  zwp_idle_inhibit_manager_v1_destroy(mgr.handle)

proc createInhibitor*(manager: InhibitManager, surface: Surface): IdleInhibitor =
  newIdleInhibitor(
    zwp_idle_inhibit_manager_v1_create_inhibitor(manager.handle, surface.handle)
  )

func initInhibitManager*(handle: pointer): InhibitManager {.inline.} =
  InhibitManager(handle: cast[ptr zwp_idle_inhibit_manager_v1](handle))
