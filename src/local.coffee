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


inetNtoa = (buf) ->
  buf[0] + "." + buf[1] + "." + buf[2] + "." + buf[3]
inetAton = (ipStr) ->
  parts = ipStr.split(".")
  unless parts.length is 4
    null
  else
    buf = new Buffer(4)
    i = 0

    while i < 4
      buf[i] = +parts[i]
      i++
    buf

config = {
  local_port: 1081,
  server_port: 8388,
  password: 'barfoo!',
  server: '127.0.0.1',
  method: null
}
SERVER = config.server
REMOTE_PORT = config.server_port
PORT = config.local_port
KEY = config.password
METHOD = config.method
timeout = Math.floor(config.timeout * 1000)

BUF_SIZE = 1500

getServer = ->
  if SERVER instanceof Array
    SERVER[Math.floor(Math.random() * SERVER.length)]
  else
    SERVER

string2ArrayBuffer = (string) ->
  buf = new ArrayBuffer(string.length)
  arr = new Uint8Array(buf, 0, string.length)
  for i in [0..(string.length-1)]
    arr[i] = string.charCodeAt(i)
  buf
    
socket = chrome.socket
socket.create 'tcp', {}, (socketInfo) ->
  listen = socketInfo.socketId
  address = '0.0.0.0'
  port = PORT

  chrome.runtime.onSuspend.addListener ->
    chrome.socket.destroy listen
    
  socket.listen listen, address, port, (result)->
    console.assert(0 == result)
    socket.getInfo listen, (info) ->
      console.log('server listening on http://localhost:' + info.localPort)
      accept = (acceptInfo) ->
        console.assert acceptInfo.resultCode == 0
        socket.accept listen, accept
        local = acceptInfo.socketId
  
        encryptor = new Encryptor(KEY, METHOD)
        # connect remote now
        chrome.socket.create 'tcp', {}, (socketInfo) ->
          remote = socketInfo.socketId
          chrome.socket.connect remote, SERVER, REMOTE_PORT, (result)->
            console.assert(0 == result)
            chrome.socket.read local, 256, (readInfo)->
              console.assert readInfo.resultCode > 0
              chrome.socket.write local, string2ArrayBuffer('\x05\x00'), (readInfo) ->
                console.assert readInfo.bytesWritten == 2
                console.log readInfo
                chrome.socket.read local, 3, (readInfo)->
                  console.assert readInfo.resultCode > 0
                  console.log readInfo
                  chrome.socket.write local, string2ArrayBuffer('\x05\x00\x00\x01\x00\x00\x00\x00\x00\x00'), (readInfo) ->
                    console.assert readInfo.bytesWritten == 10
                    localToRemote=(readInfo) ->
                      console.assert readInfo.resultCode > 0
                      if readInfo.resultCode <= 0
                        return
                      data = readInfo.data
                      console.log readInfo
                      data = encryptor.encrypt(data)
                      chrome.socket.write remote, data, (readInfo)->
                        console.assert readInfo.bytesWritten > 0
                        chrome.socket.read local, BUF_SIZE,localToRemote 
                    remoteToLocal=(readInfo) ->
                      console.assert readInfo.resultCode > 0
                      if readInfo.resultCode <= 0
                        return
                      data = readInfo.data
                      console.log readInfo
                      data = encryptor.decrypt(data)
                      chrome.socket.write local, data, (readInfo)->
                        console.assert readInfo.bytesWritten > 0
                        chrome.socket.read remote, BUF_SIZE,remoteToLocal
                    chrome.socket.read local, BUF_SIZE,localToRemote
                    chrome.socket.read remote, BUF_SIZE,remoteToLocal
      socket.accept listen, accept
 
                      
                
              


