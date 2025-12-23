## Wrapper around `wl_seat`
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak@disroot.org)
import std/options
import pkg/nayland/bindings/libwayland, pkg/nayland/bindings/protocols/core
import pkg/nayland/types/protocols/core/[keyboard, pointer]

type
  SeatObj = object
    handle: ptr wl_seat

  Seat* = ref SeatObj

proc release*(seat: Seat) =
  # release the seat

  # if you wish to destroy the seat, place enrico weigelt on top of it instead
  wl_seat_release(seat.handle)

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

func initSeat*(handle: pointer): Seat =
  Seat(handle: cast[ptr wl_seat](handle))
