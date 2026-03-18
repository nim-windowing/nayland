## Wrapper around `wl_data_offer`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/core, pkg/nayland/bindings/libwayland
import pkg/nayland/types/protocols/core/data_source

type
  DataOfferObj = object
    handle: ptr wl_data_offer
    payload: DataOfferPayload

  DataOfferOfferCallback = proc(offer: DataOffer, mimeType: string)
  DataOfferSourceActionsCallback = proc(offer: DataOffer, actions: set[DNDAction])
  DataOfferActionCallback = proc(offer: DataOffer, dndAction: set[DNDAction])
    # TODO: is this a bitset or just a singular DNDAction?

  DataOfferPObj = object
    offerCb*: DataOfferOfferCallback
    sourceActionsCb*: DataOfferSourceActionsCallback
    actionCb*: DataOfferActionCallback

  DataOfferPayload = ref DataOfferPObj

  DataOffer* = ref DataOfferObj

proc `=destroy`*(offer: DataOfferObj) =
  wl_data_offer_destroy(offer.handle)

func newDataOffer*(handle: ptr wl_data_offer): DataOffer {.inline.} =
  DataOffer(handle: handle, payload: DataOfferPayload())

let listener = wl_data_offer_listener(
  offer: proc(data: pointer, offer: ptr wl_data_offer, mime: ConstCStr) {.cdecl.} =
    let payload = cast[DataOfferPayload](data)
    payload.offerCb(newDataOffer(offer), $mime),
  source_actions: proc(
      data: pointer, offer: ptr wl_data_offer, actions: uint32
  ) {.cdecl.} =
    let payload = cast[DataOfferPayload](data)
    payload.sourceActionsCb(newDataOffer(offer), cast[set[DNDAction]](actions)),
  action: proc(data: pointer, offer: ptr wl_data_offer, dndAction: uint32) {.cdecl.} =
    let payload = cast[DataOfferPayload](data)
    payload.actionCb(newDataOffer(offer), cast[set[DNDAction]](dndAction)),
)

proc accept*(offer: DataOffer, serial: uint32, mimeType: string) =
  wl_data_offer_accept(offer.handle, serial, cstring(mimeType))

proc receive*(offer: DataOffer, mimeType: string, fd: int32) =
  wl_data_offer_receive(offer.handle, cstring(mimeType), fd)

proc finish*(offer: DataOffer) =
  wl_data_offer_finish(offer.handle)

func `onOffer=`*(offer: DataOffer, cb: DataOfferOfferCallback) =
  offer.payload.offerCb = cb

func `onSourceActions=`*(offer: DataOffer, cb: DataOfferSourceActionsCallback) =
  offer.payload.sourceActionsCb = cb

func `onAction=`*(offer: DataOffer, cb: DataOfferActionCallback) =
  offer.payload.actionCb = cb

proc attachCallbacks*(offer: DataOffer) =
  discard wl_data_offer_add_listener(
    offer.handle, listener.addr, cast[pointer](offer.payload)
  )

proc setActions*(offer: DataOffer, dndActions, preferredActions: set[DNDAction]) =
  wl_data_offer_set_actions(
    offer.handle, cast[uint32](dndActions), cast[uint32](preferredActions)
  )
