## Display type, wraps `wl_display`
##
## Copyright (C) 2025 Trayambak Rai (xtrayambak at disroot dot org)
import std/[options, posix]
import pkg/nayland/bindings/libwayland, pkg/nayland/types/event_queue

type
  DisplayError* = object of IOError
  CannotConnect* = object of DisplayError
  FlushError* = object of DisplayError
    flushErrorCode*: int32

  RoundtripError* = object of DisplayError
    roundtripErrorCode*: int32

  DisplayObj = object
    handle*: ptr wl_display

  Display* = ref DisplayObj

proc disconnect*(disp: DisplayObj) {.sideEffect, raises: [], inline.} =
  wl_display_disconnect(disp.handle)

proc `=destroy`*(disp: DisplayObj) =
  if disp.handle == nil:
    return

  disp.disconnect()

{.push inline.}
func fd*(display: DisplayObj | Display): int32 =
  wl_display_get_fd(display.handle)

func error*(display: DisplayObj | Display): int32 =
  wl_display_get_error(display.handle)
{.pop.}

proc connectDisplay*(
    name: Option[string] = none(string)
): Display {.sideEffect, raises: [CannotConnect].} =
  let disp = Display(
    handle: wl_display_connect(
      if isSome(name):
        cstring(name.get())
      else:
        nil
    )
  )

  if disp.handle == nil:
    raise newException(
      CannotConnect,
      "Cannot connect to display! Is a compositor running? (" & $strerror(errno) & ')',
    )

  disp

proc connectDisplay*(fd: int32): Display {.sideEffect, raises: [CannotConnect].} =
  let disp = Display(handle: wl_display_connect_to_fd(fd))

  if disp.handle == nil:
    raise newException(
      CannotConnect,
      "Cannot connect to fd " & $fd &
        ", is a compositor socket actually open on that fd? (" & $strerror(errno) & ')',
    )

  disp

proc dispatch*(disp: Display) {.sideEffect, raises: [].} =
  wl_display_dispatch(disp.handle)

proc flush*(disp: Display): int32 {.sideEffect, discardable, raises: [FlushError].} =
  let res = wl_display_flush(disp.handle)
  if res < 0:
    var exc = newException(
      FlushError,
      "wl_display_flush() returned " & $res & " (" & $strerror(disp.error) & ')',
    )
    exc.flushErrorCode = res

    raise ensureMove(exc)

  res

proc roundtrip*(
    disp: Display
): int32 {.sideEffect, discardable, raises: [RoundtripError].} =
  let res = wl_display_roundtrip(disp.handle)
  if res < 0:
    var exc = newException(
      RoundtripError,
      "wl_display_roundtrip() returned " & $res & " (" & $strerror(disp.error) & ')',
    )
    exc.roundtripErrorCode = res

    raise ensureMove(exc)

  res

proc createQueue*(
    disp: Display, name: Option[string] = none(string)
): EventQueue {.raises: [InvalidQueueHandle].} =
  toEventQueue(wl_display_create_queue(disp.handle))
