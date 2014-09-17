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
  'aes-128-cfb': [16, 16, 'AES-CFB']
  'aes-192-cfb': [24, 16, 'AES-CFB']
  'aes-256-cfb': [32, 16, 'AES-CFB']


class Encryptor
  constructor: (@key, @method) ->
    @iv_sent = false
    if @method == 'table'
      @method = null
    if @method?
      @cipher = @get_cipher(@key, @method, 1, forge.random.getBytesSync(32))
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
      if not iv?
        iv = iv_
      if op == 1
        @cipher_iv = iv.slice(0, m[1])
      iv = iv.slice(0, m[1])
      if op == 1
        cipher = forge.cipher.createCipher(method, key)
        cipher.start({
          iv: iv
        })
        return cipher
      else
        decipher = forge.createCipher(method, key)
        cipher.start({
          iv: iv
        })
        return decipher

  encrypt: (buf) ->
    if @method?
      result = @cipher.update(buf.toString('binary'))
      if @iv_sent
        return result
      else
        @iv_sent = true
        return @cipher_iv + result
    else
      substitute @encryptTable, buf

  decrypt: (buf) ->
    if @method?
      if not @decipher?
        decipher_iv_len = @get_cipher_len(@method)[1]
        decipher_iv = buf.slice(0, decipher_iv_len)
        @decipher = @get_cipher(@key, @method, 0, decipher_iv)
        result = to_buffer @decipher.update(buf.slice(decipher_iv_len).toString('binary'))
        return result
      else
        result = to_buffer @decipher.update(buf.toString('binary'))
        return result
    else
      substitute @decryptTable, buf
      
window.Encryptor = Encryptor