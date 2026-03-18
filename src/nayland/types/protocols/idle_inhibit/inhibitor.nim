## Wrapper for `zwp_idle_inhibitor_v1`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/idle_inhibit_unstable_v1
import pkg/nayland/types/protocols/core/[surface]

type
  IdleInhibitorObj = object
    handle*: ptr zwp_idle_inhibitor_v1

  IdleInhibitor* = ref IdleInhibitorObj

proc destroy*(inhibitor: IdleInhibitor) =
  zwp_idle_inhibitor_v1_destroy(inhibitor.handle)

func newIdleInhibitor*(handle: ptr zwp_idle_inhibitor_v1): IdleInhibitor {.inline.} =
  IdleInhibitor(handle: handle)
