import std/[tables, posix, options]
import
  pkg/nayland/types/display,
  pkg/nayland/types/protocols/core/
    [buffer, callback, pointer, registry, seat, compositor, shm, shm_pool, surface],
  pkg/nayland/bindings/protocols/[core, xdg_shell],
  pkg/nayland/types/protocols/xdg_shell/[wm_base, xdg_surface, xdg_toplevel]
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

let surf = comp.createSurface()
disp.roundtrip()

const poolsize = 32 * 32

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

surf.attach(get buff, 0, 0)
surf.damage(0, 0, 32, 32)
surf.commit()

proc onFrameCb(callback: Callback, surf: pointer, data: uint32) =
  echo "urf urf urf urf urf"
  destroy callback
  let surf = cast[Surface](surf)
  surf.frame.listen(cast[pointer](surf), onFrameCb)

  surf.attach(get buff, 0, 0)
  surf.damage(0, 0, 32, 32)
  surf.commit()

surf.frame.listen(cast[pointer](surf), onFrameCb)
commit surf

while true:
  disp.roundtrip()
