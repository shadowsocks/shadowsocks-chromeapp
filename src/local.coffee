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

socket = chrome.socket

class Local
  constructor: (config)->
    SERVER = config.server
    REMOTE_PORT = +config.server_port
    PORT = +config.local_port
    KEY = config.password
    METHOD = config.method

    BUF_SIZE = 1500

    that = @
    # this pointer is not correct in Chrome socket callbacks
    # so use enclosure instead

    string2ArrayBuffer = (string) ->
      buf = new ArrayBuffer(string.length)
      arr = new Uint8Array(buf, 0, string.length)
      for i in [0..(string.length - 1)]
        arr[i] = string.charCodeAt(i)
      buf

    socket.create 'tcp', {}, (socketInfo) ->
      that.listen = socketInfo.socketId
      listen = that.listen
      console.log "listen: #{listen}"
      address = '0.0.0.0'
      port = PORT

      chrome.runtime.onSuspend.addListener ->
        console.log 'closing listen socket'
        chrome.socket.destroy listen

      socket.listen listen, address, port, (result)->
        console.log 'listen'
        console.assert(0 == result)
        socket.getInfo listen, (info) ->
          console.log('server listening on http://localhost:' + info.localPort)
          accept = (acceptInfo) ->
            if acceptInfo.resultCode != 0
              return
            console.assert acceptInfo.resultCode == 0
            socket.accept listen, accept
            console.log 'socket.accept'
            local = acceptInfo.socketId
            console.log "accept #{local}"

            encryptor = new Encryptor(KEY, METHOD)
            # connect remote now
            socket.create 'tcp', {}, (socketInfo) ->
              remote = socketInfo.socketId
              socket.connect remote, SERVER, REMOTE_PORT, (result)->
                console.log "connect #{remote}"
                if result != 0
                  console.log "destroy #{local} #{remote}"
                  socket.destroy local
                  socket.destroy remote
                  return
                console.assert(0 == result)
                socket.read local, 256, (readInfo)->
                  console.assert readInfo.resultCode > 0
                  socket.write local, string2ArrayBuffer('\x05\x00'), (readInfo) ->
                    console.assert readInfo.bytesWritten == 2
                    socket.read local, 3, (readInfo)->
                      console.assert readInfo.resultCode > 0
                      socket.write local, string2ArrayBuffer('\x05\x00\x00\x01\x00\x00\x00\x00\x00\x00'), (readInfo) ->
                        console.assert readInfo.bytesWritten == 10
                        localToRemote=(readInfo) ->
                          if readInfo.resultCode <= 0
                            console.log "destroy #{local} #{remote}"
                            socket.destroy local
                            socket.destroy remote
                            return
                          console.assert readInfo.resultCode > 0
                          data = readInfo.data
                          data = encryptor.encrypt(data)
                          socket.write remote, data, (readInfo)->
                            if readInfo.bytesWritten <= 0
                              console.log "destroy #{local} #{remote}"
                              socket.destroy local
                              socket.destroy remote
                              return
                            console.assert readInfo.bytesWritten == data.byteLength
                            socket.read local, BUF_SIZE, localToRemote
                        remoteToLocal=(readInfo) ->
                          if readInfo.resultCode <= 0
                            console.log "destroy #{local} #{remote}"
                            socket.destroy remote
                            socket.destroy local
                            return
                          console.assert readInfo.resultCode > 0
                          data = readInfo.data
                          data = encryptor.decrypt(data)
                          socket.write local, data, (readInfo)->
                            if readInfo.bytesWritten <= 0
                              console.log "destroy #{local} #{remote}"
                              socket.destroy local
                              socket.destroy remote
                              return
                            console.assert readInfo.bytesWritten == data.byteLength
                            socket.read remote, BUF_SIZE, remoteToLocal
                        socket.read local, BUF_SIZE, localToRemote
                        socket.read remote, BUF_SIZE, remoteToLocal
          socket.accept listen, accept

  close: ->
    console.log @listen
    if @listen
      socket.destroy @listen

window.Local = Local




