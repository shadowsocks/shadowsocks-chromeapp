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
Encryptor = (@key, @method, @one_time_auth = false) ->
  @iv_sent = false
  @decipher = null
  @cipher_counter = 0
  @_method_info = Encryptor.get_method_info @method
  @cipher_iv = forge.random.getBytesSync @_method_info[1]
  if @_method_info
    @cipher = @get_cipher @key, @method, 1, @cipher_iv
  else
    console._error "method #{method} is not supported."
  return


Encryptor.method_supported =
  'rc4-md5': [16, 16, Crypto.RC4_MD5]
  'aes-128-cfb': [16, 16, Crypto.Forge]
  'aes-192-cfb': [24, 16, Crypto.Forge]
  'aes-256-cfb': [32, 16, Crypto.Forge]
  'aes-128-ofb': [16, 16, Crypto.Forge]
  'aes-192-ofb': [24, 16, Crypto.Forge]
  'aes-256-ofb': [32, 16, Crypto.Forge]
  'aes-128-ctr': [16, 16, Crypto.Forge]
  'aes-192-ctr': [24, 16, Crypto.Forge]
  'aes-256-ctr': [32, 16, Crypto.Forge]


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
  [@cipher_key, ] = Encryptor.EVP_BytesToKey password, key_len, iv_len
  new impl method, @cipher_key, iv, op


# (Uint8Array) -> Uint8Array
Encryptor::encrypt = (buf) ->
  return buf if buf.length is 0
  return @cipher.update buf if @iv_sent and not @one_time_auth

  if @iv_sent
    buf_len = buf.length
    hmac = do forge.hmac.create
    hmac.start 'sha1', @cipher_iv + forge.util.int32ToBytes(@cipher_counter++)
    hmac.update Common.uint82Str buf
    auth_data = hmac.digest().getBytes()[0...10]
    combined = new Uint8Array 2 + 10 + buf_len
    combined[0] = (buf_len & 0xff00) >> 8
    combined[1] = buf_len & 0x00ff
    combined.set Common.str2Uint8(auth_data), 2
    combined.set buf, 12
    return @cipher.update combined
   else
    @iv_sent = yes
    if @one_time_auth
      buf[0] |= 0x10
      buf = Common.uint82Str buf
      hmac = do forge.hmac.create
      hmac.start 'sha1', @cipher_iv + @cipher_key
      hmac.update buf
      buf += hmac.digest().getBytes()[0...10]
      buf = Common.str2Uint8 buf
    encrypted_array = @cipher.update buf
    cipher_iv_array = Common.str2Uint8 @cipher_iv
    combined = new Uint8Array cipher_iv_array.length + encrypted_array.length
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
    @decipher_iv = Common.uint82Str buf.subarray(0, decipher_iv_len)
    @decipher = @get_cipher @key, @method, 0, @decipher_iv
    buf = new Uint8Array buf.subarray decipher_iv_len
    return buf if buf.length is 0
  return @decipher.update buf


# (String, String, 0|1, Uint8Array, Boolean) -> Uint8Array
Encryptor.encrypt_all = (password, method, op, data, one_time_auth) ->
  [key_len, iv_len, impl] = Encryptor.get_method_info method
  [key, ] = Encryptor.EVP_BytesToKey password, key_len, iv_len

  if op is 1    # Encrypt
    iv = forge.random.getBytesSync iv_len
    if one_time_auth
      data[0] |= 0x10
      data = Common.uint82Str data
      hmac = do forge.hmac.create
      hmac.start 'sha1', iv + key
      hmac.update data
      data = Common.str2Uint8 data + hmac.digest().getBytes()[0...10]
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
