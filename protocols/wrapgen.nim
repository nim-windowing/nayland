## `wrapgen` parses Wayland protocol XML files to generate high-level, idiomatic wrappers for protocol objects.
## It aims to easen the painful process of writing handrolled wrappers. The generated output will still
## need some work to make it as ergonomic as possible, but it's leaps less work than before.
##
## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)
import
  std/[os, osproc, parsexml, rdstdin, streams, strformat, strutils, sequtils, tables]
import pkg/[shakar]

type
  RequestKind* = enum
    Call
    Destructor = "destructor"

  Arg* = object
    name*: string
    typ*: string
    retval*: bool

  Request* = object
    name*: string
    kind*: RequestKind
    args*: seq[Arg]
    summary*, description*: string

  EnumEntry* = object
    name*: string
    value*: uint32
    summary*: string

  Enum* = object
    name*: string
    summary*, description*: string
    entries*: seq[EnumEntry]

  Event* = object
    name*: string
    description*: string
    summary*: string
    args*: seq[Arg]

  Interface* = object
    name*: string
    version*: uint32

    summary*: string
    description*: string
    requests*: seq[Request]
    events*: seq[Event]

    enums*: seq[Enum]

  Wrapper* = object
    name*: string # filename for interface
    data*: string # generated Nim code

proc eatCharData(p: var XmlParser): string =
  while p.kind != xmlEof:
    p.next()
    if p.kind == xmlCharData:
      return p.charData
    elif p.kind == xmlElementEnd:
      break
    else:
      continue

func normalizeDocStr(doc: string): string =
  join(replace(doc, "\n", newString(0)).split().filterIt(it.len > 0), " ")

proc eatAttrs(p: var XmlParser): Table[string, string] =
  var attrs: Table[string, string]

  while p.kind != xmlEof:
    next p
    case p.kind
    of xmlEof:
      break
    of xmlAttribute:
      attrs[p.attrKey] = p.attrValue
    of xmlElementClose:
      break
    else:
      unreachable

  ensureMove(attrs)

proc eatArg(p: var XmlParser): Arg =
  let attrs = eatAttrs p

  var arg: Arg
  arg.name = attrs["name"]

  let typ = attrs["type"]
  arg.retval = typ == "new_id"

  if "interface" in attrs:
    arg.typ = attrs["interface"]
  else:
    arg.typ = typ

  ensureMove(arg)

proc eatRequest(p: var XmlParser): Request =
  var req: Request
  let attrs = eatAttrs p

  req.name = attrs["name"]
  req.kind =
    if "type" in attrs and attrs["type"] == "destructor":
      RequestKind.Destructor
    else:
      RequestKind.Call

  while p.kind != xmlEof:
    p.next()
    case p.kind
    of xmlElementOpen:
      if p.elementName == "description":
        let attrsDesc = eatAttrs(p)
        req.summary = attrsDesc["summary"]
        req.description = normalizeDocStr(eatCharData p)
      elif p.elementName == "arg":
        req.args &= eatArg(p)
      else:
        unreachable
    of xmlElementEnd:
      if p.elementName == "request":
        break
    of xmlElementClose:
      discard
    else:
      unreachable

  ensureMove(req)

func normalizeInterfaceName(name: string): string

proc eatEvent(p: var XmlParser): Event =
  var event: Event
  let attrs = eatAttrs p

  event.name = attrs["name"]

  while p.kind != xmlEof:
    p.next()
    case p.kind
    of xmlElementOpen:
      if p.elementName == "description":
        let attrsDesc = eatAttrs(p)
        event.summary = attrsDesc["summary"]
        event.description = normalizeDocStr(eatCharData p)
      elif p.elementName == "arg":
        event.args &= eatArg(p)
      else:
        discard
    of xmlElementEnd:
      if p.elementName == "event":
        break
    of xmlElementClose:
      discard
    else:
      unreachable

  ensureMove(event)

proc eatEnum(p: var XmlParser): Enum =
  var val: Enum
  val.name = eatAttrs(p)["name"]

  while p.kind != xmlEof:
    next p
    case p.kind
    of xmlElementOpen:
      if p.elementName == "description":
        let attrs = eatAttrs p
        val.summary = attrs["summary"]
        val.description = normalizeDocStr(eatCharData p)
      elif p.elementName == "entry":
        let attrs = eatAttrs p

        var entry: EnumEntry
        entry.name = attrs["name"]

        let value = attrs["value"]
        if value.startsWith("0x"):
          entry.value = cast[uint32](parseHexInt(attrs["value"]))
        else:
          entry.value = cast[uint32](parseUint(attrs["value"]))
        if "summary" in attrs:
          entry.summary = attrs["summary"]

        val.entries &= ensureMove(entry)
    of xmlElementEnd:
      if p.elementName == "enum":
        break
    else:
      discard

  ensureMove(val)

func normalizeInterfaceName(name: string): string =
  ## Nayland doesn't really use the usual qualified names for interfaces,
  ## and instead shortens them.
  ##
  ## This routine just attempts to do the same, except without any handrolling.
  ## The goal is to preserve all identifier names from the handrolled wrappers,
  ## such that there are no massive breakages.

  # Step 1: Remove the protocol family. I like calling it the family.
  let replaceFamily = name.multiReplace(
    {
      "zwp": "",
      "wp": "", # Staging
      "xx": "", # Experimental
      "xdg": "", # XDG/Freedesktop
      "wlr": "", # wlroots
      "kde": "", # KDE
      "wl": "", # Core
      "ext": "",
        # not sure what ext stands for. extra? extension? external? ¯\_(ツ)_/¯
    }
  )

  # Step 2: For every char in the new string,
  var buffer: string
  var pos = 0'i64
  while pos < replaceFamily.len:
    # If C is '_', do not append it. 
    # Instead, if there is an alphabetic character ahead,
    # append its uppercase version and inc pointer by 1
    if replaceFamily[pos] == '_' and pos < replaceFamily.len - 1:
      let next = replaceFamily[pos + 1]
      if next == 'v' and pos < replaceFamily.len - 2 and replaceFamily[pos + 2].isDigit:
        # Do not add version numbers.
        break

      buffer &= next.toUpperAscii()
        # technically not guaranteed to be alphabetic, but eh.
      inc pos
    else:
      buffer &= replaceFamily[pos]

    # Inc pointer by 1.
    inc pos

  ensureMove(buffer)

func interfaceNameToModule(name: string): string =
  var lastCapIdx = 0

  for i, c in name:
    if c.isUpperAscii:
      lastCapIdx = i

  name[lastCapIdx ..< name.len].toLowerAscii()

proc emitImportsSection(buffer: var string, iface: Interface, moduleName: string) =
  # NOTE: wrapgen cannot generate the full list of imports a module requires!
  # that is why it's a partial automation, not a full one!
  buffer &= &"import pkg/nayland/bindings/protocols/[core, {moduleName}]\n"
  buffer &= "import pkg/nayland/types/protocols/core/prelude"

func normalizeEnumIdent(ident: string, firstCapital: bool = true): string =
  var buff = newStringOfCap(ident.len)
  buff &= (if firstCapital: ident[0].toUpperAscii()
  else: ident[0].toLowerAscii())

  var i = 1
  while i < ident.len:
    let c = ident[i]
    case c
    of '_':
      buff &= ident[i + 1].toUpperAscii
      i += 2
    else:
      buff &= ident[i]
      inc i

  ensureMove(buff)

func isComplexType(typ: string): bool {.inline.} =
  const SimpleTypes = ["uint", "string", "int", "fixed", "fd"]
    # TODO: there's probably more I forgot

  typ notin SimpleTypes

func normalizeTypeName(
    typ: string,
    fixedToFloat: bool = false,
    complexSubs: bool = true,
    requiresWrapping: out bool,
): string {.inline.} =
  var SubTable = {
    "uint": "uint32",
    "string": "string",
    "int": "int32",
    "string": "cstring",
    "fixed": "wl_fixed",
    "fd": "int32",
  }.toTable
  if fixedToFloat:
    SubTable["fixed"] = "float"

  requiresWrapping = false

  if isComplexType(typ) and complexSubs:
    # If it's a wayland interface, normalize it
    return normalizeInterfaceName(typ)

  if typ in SubTable:
    # If it exists in the substitution table, substitute it.
    return SubTable[typ]

  # Otherwise, return it as-is, and let the caller know it'll probably require wrapping down the line when passed to higher-level callback procs.
  requiresWrapping = true
  typ

proc emitInterfaceStruct(buffer: var string, iface: Interface, normalizedName: string) =
  buffer &= "\n# wrapgen: begin emitting interface structures\ntype\n"
  # Step 1: Generate any enums
  for evalue in iface.enums:
    buffer &= &"  {evalue.name[0].toUpperAscii & evalue.name[1 ..< evalue.name.len]}*"
    buffer &= " {.pure, size: sizeof(uint32).} = enum\n"
    buffer &=
      &"    ## =====\n    ## {evalue.summary}\n    ## =====\n    ## {evalue.description}\n"

    var numerics: seq[uint32]

    for entry in evalue.entries:
      if entry.value in numerics:
        continue
      numerics &= entry.value
      buffer &=
        &"    {entry.name.normalizeEnumIdent} = {entry.value}'u32 ## {entry.summary}\n"

    buffer &= '\n'

  # Step 2: Generate the raw non-GC'd struct
  buffer &= &"  {normalizedName}Obj* = object\n"
  buffer &= &"    handle*: ptr {iface.name}\n" # The low level libwayland handle
  if iface.events.len > 0:
    buffer &= &"    payload: {normalizedName}Payload\n"
      # Nayland's payload callbacks system

  buffer &= '\n'

  # Step 3: Generate the GC'd struct
  buffer &= &"  {normalizedName}* = ref {normalizedName}Obj\n"
  buffer &=
    &"    ## =====\n    ## {iface.summary}\n    ## =====\n    ## {iface.description}"
    # documentation goodies :^)

  # Step 4: Event structs, if they exist.
  if iface.events.len > 0:
    let payloadStructName = normalizedName & "Payload"

    buffer &= "\n\n"
    for event in iface.events:
      let norm = normalizeInterfaceName(event.name)
      buffer &=
        &"  {normalizedName}{norm[0].toUpperAscii & norm[1 ..< norm.len]}Callback* = proc("

      for i, arg in event.args:
        var aux: bool
        buffer &=
          &"{arg.name}: {normalizeTypeName(arg.typ, fixedToFloat = true, requiresWrapping = aux)}"

        if i + 1 < event.args.len:
          buffer &= ", "

      buffer &= ")\n"

    buffer &= &"  {payloadStructName} = ref object\n"
    for event in iface.events:
      let norm = normalizeInterfaceName(event.name)
      buffer &=
        &"    {event.name}Cb: {normalizedName}{norm[0].toUpperAscii & norm[1 ..< norm.len]}Callback\n"

  # Step 5: Destructors because they need to be the first routine declared after the type 's declaration
  buffer &= "\n\n"
  for req in iface.requests:
    if req.kind != RequestKind.Destructor:
      continue

    buffer &= &"proc `=destroy`*(obj: {normalizedName}Obj) =\n"
    buffer &= &"  ## =====\n  ## {req.summary}\n  ## =====\n  ## {req.description}\n"
    buffer &= &"  {iface.name}_{req.name}(obj.handle)\n\n"
    break

proc emitInterfaceCtors(buffer: var string, iface: Interface, normalizedName: string) =
  let ending =
    if iface.events.len > 0:
      &", payload: {normalizedName}Payload())"
    else:
      ")"

  buffer &= "\n# wrapgen: begin emitting constructor routines\n"
  buffer &=
    &"""
func init{normalizedName}*(raw: ptr {iface.name} | pointer): {normalizedName} =
  ## Instantiate a {normalizedName} using its low-level libwayland handle.
  ##
  ## **Note**: This routine does not accept NULL pointers (there is no reason to), and WILL crash upon being given one!
  when not defined(danger):
    assert(raw != nil, "BUG: init{normalizedName}() was given an uninitialized handle!")
  
  {normalizedName}(handle: cast[ptr {iface.name}](raw){ending}

func new{normalizedName}*(raw: ptr {iface.name}): {normalizedName} =
  ## Instantiate a {normalizedName} using its low-level libwayland handle.
  ##
  ## **Note**: This routine does not accept NULL pointers (there is no reason to), and WILL crash upon being given one!
  when not defined(danger):
    assert(raw != nil, "BUG: new{normalizedName}() was given an uninitialized handle!")
  
  {normalizedName}(handle: raw{ending}
"""

  buffer &= "\n# wrapgen: end emitting constructor routines\n"

proc emitRequests(buffer: var string, iface: Interface, normalizedName: string) =
  buffer &= "\n# wrapgen: start emitting request wrappers\n"

  for req in iface.requests:
    case req.kind
    of RequestKind.Destructor:
      discard # Already handled in the struct generation pass.
    of RequestKind.Call:
      buffer &=
        &"\nproc {normalizeEnumIdent(req.name, firstCapital = false)}*(obj: {normalizedName}"

      for arg in req.args:
        if not arg.retval:
          var aux: bool
          buffer &=
            &", {normalizeEnumIdent(arg.name)}: {normalizeTypeName(arg.typ, requiresWrapping = aux)}"

      buffer &= ")"

      var
        hasRetval = false
        retvalType: string

      for arg in req.args:
        if arg.retval:
          retvalType = normalizeInterfaceName(arg.typ)
          hasRetval = true

          buffer &= &": {retvalType}"
          break

      buffer &= " =\n"
      buffer &= "  ## =====\n"
      buffer &= &"  ## {req.summary}\n"
      buffer &= "  ## =====\n"
      buffer &= &"  ## {req.description}\n"
      buffer &= "  "

      if hasRetval:
        # If we return a retval, we have to wrap it too.
        buffer &= &"init{retvalType}("

      buffer &= &"{iface.name}_{req.name}(obj.handle"
      for arg in req.args:
        if not arg.retval:
          buffer &= &", {normalizeEnumIdent(arg.name)}"

          if isComplexType(arg.typ):
            buffer &= ".handle"
          elif arg.typ == "fixed":
            buffer &= ".toFloat"
      buffer &= ')'
      if hasRetval:
        buffer &= ')'

      buffer &= "\n\n"

  buffer &= "\n\n# wrapgen: end emitting request wrappers"

proc emitShims(buffer: var string, iface: Interface) =
  buffer &= "\n# wrapgen: start emitting enum shims\n"

  for i, evalue in iface.enums:
    buffer &=
      &"""
converter shim{i}*(v: {evalue.name[0].toUpperAscii & evalue.name[1 ..< evalue.name.len]}): uint32 = cast[uint32](v)
"""

  buffer &= "# wrapgen: end emitting enum shims\n"

func sanitizeNimIdent(ident: string): string {.inline.} =
  ## This returns `ident` with stropping (backtick-enclosures) in the event that `ident` is
  ## found to be a Nim keyword that'd cause a parsing error.
  if ident in ["end"]:
    # Thus far I've only found `end` in the wild.
    return &"`{ident}`"

  ident

proc emitEvents(buffer: var string, iface: Interface, normalizedName: string) =
  if iface.events.len < 1:
    return

  let payloadStructName = normalizedName & "Payload"

  buffer &= "\n\nlet listener {.global.} =\n"
  buffer &= &"  {iface.name}_listener(\n"

  for i, event in iface.events:
    buffer &=
      &"    {sanitizeNimIdent(event.name)}: proc(data: pointer, this: ptr {iface.name}"

    var requiresWrapping = newSeq[bool](event.args.len)
    for i, arg in event.args:
      let normalized = normalizeTypeName(
        arg.typ, complexSubs = false, requiresWrapping = requiresWrapping[i]
      )
      buffer &= &", {arg.name}: "

      if requiresWrapping[i]:
        # Most, if not all types that require wrapping are just opaque libwayland structs.
        buffer &= "ptr "

      buffer &= normalized

    buffer &= ") {.cdecl.} =\n"

    const Indent = "      "

    buffer &= Indent
    buffer &= &"let payload = cast[{payloadStructName}](data)\n"
    buffer &=
      &"""
      if payload.{event.name}Cb == nil:
        write(stderr, "[nayland] handler not attached for event '{event.name}'!\n")
        return

"""
    buffer &= Indent
    buffer &= &"payload.{event.name}Cb("
    for i, arg in event.args:
      buffer &= &"{arg.name}"
      if arg.typ == "fixed":
        buffer &= ".toFloat"
      elif requiresWrapping[i]:
        var aux: bool
        buffer &=
          &".new{normalizeTypeName(arg.typ, complexSubs = true, requiresWrapping = aux)}()"

      if i + 1 < event.args.len:
        buffer &= ", "

    buffer &= ')'

    if i + 1 < iface.events.len:
      buffer &= "\n  ,\n"

  buffer &= "\n)\n"

  buffer &=
    &"""
proc attachCallbacks*(obj: {normalizedName}) =
  discard {iface.name}_add_listener(obj.handle, listener.addr, cast[pointer](obj.payload))

"""

  for event in iface.events:
    let norm = normalizeInterfaceName(event.name)
    let eventName = norm[0].toUpperAscii & norm[1 ..< norm.len]
    buffer &=
      &"func `on{eventName}=`*(obj: {normalizedName}, cb: {normalizedName}{eventName}Callback)"
    buffer &= " {.inline, raises: [].} =\n"
    buffer &= &"  obj.payload.{event.name}Cb = cb\n"

proc emitWrapperCode(body: seq[Interface], bindingModuleName: string): seq[Wrapper] =
  var wrappers: seq[Wrapper]
  for iface in body:
    var buffer = newStringOfCap(4096) # super accurate prealloc method
    let
      normalizedName = normalizeInterfaceName(iface.name)
      moduleName = interfaceNameToModule(normalizedName)

    buffer &= "## Wrapper around `" & iface.name & "` (`" & normalizedName & "`)\n"
    buffer &=
      "## Generated by wrapgen (protocols/wrapgen.nim).\n##\n## Copyright (C) 2026 Trayambak Rai (xtrayambak@disroot.org)\n"

    # Import bindings we may or may not require
    emitImportsSection(buffer, iface, bindingModuleName)

    # Generate code for the actual struct
    emitInterfaceStruct(buffer, iface, normalizedName)

    # Generate constructor code
    emitInterfaceCtors(buffer, iface, normalizedName)

    # Generate code for events + callbacks-attach proc
    emitEvents(buffer, iface, normalizedName)

    # Generate code for the method calls and destructor
    emitRequests(buffer, iface, normalizedName)

    # Finally, generate some converters just so old code doesn't catastrophically break.
    emitShims(buffer, iface)

    wrappers &= Wrapper(name: moduleName & ".nim", data: ensureMove(buffer))

  ensureMove(wrappers)

proc generateWrapper(protocolFile: string) =
  var p: XmlParser
  p.open(newFileStream(protocolFile, fmRead), protocolFile)

  var body: seq[Interface]
  var currIface: Interface

  while true:
    p.next()
    case p.kind
    of xmlEof:
      break
    of xmlElementOpen:
      if p.elementName == "interface":
        let attrs = eatAttrs p
        currIface.name = attrs["name"]
        currIface.version = cast[uint32](parseUint(attrs["version"]))
      elif p.elementName == "description":
        currIface.summary = eatAttrs(p)["summary"]
        currIface.description = normalizeDocStr(eatCharData p)
      elif p.elementName == "request":
        currIface.requests &= eatRequest(p)
      elif p.elementName == "event":
        currIface.events &= eatEvent(p)
      elif p.elementName == "enum":
        currIface.enums &= eatEnum(p)
    of xmlElementEnd:
      if p.elementName == "interface":
        body &= move(currIface)
    else:
      continue

  if currIface.name.len != 0:
    body &= move(currIface)

  # prepare directories in source tree
  let
    splitProtoDir = protocolFile.splitPath().tail.split("-")
    moduleName = splitProtoDir.join("_").split('.')[0] # In the bindings dir
    protoDirName = splitProtoDir[0 ..< splitProtoDir.len - 1].join("_")
    baseDir = &"src/nayland/types/protocols/{protoDirName}"
    nphPath = findExe("nph")

  createDir(baseDir)

  # Prelude file
  var preludeBuffer = newStringOfCap(1024)

  # Write the wrapper code in there
  for wrapper in emitWrapperCode(ensureMove(body), moduleName):
    let
      path = &"{baseDir}/{wrapper.name}"
      confirmed =
        not fileExists(path) or
        readLineFromStdin(&"Replace '{path}'? [y/N] ").toLowerAscii() == "y"

    let name = wrapper.name.splitFile().name
    preludeBuffer &= &"import pkg/nayland/types/protocols/{protoDirName}/{name}\n"
    preludeBuffer &= &"export {name}\n"

    if confirmed:
      echo "=> " & path
      writeFile(path, wrapper.data)

      if nphPath.len > 0:
        discard execCmd(&"{nphPath} {path}")
    else:
      echo &"Skipped '{path}'"

  writeFile(&"{baseDir}/prelude.nim", ensureMove(preludeBuffer))

proc main() {.inline.} =
  let file = paramStr(1)

  generateWrapper(file)

when isMainModule:
  main()
