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

proc newDataOffer*(handle: ptr wl_data_offer): DataOffer {.inline.}

let listener = wl_data_offer_listener(
  offer: proc(data: pointer, offer: ptr wl_data_offer, mime: ConstCStr) {.cdecl.} =
    let payload = cast[DataOfferPayload](data)
    if payload.offerCb != nil:
      payload.offerCb(newDataOffer(offer), $mime),
  source_actions: proc(
      data: pointer, offer: ptr wl_data_offer, actions: uint32
  ) {.cdecl.} =
    let payload = cast[DataOfferPayload](data)
    if payload.sourceActionsCb != nil:
      payload.sourceActionsCb(newDataOffer(offer), cast[set[DNDAction]](actions)),
  action: proc(data: pointer, offer: ptr wl_data_offer, dndAction: uint32) {.cdecl.} =
    let payload = cast[DataOfferPayload](data)
    if payload.actionCb != nil:
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

proc attachCallbacks*(offer: DataOffer) {.deprecated: "callbacks are attached automatically now; this call is a no-op and safe to remove".} =
  discard

proc setActions*(offer: DataOffer, dndActions, preferredActions: set[DNDAction]) =
  wl_data_offer_set_actions(
    offer.handle, cast[uint32](dndActions), cast[uint32](preferredActions)
  )

proc newDataOffer*(handle: ptr wl_data_offer): DataOffer {.inline.} =
  result = DataOffer(handle: handle, payload: DataOfferPayload())
  discard wl_data_offer_add_listener(
    result.handle, listener.addr, cast[pointer](result.payload)
  )
