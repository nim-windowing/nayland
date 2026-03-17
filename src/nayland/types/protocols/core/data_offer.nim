## Wrapper around `wl_data_offer`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/core
import pkg/nayland/types/protocols/core/data_source

type
  DataOfferObj = object
    handle: ptr wl_data_offer

  DataOffer* = ref DataOfferObj

proc `=destroy`*(offer: DataOfferObj) =
  wl_data_offer_destroy(offer.handle)

proc accept*(offer: DataOffer, serial: uint32, mimeType: string) =
  wl_data_offer_accept(offer.handle, serial, cstring(mimeType))

proc receive*(offer: DataOffer, mimeType: string, fd: int32) =
  wl_data_offer_receive(offer.handle, cstring(mimeType), fd)

proc finish*(offer: DataOffer) =
  wl_data_offer_finish(offer.handle)

proc setActions*(offer: DataOffer, dndActions, preferredActions: set[DNDAction]) =
  wl_data_offer_set_actions(
    offer.handle, cast[uint32](dndActions), cast[uint32](preferredActions)
  )
