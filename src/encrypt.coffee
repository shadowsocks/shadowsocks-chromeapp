# Copyright (c) 2015 clowwindy
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


# (str, str)
Encryptor = (@key, @method) ->
  @iv_sent = false
  @cipher_iv = ""
  @decipher = null
  @_method_info = Encryptor.get_method_info @method
  if @_method_info
    @cipher = @get_cipher @key, @method, 1, forge.random.getBytesSync @_method_info[1]
  else
    console.error "method #{method} is not supported."
  return


Encryptor.method_supported =
  'rc4-md5': [16, 16, Crypto.RC4_MD5]


# (str, int, int) -> [binstr, binstr]
Encryptor._bytes_to_key_cache = {}
Encryptor.EVP_BytesToKey = (password, key_len, iv_len) ->
  cached_key = "#{password}-#{key_len}-#{iv_len}"
  if cached_key of Encryptor._bytes_to_key_cache
    return Encryptor._bytes_to_key_cache[cached_key]
  m = []
  count = 0
  while count < key_len + iv_len
    md5 = do forge.md.md5.create
    data = (m[m.length - 1] || '') + password
    md5.update data
    d = md5.digest().bytes()
    m.push d
    count += d.length
  ms = m.join ''
  key = ms[0...key_len]
  iv  = ms[key_len...key_len + iv_len]
  Encryptor._bytes_to_key_cache[cached_key] = [key, iv]
  return [key, iv]


# (str) -> [int, int, cipherclass]
Encryptor.get_method_info = (method) ->
  Encryptor.method_supported[do method.toLowerCase]


# () -> int
Encryptor::iv_len = () ->
  @cipher_iv.length


# (str, str, 0/1, binstr) -> cipher
Encryptor::get_cipher = (password, method, op, iv) ->
  [key_len, iv_len, impl] = @_method_info
  [key, ] = Encryptor.EVP_BytesToKey password, key_len, iv_len
  iv = iv[0...iv_len]
  if op is 1
    @cipher_iv = iv
  new impl method, key, iv, op


# (Uint8Array|binstr) -> Uint8Array
Encryptor::encrypt = (buf) ->
  if Object::toString.call(buf) is "[object String]"
    buf = Common.str2Uint8 buf
  return buf if buf.length is 0
  return @cipher.update buf if @iv_sent
  @iv_sent = true
  encrypted_array = @cipher.update buf
  cipher_iv_array = Common.str2Uint8 @cipher_iv
  combined = new Uint8Array encrypted_array.length + cipher_iv_array.length
  combined.set cipher_iv_array, 0
  combined.set encrypted_array, cipher_iv_array.length
  return combined


# (Uint8Array|binstr) -> Uint8Array
Encryptor::decrypt = (buf) ->
  if Object::toString.call(buf) is "[object String]"
    buf = Common.str2Uint8 buf
  return buf if buf.length is 0
  if not @decipher?
    decipher_iv_len = @_method_info[1]
    decipher_iv = Common.uint82Str buf.subarray(0, decipher_iv_len)
    @decipher = @get_cipher @key, @method, 0, decipher_iv
    buf = new Uint8Array buf.subarray decipher_iv_len
    return buf if buf.length is 0
  return @decipher.update buf


# (String, String, 0|1, Uint8Array|binstr) -> Uint8Array
Encryptor.encrypt_all = (password, method, op, data) ->
  if Object::toString.call(data) is "[object String]"
    data = Common.str2Uint8 data

  [key_len, iv_len, impl] = Encryptor.get_method_info method
  [key, ] = Encryptor.EVP_BytesToKey password, key_len, iv_len

  if op is 1    # Encrypt
    iv = forge.random.getBytesSync iv_len
  else          # Decrypt
    iv = Common.uint82Str data.subarray(0, iv_len)
    data = new Uint8Array data.subarray iv_len

  cipher = new impl method, key, iv, op
  encrypted_array = cipher.update data

  return encrypted_array if op is 0
  combined = new Uint8Array iv_len + encrypted_array.length
  combined.set Common.str2Uint8(iv), 0
  combined.set encrypted_array, iv_len
  return combined