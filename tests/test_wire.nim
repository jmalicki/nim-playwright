## Tests for wire protocol encoding/decoding (no driver required).

import std/[json]
import playwright/private/wire

proc main() =
  # encodeFrame / decodeFrame round-trip
  let body = """{"id":1,"method":"test","params":{}}"""
  let encoded = encodeFrame(body)
  doAssert encoded.len == 4 + body.len
  let (decoded, consumed) = decodeFrame(encoded)
  doAssert decoded == body
  doAssert consumed == encoded.len

  # Empty body
  let enc2 = encodeFrame("")
  doAssert enc2.len == 4
  let (dec2, cons2) = decodeFrame(enc2)
  doAssert dec2 == ""
  doAssert cons2 == 4

  # JSON body round-trip
  let j = %* {"playwright": {"guid": "pw-123"}}
  let js = $j
  let (outBody, _) = decodeFrame(encodeFrame(js))
  doAssert outBody == js
  let j2 = parseJson(outBody)
  doAssert j2["playwright"]["guid"].getStr() == "pw-123"

  # decodeFrame raises on too short input
  try:
    discard decodeFrame("ab")
    doAssert false, "should raise"
  except WireError:
    discard

  # decodeFrame raises on incomplete frame (length says 1000 but only 10 bytes)
  try:
    var bad = newString(4)
    bad[0] = char(0xe8)
    bad[1] = char(0x03)
    bad[2] = char(0)
    bad[3] = char(0)
    discard decodeFrame(bad)
    doAssert false, "should raise"
  except WireError:
    discard

  echo "test_wire: OK"

main()
