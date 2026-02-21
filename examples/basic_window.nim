import std/[options, posix]
import
  pkg/nayland/types/display,
  pkg/nayland/types/protocols/core/[compositor, registry, shm, shm_pool, surface],
  pkg/nayland/bindings/protocols/[core, xdg_shell, xdg_decoration_unstable_v1],
  pkg/nayland/types/protocols/xdg_shell/[wm_base, xdg_surface, xdg_toplevel]

const
  width = 320
  height = 240
  stride = width * 4
  poolSize = stride * height

var MFD_CLOEXEC {.importc, header: "<sys/mman.h>".}: uint32
proc memfd_create(
  name: cstring, flags: uint32
): int32 {.importc, header: "<sys/mman.h>".}

let disp = connectDisplay()
let reg = initRegistry(disp)
discard disp.roundtrip()

let compIface = reg["wl_compositor"]
let comp = initCompositor(
  reg.bindInterface(compIface.name, wl_compositor_interface.addr, compIface.version)
)

let shmIface = reg["wl_shm"]
let shmObj = initShm(
  reg.bindInterface(shmIface.name, wl_shm_interface.addr, shmIface.version)
)

let wmIface = reg["xdg_wm_base"]
let wm = initWMBase(
  reg.bindInterface(wmIface.name, xdg_wm_base_interface.addr, wmIface.version)
)
wm.attachCallbacks()

let surf = comp.createSurface()
let xdgSurf = get wm.getXDGSurface(surf)
let toplevel = get xdgSurf.getToplevel()

var running = true
toplevel.onConfigure = proc(_: XDGToplevel, width, height: int32) =
  discard
toplevel.onClose = proc(_: XDGToplevel) =
  running = false
toplevel.attachCallbacks()

toplevel.title = "Nayland Example"
toplevel.appId = "org.nayland.example"

let fd = memfd_create("nayland-example-shm", MFD_CLOEXEC)
if fd < 0:
  quit "memfd_create failed"

discard ftruncate(fd, Off(poolSize))

let map = mmap(
  nil,
  poolSize,
  PROT_READ or PROT_WRITE,
  MAP_SHARED,
  fd,
  0,
)
if map == cast[pointer](-1):
  quit "mmap failed"

let pixels = cast[ptr UncheckedArray[uint32]](map)
let pixelCount = width * height
let color = 0xff243447'u32
for i in 0 ..< pixelCount:
  pixels[i] = color

let pool = get shmObj.createPool(fd, int32(poolSize))
let buffer = get pool.createBuffer(
  0,
  int32(width),
  int32(height),
  int32(stride),
  ShmFormat.ARGB8888,
)

var configured = false
var decorationReady = true
var committed = false
var decorationListener: zxdg_toplevel_decoration_v1_listener
xdgSurf.onConfigure = proc(xdg: XDGSurface, data: pointer, serial: uint32) =
  xdg.ackConfigure(serial)
  configured = true
xdgSurf.attachCallbacks()

if "zxdg_decoration_manager_v1" in reg:
  let decoIface = reg["zxdg_decoration_manager_v1"]
  let decoManager = cast[ptr zxdg_decoration_manager_v1](
    reg.bindInterface(
      decoIface.name, zxdg_decoration_manager_v1_interface.addr, decoIface.version
    )
  )
  let decoration = zxdg_decoration_manager_v1_get_toplevel_decoration(
    decoManager, toplevel.handle
  )
  decorationReady = false
  decorationListener.configure = proc(
      data: pointer,
      _: ptr zxdg_toplevel_decoration_v1,
      mode: uint32,
  ) {.cdecl.} =
    let ready = cast[ptr bool](data)
    ready[] = true
  discard zxdg_toplevel_decoration_v1_add_listener(
    decoration, decorationListener.addr, addr decorationReady
  )
  zxdg_toplevel_decoration_v1_set_mode(
    decoration, cast[uint32](ZXDG_TOPLEVEL_DECORATION_V1_MODE_SERVER_SIDE)
  )

surf.commit()

while running:
  disp.dispatch()
  if configured and decorationReady and not committed:
    committed = true
    surf.attach(buffer, 0, 0)
    surf.damage(0, 0, int32(width), int32(height))
    surf.commit()
