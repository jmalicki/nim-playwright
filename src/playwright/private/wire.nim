## Low-level wire protocol: spawn Playwright driver and send/receive length-prefixed JSON over stdio.
## Playwright uses 4-byte little-endian length prefix followed by UTF-8 JSON.

import std/[os, osproc, streams, json, endians, tables]

type
  WireError* = object of CatchableError

  Driver* = ref object
    process: Process
    stdinStream: Stream
    stdoutStream: Stream
    nextId: int
    createdInitializers*: Table[string, JsonNode]  ## guid -> initializer from __create__ events

proc getDriverCommand(): string =
  let cmd = getEnv("PLAYWRIGHT_NIM_DRIVER", "npx")
  if cmd == "npx":
    "npx -y playwright@latest run-driver"
  else:
    cmd

proc startDriver*(): Driver =
  let cmd = getDriverCommand()
  var p = startProcess(
    command = cmd,
    args = @[],
    options = {poUsePath, poEvalCommand},
    env = nil
  )
  result = Driver(
    process: p,
    stdinStream: p.inputStream,
    stdoutStream: p.outputStream,
    nextId: 1,
    createdInitializers: initTable[string, JsonNode]()
  )

proc encodeFrame*(body: string): string =
  ## Encode a message frame: 4-byte little-endian length + body. Used by send; exposed for tests.
  var lenBuf: array[4, byte]
  var len32 = uint32(body.len)
  littleEndian32(addr lenBuf[0], addr len32)
  result = newString(4 + body.len)
  for i in 0 ..< 4: result[i] = lenBuf[i].char
  for i in 0 ..< body.len: result[4 + i] = body[i]

proc decodeFrame*(data: string): tuple[body: string, consumed: int] =
  ## Decode one frame from the start of data. consumed is 4 + body.len. Exposed for tests.
  if data.len < 4:
    raise (ref WireError)(msg: "Frame too short")
  var lenBuf: array[4, byte]
  for i in 0 ..< 4: lenBuf[i] = data[i].byte
  var len32: uint32
  littleEndian32(addr len32, addr lenBuf[0])
  let n = int len32
  if data.len < 4 + n:
    raise (ref WireError)(msg: "Incomplete frame")
  result.body = data[4 ..< 4 + n]
  result.consumed = 4 + n

proc send*(d: Driver; guid: string; methodName: string; params: JsonNode): int =
  let id = d.nextId
  inc d.nextId
  var msgObj = newJObject()
  msgObj["id"] = %id
  msgObj["guid"] = %guid
  msgObj["method"] = %methodName
  msgObj["params"] = params
  ## Playwright 1.49+ requires metadata on every message; missing metadata causes
  ## dispatcher to crash (validMetadata is undefined then validMetadata.location).
  msgObj["metadata"] = newJObject()
  let s = $msgObj
  result = id
  let frame = encodeFrame(s)
  d.stdinStream.write(frame)
  d.stdinStream.flush()

proc readMessage(d: Driver): JsonNode =
  let s = d.stdoutStream
  var lenBuf: array[4, byte]
  if s.readData(addr lenBuf[0], 4) != 4:
    raise (ref WireError)(msg: "Driver closed or read failed")
  var len32: uint32
  littleEndian32(addr len32, addr lenBuf[0])
  let n = int len32
  var buf = newString(n)
  if s.readData(addr buf[0], n) != n:
    raise (ref WireError)(msg: "Driver read truncated")
  parseJson(buf)

proc receive*(d: Driver; id: int): JsonNode =
  while true:
    let j = d.readMessage()
    if j.hasKey("method") and j["method"].getStr() == "__create__":
      ## Playwright 1.49+ sends browser types via __create__ initializer, not method calls.
      let params = j.getOrDefault("params")
      if params != nil and params.hasKey("guid") and params.hasKey("initializer"):
        let guid = params["guid"].getStr()
        d.createdInitializers[guid] = params["initializer"]
    elif j.hasKey("id") and j["id"].getInt() == id:
      if j.hasKey("error"):
        let err = j["error"]
        let msg = if err.hasKey("message"): err["message"].getStr() else: $err
        raise (ref WireError)(msg: "Driver error: " & msg)
      return if j.hasKey("result"): j["result"] else: newJNull()
    # Skip other events; match by id

proc getCreatedInitializer*(d: Driver; guid: string): JsonNode =
  ## Return initializer from __create__ event for guid, or default (nil) if not found.
  d.createdInitializers.getOrDefault(guid)

proc call*(d: Driver; guid: string; methodName: string;
    params: JsonNode = nil): JsonNode =
  let prm = if params.isNil: newJObject() else: params
  let id = d.send(guid, methodName, prm)
  d.receive(id)

proc close*(d: Driver) =
  if d.process != nil:
    terminate(d.process)
    close(d.process)
