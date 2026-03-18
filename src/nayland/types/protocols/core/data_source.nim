## Wrapper around `wl_data_source`
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import pkg/nayland/bindings/protocols/core, pkg/nayland/bindings/libwayland

type
  DataSourceObj = object
    handle*: ptr wl_data_source
    payload: DataSourcePayload

  DataSourceTargetCallback = proc(source: DataSource, mimeType: string)
  DataSourceSendCallback = proc(source: DataSource, mimeType: string, fd: int32)
  DataSourceCancelledCallback = proc(source: DataSource)
  DataSourceDNDDropPerformedCallback = DataSourceCancelledCallback
  DataSourceDNDFinishedCallback = DataSourceCancelledCallback
  DataSourceActionCallback = proc(source: DataSource, action: DNDAction)

  DataSourcePObj = object
    targetCb*: DataSourceTargetCallback
    sendCb*: DataSourceSendCallback
    cancelledCb*: DataSourceCancelledCallback
    dndDropPerformedCb*: DataSourceDNDDropPerformedCallback
    dndFinishedCb*: DataSourceDNDFinishedCallback
    actionCb*: DataSourceActionCallback

  DataSourcePayload = ref DataSourcePObj

  DNDAction* {.pure, size: sizeof(uint32).} = enum
    None = 0
    Copy = 1
    Move = 2
    Ask = 4

  DataSource* = ref DataSourceObj

proc `=destroy`*(source: DataSourceObj) =
  wl_data_source_destroy(source.handle)

func newDataSource*(handle: ptr wl_data_source): DataSource {.inline.} =
  DataSource(handle: handle, payload: DatasourcePayload())

let listener = wl_data_source_listener(
  target: proc(
      data: pointer, source: ptr wl_data_source, mimeType: ConstCStr
  ) {.cdecl.} =
    let payload = cast[DataSourcePayload](data)
    payload.targetCb(newDataSource(source), $mimeType),
  send: proc(
      data: pointer, source: ptr wl_data_source, mimeType: ConstCStr, fd: int32
  ) {.cdecl.} =
    let payload = cast[DataSourcePayload](data)
    payload.sendCb(newDataSource(source), $mimeType, fd),
  cancelled: proc(data: pointer, source: ptr wl_data_source) {.cdecl.} =
    let payload = cast[DataSourcePayload](data)
    payload.cancelledCb(newDataSource(source)),
  dnd_drop_performed: proc(data: pointer, source: ptr wl_data_source) {.cdecl.} =
    let payload = cast[DataSourcePayload](data)
    payload.dndDropPerformedCb(newDataSource(source)),
  dnd_finished: proc(data: pointer, source: ptr wl_data_source) {.cdecl.} =
    let payload = cast[DataSourcePayload](data)
    payload.dndFinishedCb(newDataSource(source)),
  action: proc(data: pointer, source: ptr wl_data_source, dndAction: uint32) {.cdecl.} =
    let payload = cast[DataSourcePayload](data)
    payload.actionCb(newDataSource(source), cast[DNDAction](dndAction)),
)

func `onTarget=`*(source: DataSource, cb: DataSourceTargetCallback) =
  source.payload.targetCb = cb

func `onSend=`*(source: DataSource, cb: DataSourceSendCallback) =
  source.payload.sendCb = cb

func `onCancelled=`*(source: DataSource, cb: DataSourceCancelledCallback) =
  source.payload.cancelledCb = cb

func `onDndDropPerformed=`*(
    source: DataSource, cb: DataSourceDNDDropPerformedCallback
) =
  source.payload.dndDropPerformedCb = cb

func `onDndFinished=`*(source: DataSource, cb: DataSourceDNDFinishedCallback) =
  source.payload.dndFinishedCb = cb

func `onAction=`*(source: DataSource, cb: DataSourceActionCallback) =
  source.payload.actionCb = cb

proc attachCallbacks*(source: DataSource) =
  discard wl_data_source_add_listener(
    source.handle, listener.addr, cast[pointer](source.payload)
  )

proc offer*(source: DataSource, mime: string) =
  wl_data_source_offer(source.handle, cstring(mime))

proc setActions*(source: DataSource, actions: set[DNDAction]) =
  wl_data_source_set_actions(source.handle, cast[uint32](actions))
