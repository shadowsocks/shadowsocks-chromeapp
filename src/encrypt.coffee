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
  

class Encryptor
  constructor: (key, @method) ->
    if @method?
      @cipher = crypto.createCipher @method, key
      @decipher = crypto.createDecipher @method, key
    else
      [@encryptTable, @decryptTable] = getTable(key)
      
  encrypt: (buf) ->
    if @method?
      result = new Buffer(@cipher.update(buf.toString('binary')), 'binary')
      result
    else
      encrypt @encryptTable, buf
      
  decrypt: (buf) ->
    if @method?
      result = new Buffer(@decipher.update(buf.toString('binary')), 'binary')
      result
    else
      encrypt @decryptTable, buf
      
window.Encryptor = Encryptor