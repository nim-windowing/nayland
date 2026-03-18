## Prelude file to import the entirity of the Wayland core protocol
import
  pkg/nayland/types/protocols/core/[
    buffer, callback, compositor, data_device, data_device_manager, data_offer,
    data_source, keyboard, pointer, region, registry, seat, shm, shm_pool, surface,
  ]

export
  buffer, callback, compositor, data_device, data_device_manager, data_offer,
  data_source, keyboard, pointer, region, registry, seat, shm, shm_pool, surface
