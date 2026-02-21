## ===========================
## zxdg_decoration_manager_v1
## ===========================
## **version 2**
##
## Window decoration manager
## 
## This interface allows a compositor to announce support for server-side decorations.
## 
## A window decoration is a set of window controls as deemed appropriate by the party managing them, such as user interface components used to move, resize and change a window's state.
## 
## A client can use this protocol to request being decorated by a supporting compositor.
## 
## If compositor and client do not negotiate the use of a server-side decoration using this protocol, clients continue to self-decorate as they see fit.
import pkg/nayland/types/protocols/xdg_decoration/[manager, toplevel_decoration]

export manager, toplevel_decoration
