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
Crypto.Forge = (cipher_name, key, iv, op) ->
  cipher_info = cipher_name.match /^(aes)-(128|192|256)-(cfb|ofb|ctr)$/i
  console.assert key.length is cipher_info[2] / 8, "Cipher and key length mismatch."
  if op is 1  # cipher
    @cipher = forge.cipher.createCipher "#{cipher_info[1]}-#{cipher_info[3]}", key
  else        # 0 is decipher
    @cipher = forge.cipher.createDecipher "#{cipher_info[1]}-#{cipher_info[3]}", key
  @cipher.start iv: iv
  return


# (Uint8Array) -> Uint8Array
Crypto.Forge::update = (data) ->
  @cipher.update forge.util.createBuffer Common.uint82Str data
  return Common.str2Uint8 do @cipher.output.getBytes