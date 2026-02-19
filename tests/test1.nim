import std/[tables, posix, options]
import
  pkg/nayland/types/display,
  pkg/nayland/types/protocols/core/[
    buffer, callback, compositor, keyboard, pointer, registry, seat, shm, shm_pool,
    surface,
  ],
  pkg/nayland/bindings/protocols/[core, xdg_shell, fractional_scale_v1],
  pkg/nayland/types/protocols/xdg_shell/[wm_base, xdg_surface, xdg_toplevel],
  pkg/nayland/types/protocols/fractional_scale/prelude
import pkg/pretty

let disp = connectDisplay()
let reg = initRegistry(disp)

echo "roundtrip: " & $disp.roundtrip()

assert "wl_seat" in reg
assert "wl_skibidi" notin reg

for id in reg:
  echo id

let compIface = reg["wl_compositor"]
let comp = initCompositor(
  reg.bindInterface(compIface.name, wl_compositor_interface.addr, compIface.version)
)

let shmIface = reg["wl_shm"]
let shmi =
  initShm(reg.bindInterface(shmIface.name, wl_shm_interface.addr, shmIface.version))

let wmBaseIface = reg["xdg_wm_base"]
let wm = initWmBase(
  reg.bindInterface(wmBaseIface.name, xdg_wm_base_interface.addr, wmBaseIface.version)
)

let fracScale = reg["wp_fractional_scale_manager_v1"]
let fracManager = initFractionalScaleManager(
  reg.bindInterface(
    fracScale.name, wp_fractional_scale_manager_v1_interface.addr, fracScale.version
  )
)

let seatIface = reg["wl_seat"]
let seatObj =
  initSeat(reg.bindInterface(seatIface.name, wl_seat_interface.addr, seatIface.version))

let pointr = get seatObj.getPointer() # internal pointer variable moment
pointr.onEnter = proc(pntr: Pointer, serial: uint32, surface: Surface, sx, sy: float) =
  echo "oh my god the user entered this surface woaaa!!!"
  echo "local X: " & $sx & ", local Y: " & $sy

pointr.onMotion = proc(pntr: Pointer, time: uint32, sx, sy: float) =
  echo "motion event (local x: " & $sx & "; local y: " & $sy & ')'

pointr.onFrame = proc(pntr: Pointer) =
  echo "pointer frame event"

pointr.onLeave = proc(pntr: Pointer, serial: uint32, surface: Surface) =
  echo "please wayland i need this, my surface kinda focusless"

pointr.onAxis = proc(pntr: Pointer, time, axis: uint32, value: float) =
  echo "axis event, time=" & $time & "; axis=" & $axis & "; value=" & $value

pointr.attachCallbacks()

let keyb = get seatObj.getKeyboard()
keyb.onKeymap = proc(keyb: Keyboard, fmt: uint32, fd: int32, size: uint32) =
  echo "Compositor sent keymap (fmt=" & $fmt & "; fd=" & $fd & "; size=" & $size & ')'

keyb.onEnter = proc(
    keyb: Keyboard, serial: uint32, surface: Surface, keys: seq[uint32]
) =
  echo "User is now focusing on surface!!!"
  echo keys

keyb.onLeave = proc(keyb: Keyboard, serial: uint32, surface: Surface) =
  echo "User is no longer focusing on surface"

keyb.onKey = proc(
    keyb: Keyboard, serial: uint32, time: uint32, key: uint32, state: uint32
) =
  echo "Key event (serial=" & $serial & "; time=" & $time & "; key=" & $key & "; state=" &
    $state & ')'

keyb.onModifiers = proc(
    keyb: Keyboard,
    serial: uint32,
    modsDepressed, modsLatched, modsLocked, group: uint32,
) =
  discard

keyb.onRepeatInfo = proc(keyb: Keyboard, rate, delay: int32) =
  echo "Repeat info received (rate=" & $rate & "; delay=" & $delay & ')'

keyb.attachCallbacks()

let surf = comp.createSurface()
disp.roundtrip()

const poolsize = 32 * 32 * 4

var MFD_CLOEXEC {.importc, header: "<sys/mman.h>".}: uint32
proc memfd_create(
  name: cstring, flags: uint32
): int32 {.importc, header: "<sys/mman.h>".}

let fd = memfd_create("nayland-shmpool", MFD_CLOEXEC)
discard ftruncate(fd, Off(poolsize))
echo "nayland-shmpool -> " & $fd

let pool = get shmi.createPool(fd, poolsize)
let buff = pool.createBuffer(0, 32, 32, 32 * 4, ShmFormat.ARGB8888)
roundtrip disp

let scale = fracManager.getFractionalScale(surf)
scale.onPreferredScale = proc(scale: uint32) =
  echo "got preferred output scale: " & $scale

scale.attachCallbacks()

let xsurf = get wm.getXDGSurface(surf)
let toplevel = get xsurf.getToplevel()
wm.attachCallbacks()

xsurf.onConfigure = proc(surface: XDGSurface, data: pointer, serial: uint32) =
  surface.ackConfigure(serial)

xsurf.attachCallbacks()

commit surf

roundtrip disp

toplevel.title = "Hello Nayland!"
toplevel.appId = "xyz.xtrayambak.nayland"

toplevel.onConfigure = proc(toplevel: XDGToplevel, width, height: int32) =
  echo "Configure XDGToplevel; width=" & $width & ", height=" & $height

const maxFrames = 200
var running = true
var frameCount = 0
toplevel.onClose = proc(toplevel: XDGToplevel) =
  echo "User wants to close XDGToplevel"
  running = false

toplevel.attachCallbacks()

let buffr = get buff
buffr.onRelease = proc(_: Buffer) =
  discard # echo "Release Buffer"

buffr.attachCallbacks()

surf.attach(buffr, 0, 0)
surf.damage(0, 0, 32, 32)
surf.commit()

proc onFrameCb(callback: Callback, surf: pointer, data: uint32) {.cdecl.} =
  let surf = cast[Surface](surf)
  if not running:
    return
  inc frameCount
  if frameCount >= maxFrames:
    running = false
    return
  surf.frame.listen(cast[pointer](surf), onFrameCb)

  surf.attach(get buff, 0, 0)
  surf.damage(0, 0, 32, 32)
  surf.commit()

surf.frame.listen(cast[pointer](surf), onFrameCb)
commit surf

while running:
  disp.roundtrip()
