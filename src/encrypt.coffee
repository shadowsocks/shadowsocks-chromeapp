# Copyright (c) 2012 clowwindy
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

int32Max = Math.pow(2, 32)

cachedTables = {} # password: [encryptTable, decryptTable]

window.getTable = (key) ->
  if cachedTables[key]
    return cachedTables[key]
  console.log "calculating ciphers"
  table = new Array(256)
  decrypt_table = new Array(256)
  md5sum_str = rstr_md5(key)
  md5sum = new ArrayBuffer(8)
  md5sum_array = new Uint8Array(md5sum, 0, 8)
  for i in [0..7]
    md5sum_array[i] = md5sum_str.charCodeAt(i)
  al = new Uint32Array(md5sum, 0, 1)[0]
  ah = new Uint32Array(md5sum, 4, 1)[0]
  i = 0

  while i < 256
    table[i] = i
    i++
  i = 1

  while i < 1024
    table = merge_sort(table, (x, y) ->
      ((ah % (x + i)) * int32Max + al) % (x + i) - ((ah % (y + i)) * int32Max + al) % (y + i)
    )
    i++
  i = 0
  while i < 256
    decrypt_table[table[i]] = i
    ++i
  result = [table, decrypt_table]
  cachedTables[key] = result
  result
  
encrypt = (table, buf) ->
  i = 0

  array = new Uint8Array(buf)
  while i < array.length
    array[i] = table[array[i]]
    i++
  buf


bytes_to_key_results = {}

string2Uint8Array = (string) ->
  arr = new Uint8Array(string.length)
  for i in [0..(string.length - 1)]
    arr[i] = string.charCodeAt(i)
  arr

uint82String = (arr) ->
  String.fromCharCode.apply(null, arr)

EVP_BytesToKey = (password, key_len, iv_len) ->
  if bytes_to_key_results[password]
    return bytes_to_key_results[password]
  m = []
  i = 0
  count = 0
  while count < key_len + iv_len
    md5 = forge.md.md5.create()
    data = password
    if i > 0
      data = [m[i - 1] + password]
    md5.update(data)
    d = md5.digest().bytes()
    m.push(d)
    count += d.length
    i += 1
  ms = m.join('')
  key = ms.slice(0, key_len)
  iv = ms.slice(key_len, key_len + iv_len)
  bytes_to_key_results[password] = [key, iv]
  return [key, iv]


method_supported =
  'rc4-md5': [16, 16, 'RC4-MD5']

createCipher = (method, key, iv, op) ->
  if method == 'rc4-md5'
    md = forge.md.md5.create()
    md.update(key)
    md.update(uint82String(iv))
    rc4_key = string2Uint8Array(md.digest().data)
    key = string2Uint8Array(key)
    console.log 'key:' + key[0].toString(16) + key[1].toString(16) + key[2].toString(16) + key[3].toString(16)
    console.log 'iv:' + iv[0].toString(16) + iv[1].toString(16) + iv[2].toString(16) + iv[3].toString(16)
    console.log 'rc4_key:' + rc4_key[0].toString(16) + rc4_key[1].toString(16) + rc4_key[2].toString(16) + rc4_key[3].toString(16)
    return RC4(rc4_key)
  else
    throw new Error("unknown cipher #{method}")


class Encryptor
  constructor: (@key, @method) ->
    @iv_sent = false
    if @method == 'table'
      @method = null
    if @method?
      @cipher = @get_cipher(@key, @method, 1, string2Uint8Array(forge.random.getBytesSync(32)))
    else
      [@encryptTable, @decryptTable] = getTable(@key)

  get_cipher_len: (method) ->
    method = method.toLowerCase()
    m = method_supported[method]
    return m

  get_cipher: (password, method, op, iv) ->
    method = method.toLowerCase()
    m = @get_cipher_len(method)
    if m?
      [key, iv_] = EVP_BytesToKey(password, m[0], m[1])
      iv = iv.subarray(0, m[1])
      if op == 1
        @cipher_iv = iv
      return createCipher(method, key, iv, op)

  encrypt: (buf) ->
    buf = new Uint8Array(buf)
    if @method?
      len = buf.byteLength
      result = new Uint8Array(len)
      @cipher.update(result, buf, len)
      if @iv_sent
        return result.buffer
      else
        @iv_sent = true
        iv_len = @cipher_iv.byteLength
        combined = new Uint8Array(iv_len + len)
        combined.set(@cipher_iv, 0)
        combined.set(result, iv_len)
        return combined.buffer
    else
      substitute @encryptTable, buf

  decrypt: (buf) ->
    buf = new Uint8Array(buf)
    if @method?
      if not @decipher?
        decipher_iv_len = @get_cipher_len(@method)[1]
        decipher_iv = buf.subarray(0, decipher_iv_len)
        @decipher = @get_cipher(@key, @method, 0, decipher_iv)
        result = new Uint8Array(buf.byteLength  - decipher_iv_len)
        @decipher.update(result, buf.subarray(decipher_iv_len), buf.length - decipher_iv_len)
        return result.buffer
      else
        len = buf.byteLength
        @decipher.update(buf, buf, len)
        return buf.buffer
    else
      substitute @decryptTable, buf
      
window.Encryptor = Encryptor