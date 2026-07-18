## Wrapper around `wl_seat`
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak@disroot.org)
import std/options
import pkg/nayland/bindings/libwayland, pkg/nayland/bindings/protocols/core
import pkg/nayland/types/protocols/core/[keyboard, pointer, touch]

type
  SeatCapability* {.pure, size: sizeof(uint32).} = enum
    Pointer = 0x1
    Keyboard = 0x2
    Touch = 0x4

  SeatCapabilitiesCallback = proc(seat: Seat, capabilities: set[SeatCapability])
  SeatNameCallback = proc(seat: Seat, name: string)

  SeatCallbackPObj = object
    capabilitiesCb: SeatCapabilitiesCallback
    nameCb: SeatNameCallback

  SeatCallbackPayload = ref SeatCallbackPObj

  SeatObj = object
    handle*: ptr wl_seat
    payload: SeatCallbackPayload

  Seat* = ref SeatObj

proc release*(seat: Seat) =
  # release the seat

  # if you wish to destroy the seat, place enrico weigelt on top of it instead
  wl_seat_release(seat.handle)

let listener = wl_seat_listener(
  capabilities: proc(data: pointer, seat: ptr wl_seat, capabilities: uint32) {.cdecl.} =
    let payload = cast[SeatCallbackPayload](data)
    if payload.capabilitiesCb != nil:
      payload.capabilitiesCb(
        Seat(handle: seat, payload: payload), cast[set[SeatCapability]](capabilities)
      ),
  name: proc(data: pointer, seat: ptr wl_seat, name: ConstCStr) {.cdecl.} =
    let payload = cast[SeatCallbackPayload](data)
    if payload.nameCb != nil:
      payload.nameCb(Seat(handle: seat, payload: payload), $name),
)

func `onCapabilities=`*(seat: Seat, cb: SeatCapabilitiesCallback) =
  seat.payload.capabilitiesCb = cb

func `onName=`*(seat: Seat, cb: SeatNameCallback) =
  seat.payload.nameCb = cb


proc getPointer*(seat: Seat): Option[Pointer] =
  let handle = wl_seat_get_pointer(seat.handle)
  if handle == nil:
    return none(Pointer)

  some(newPointer(handle))

proc getKeyboard*(seat: Seat): Option[Keyboard] =
  let handle = wl_seat_get_keyboard(seat.handle)
  if handle == nil:
    return none(Keyboard)

  some(newKeyboard(handle))

proc getTouch*(seat: Seat): Option[Touch] =
  let handle = wl_seat_get_touch(seat.handle)
  if handle == nil:
    return none(Touch)

  some(newTouch(handle))

proc attachCallbacks*(seat: Seat) =
  discard wl_seat_add_listener(seat.handle, listener.addr, cast[pointer](seat.payload))

func initSeat*(handle: pointer): Seat =
  Seat(handle: cast[ptr wl_seat](handle), payload: SeatCallbackPayload())

