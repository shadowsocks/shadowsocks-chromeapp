# Copyright (c) 2015 Sunny
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


Common = {}


# (String) -> Uint8Array
Common.str2Uint8 = (str) ->
  arr = new Uint8Array str.length
  for i in [0...str.length]
    arr[i] = str.charCodeAt i
  return arr


# (Uint8Array) -> String
Common.uint82Str = (uint8) ->
  String.fromCharCode uint8...


# (TypedArray|Array, Number, int) -> int
Common.typedIndexOf = (typedArray, searchElement, fromIndex = 0) ->
  for element, index in typedArray
    return index if element is searchElement and index >= fromIndex
  return -1


# (TypedArray|Array, TypedArray|Array, int, int, int, int) -> int
Common.typedArrayCpy = (dst, src, dstStart = 0, srcStart = 0, dstEnd = dst.length, srcEnd = src.length) ->
  len = Math.min srcEnd - srcStart, dstEnd - dstStart
  for i in [dstStart...dstStart + len]
    dst[i] = src[srcStart + i - dstStart]
  return len


# (int, int, ...) -> String
Common.bytes2FixedHexString = (bytes...) ->
  ((if byte < 16 then "0" else "") + byte.toString(16) for byte in bytes).join('')


# (0x01|0x04, TypedArray|Array<int>) -> String
Common.inet_ntop = (family, array) ->
  if family is 0x01 and array.length is 4         # IPv4
    return (i for i in array).join('.')
  else if family is 0x04 and array.length is 16   # IPv6
    (Common.bytes2FixedHexString array[i], array[i + 1] for i in [0...16] by 2).join(':')
  else
    console.error "Not a valid family."


# (0x01|0x04, String) -> Array<int>
Common.inet_pton = (family, str) ->
  if family is 0x01       # IPv4
    return (parseInt byte for byte in str.split('.'))
  else if family is 0x04  # IPv6
    if str.indexOf('.') >= 0
      v4arr  = Common.inet_pton 0x01, str.slice str.lastIndexOf(':') + 1
      v6like = (Common.bytes2FixedHexString v4arr[i], v4arr[i + 1] for i in [0...4] by 2).join(':')
      newaddr = str.slice(0, str.lastIndexOf(':') + 1) + v6like
      return Common.inet_pton family, newaddr
    bytes = []
    grp = str.split ':'
    do grp.shift if grp[0] is ""
    do grp.pop if grp[grp.length - 1] is ""
    for twoBytes in grp
      if twoBytes is ""
        bytes.push 0 for i in [0...(16 - (grp.length - 1) * 2)]
      else
        bytes.push parseInt(twoBytes.slice(0, 2), 16)
        bytes.push parseInt(twoBytes.slice(2, 4), 16)
    return bytes
  else
    console.error "Not a valid family."


Common.regExpIPv4 = /((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])/
Common.regExpIPv6 = /// (                          # Regexps credits to David M. Syzdek @ stackoverflow
([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|          # 1:2:3:4:5:6:7:8
([0-9a-fA-F]{1,4}:){1,7}:|                         # 1::                              1:2:3:4:5:6:7::
([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|         # 1::8             1:2:3:4:5:6::8  1:2:3:4:5:6::8
([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|  # 1::7:8           1:2:3:4:5::7:8  1:2:3:4:5::8
([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|  # 1::6:7:8         1:2:3:4::6:7:8  1:2:3:4::8
([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|  # 1::5:6:7:8       1:2:3::5:6:7:8  1:2:3::8
([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|  # 1::4:5:6:7:8     1:2::4:5:6:7:8  1:2::8
[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|       # 1::3:4:5:6:7:8   1::3:4:5:6:7:8  1::8  
:((:[0-9a-fA-F]{1,4}){1,7}|:)|                     # ::2:3:4:5:6:7:8  ::2:3:4:5:6:7:8 ::8       ::     
fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|     # fe80::7:8%eth0   fe80::7:8%1     (link-local IPv6 addresses with zone index)
::(ffff(:0{1,4}){0,1}:){0,1}
((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}
(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|          # ::255.255.255.255   ::ffff:255.255.255.255  ::ffff:0:255.255.255.255  (IPv4-mapped IPv6 addresses and IPv4-translated addresses)
([0-9a-fA-F]{1,4}:){1,4}:
((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}
(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])           # 2001:db8:3:4::192.0.2.33  64:ff9b::192.0.2.33 (IPv4-Embedded IPv6 Address)
) ///
Common.guessFamily = (str) ->     # (String) -> 0x01|0x03|0x04
  if Common.regExpIPv4.test str
    return 0x01
  else if Common.regExpIPv6.test str
    return 0x04
  else
    return 0x03


# (Uint8Array) -> Object
Common.parseHeader = (data) ->
  switch data[3]    # ATYP
    when 0x01       # IPv4
      dst = Common.inet_ntop data[3], data.subarray(4, -2)
    when 0x03       # doamin name
      if data.length > 2 + 6  # 6 contains VER, CMD, RSV, ATYP, PORT(2)
        len = data[4]
        dst = Common.uint82Str(data.subarray(5, len + 5))
      else
        console.warn "Header is too short."
        return null
    when 0x04       # IPv6
      dst = Common.inet_ntop data[3], data.subarray(4, -2)
    else
      console.error "Not a valid ATYP."
      return null
  prt = data.subarray -2
  port = prt[0] << 8 | prt[1]
  ver: data[0], cmd: data[1], rsv: data[2], atyp: data[3], dst: dst, port: port


# (int, 0x01|0x03|0x04|0x80|null, String, String|int) -> Uint8Array
# set atyp to null or 0x80 means guess the type of address
Common.packHeader = (rep, atyp = 0x80, addr, port) ->
  switch atyp
    when 0x01 then len = 10   # 1 (VER) + 1 (REP) + 1 (RSV) + 1 (ATYP) + 4 (BND.ADDR) + 2 (BND.PORT)
    when 0x03 then len = 7 + addr.length  # VER + REP + RSV + ATYP + (1 + LEN)(BND.ADDR) + BND.PORT
    when 0x04 then len = 22   # VER + REP + RSV + ATYP + 16 (BND.ADDR) + BND.PORT
    when 0x80 then return Common.packHeader rep, Common.guessFamily(addr), addr, port
    else return console.error "Not a valid ATYP."

  index = 0
  arr = new Uint8Array len
  arr[index++] = 0x05   # VER = 0x05
  arr[index++] = rep
  arr[index++] = 0x00   # RSV = 0x00
  arr[index++] = atyp
  arr[index++] = addr.length if atyp is 0x03
  if atyp is 0x01 or atyp is 0x04
    bindAddr = Common.inet_pton atyp, addr
  else
    bindAddr = Common.str2Uint8 addr
  index += Common.typedArrayCpy arr, bindAddr, index
  arr[index++] = (port & 0xff00) >> 8
  arr[index++] = port & 0xff
  console.assert index is len
  return arr


Common.test = () ->
  array_equals = (arr1, arr2) ->
    return false if arr1.length isnt arr2.length
    for i in [0...arr1.length]
      return false if arr1[i] isnt arr2[i]
    return true

  # Test for uint8 <=> string
  console.assert array_equals(Common.str2Uint8("h.w"), new Uint8Array([104, 46, 119]))
  console.assert Common.uint82Str(new Uint8Array([104, 46, 119])) is "h.w"

  # Test for typedIndexOf
  console.assert Common.typedIndexOf(new Uint8Array([0xa1, 0x35, 0xc0, 0x35]), 0x35, 1) is 1
  console.assert Common.typedIndexOf(new Uint8Array([0xa1, 0x35, 0xc0, 0x35]), 0x35, 2) is 3

  # Test for typedArrayCpy
  arr1 = new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
  arr2 = new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
  console.assert Common.typedArrayCpy(arr1, arr2, 4, 8, 6, 12) is 2
  console.assert array_equals(arr1, new Uint8Array([0, 1, 2, 3, 8, 9, 6, 7, 8, 9, 10, 11, 12]))

  # Test for bytes2FixedHexString
  console.assert Common.bytes2FixedHexString(0xff, 0x00) is "ff00"

  # Test for inet_ntop
  console.assert Common.inet_ntop(0x01, new Uint8Array([0xcb, 0xd0, 0x29, 0x91])) is "203.208.41.145"
  console.assert Common.inet_ntop(0x04, new Uint8Array([0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef,
    0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef])) is "1234:5678:90ab:cdef:1234:5678:90ab:cdef"

  # Test for inet_pton
  console.assert array_equals(Common.inet_pton(0x01, "203.208.41.145"), [0xcb, 0xd0, 0x29, 0x91])
  console.assert array_equals(Common.inet_pton(0x04, "1234:5678:90ab:cdef:1234:5678:90ab:cdef"),
    [0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef, 0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef])
  console.assert array_equals(Common.inet_pton(0x04, "1234::5678:203.208.41.145"), [0x12, 0x34, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x56, 0x78, 0xcb, 0xd0, 0x29, 0x91])
  console.assert array_equals(Common.inet_pton(0x04, "1234::5678"), [0x12, 0x34, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x56, 0x78])
  console.assert array_equals(Common.inet_pton(0x04, "::1234:5678"), [0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x34, 0x56, 0x78])
  console.assert array_equals(Common.inet_pton(0x04, "1234:5678::"), [0x12, 0x34, 0x56, 0x78, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])

  # Test for guess family
  console.assert Common.guessFamily("192.168.1.0") is 0x01
  console.assert Common.guessFamily("www.google.com") is 0x03
  console.assert Common.guessFamily("1234::5678") is 0x04
  console.assert Common.guessFamily("::1234:5678") is 0x04
  console.assert Common.guessFamily("1234:5678::") is 0x04
  console.assert Common.guessFamily("1234:5678:90ab:cdef:1234:5678:90ab:cdef") is 0x04

  # Test for parseHeader
  testHeader = Common.parseHeader(new Uint8Array([0x05, 0x01, 0x00, 0x01, 0xcb, 0xd0, 0x29, 0x91, 0x01, 0xbb]))
  console.assert testHeader.atyp is 0x01 and testHeader.dst is "203.208.41.145" and testHeader.port is 443
  testHeader = Common.parseHeader(new Uint8Array([0x05, 0x01, 0x00, 0x03, 0x03, 0x68, 0x2e, 0x77, 0x00, 0x50]))
  console.assert testHeader.atyp is 0x03 and testHeader.dst is "h.w" and testHeader.port is 80
  testHeader = Common.parseHeader(new Uint8Array([0x05, 0x01, 0x00, 0x04, 0x12, 0x34, 0x56, 0x78, 0x90, 0xab,
    0xcd, 0xef, 0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef, 0x1f, 0x90]))
  console.assert testHeader.ver = 0x05 and testHeader.cmd = 0x01 and testHeader.atyp is 0x04 and
    testHeader.dst is "1234:5678:90ab:cdef:1234:5678:90ab:cdef" and testHeader.port is 8080

  # Test for packHeader
  testHeader = Common.packHeader(0x00, 0x01, "203.208.41.145", 443)
  console.assert array_equals(testHeader, new Uint8Array([0x05, 0x00, 0x00, 0x01, 0xcb, 0xd0, 0x29, 0x91, 0x01, 0xbb]))
  testHeader = Common.packHeader(0x00, 0x03, "h.w", 80)
  console.assert array_equals(testHeader, new Uint8Array([0x05, 0x00, 0x00, 0x03, 0x03, 0x68, 0x2e, 0x77, 0x00, 0x50]))
  testHeader = Common.packHeader(0x00, 0x04, "1234::5678", 8080)
  console.assert array_equals(testHeader, new Uint8Array([0x05, 0x00, 0x00, 0x04, 0x12, 0x34, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x56, 0x78, 0x1f, 0x90]))
  testHeader = Common.packHeader(0x00, 0x80, "203.208.41.145", 443)
  console.assert array_equals(testHeader, new Uint8Array([0x05, 0x00, 0x00, 0x01, 0xcb, 0xd0, 0x29, 0x91, 0x01, 0xbb]))
  testHeader = Common.packHeader(0x00, null, "h.w", 80)
  console.assert array_equals(testHeader, new Uint8Array([0x05, 0x00, 0x00, 0x03, 0x03, 0x68, 0x2e, 0x77, 0x00, 0x50]))
  testHeader = Common.packHeader(0x00, null, "1234::5678", 8080)
  console.assert array_equals(testHeader, new Uint8Array([0x05, 0x00, 0x00, 0x04, 0x12, 0x34, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x56, 0x78, 0x1f, 0x90]))

  console.log "All test passed!"


# do Common.test