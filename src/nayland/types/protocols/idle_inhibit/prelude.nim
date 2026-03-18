## ============================
## zwp_idle_inhibit_manager_v1
## ============================
## **version 1**
##
## Control behavior when display idles
## 
## This interface permits inhibiting the idle behavior such as screen blanking, locking, and screensaving. The client binds the idle manager globally, then creates idle-inhibitor objects for each surface.
## 
## **Warning**: The protocol described in this file is experimental and backward incompatible changes may be made. Backward compatible changes may be added together with the corresponding interface version bump. Backward incompatible changes are done by bumping the version number in the protocol and interface names and resetting the interface version. Once the protocol is to be declared stable, the 'z' prefix and the version number in the protocol and interface names are removed and the interface version number is reset.
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/types/protocols/idle_inhibit/[inhibitor, inhibit_manager]

export inhibitor, inhibit_manager
