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


Crypto = if Crypto? then Crypto else {}


# (String, binstr, binstr, 0|1)
Crypto.RC4_MD5 = (cipher_name, key, iv, op) ->
  md5 = do forge.md.md5.create
  md5.update key
  md5.update iv
  rc4_key = md5.digest().bytes()
  @cipher = new RC4 Common.str2Uint8 rc4_key
  return


# (Uint8Array) -> Uint8Array
Crypto.RC4_MD5::update = (data) ->
  len    = data.length
  buf    = new Uint8Array data
  result = new Uint8Array len
  @cipher.update result, buf, len
  return result