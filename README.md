# nayland
Nayland is a library which provides high-level, ergonomic, memory safe* wrappers to the libwayland library's client API.

It aims to make it easier to write Wayland clients in Nim.

# notes
- It is still a heavy work-in-progress.
- This library does not plan to build a high-level windowing abstraction on top of Wayland! It simply provides low-level wrappers over Wayland interfaces.

## generating protocol wrappers
`protocols/bindgen.nim` is your best friend for this. It can take in a `.xml` file, and integrate bindings for it inside `src/nayland/bindings/protocols/`, including private C code.

# installation
You can get Neo [here](https://github.com/xTrayambak/neo). I do not test the Nimble manifest, and I have no plans to provide support for it.

## Neo (recommended)
Inside your project directory, run:
```
$ neo add gh:xTrayambak/nayland
```

## Nimble (NOT RECOMMENDED)
Inside your project directory, run:
```
$ nimble add https://github.com/xTrayambak/nayland
```

# roadmap
## core protocol
- [X] `wl_display`
- [X] `wl_registry`
- [X] `wl_compositor`
- [X] `wl_surface`
- [X] `wl_region`
- [X] `wl_shm`
- [X] `wl_buffer`
- [X] `wl_callback`
- [X] `wl_shm_pool`
- [ ] `wl_data_offer`
- [ ] `wl_data_source`
- [ ] `wl_data_device`
- [ ] `wl_data_device_manager`
- [X] `wl_seat`
- [X] `wl_pointer`
- [ ] `wl_keyboard`
- [ ] `wl_touch`
- [ ] `wl_output`
- [ ] `wl_subcompositor`
- [X] `wl_region`
- [ ] `wl_subsurface`
- [ ] `wl_fixes`

## XDG shell
- [X] `xdg_wm_base`
- [ ] `xdg_positioner`
- [X] `xdg_surface`
- [X] `xdg_toplevel`
- [ ] `xdg_popup`

## linux DMA-BUF
- [ ] `zwp_linux_dmabuf_v1`
- [ ] `zwp_linux_buffer_params_v1`
- [ ] `zwp_linux_dmabuf_feedback_v1`
