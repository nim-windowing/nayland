## ===================
## zwlr_layer_shell_v1
## ===================
## **version 5**
## Create surfaces that are layers of the desktop
## 
## Clients can use this interface to assign the surface_layer role to wl_surfaces. Such surfaces are assigned to a "layer" of the output and rendered with a defined z-depth respective to each other. They may also be anchored to the edges and corners of a screen and specify input handling semantics. This interface should be suitable for the implementation of many desktop shell components, and a broad number of other applications that interact with the desktop.
import
  pkg/nayland/types/protocols/wlr/layer_shell/[constants, shell, surface],
  pkg/nayland/types/protocols/xdg_shell/prelude
    # HACK: Required because wlr-layer-shell pulls in the interface for xdg-popup, which in turn requires compiling the private code for xdg-shell.

export constants, shell, surface
