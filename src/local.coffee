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

tcpServer = chrome.sockets.tcpServer
tcp = chrome.sockets.tcp

receiveCallbacks = {}

read = (sockId, callback) ->
  receiveCallbacks[sockId] = callback
  tcp.setPaused(sockId, false)

receiveRedirector = (info) ->
#  console.log 'receiveRedirector', info
  receiveCallbacks[info.socketId](info.data, null)

errorRedirector = (info) ->
#  console.error 'errorRedirector', info
  receiveCallbacks[info.socketId](null, info.resultCode)

tcp.onReceive.addListener receiveRedirector
tcp.onReceiveError.addListener errorRedirector

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

    tcpServer.create {}, (socketInfo) ->
      that.listen = socketInfo.socketId
      listen = that.listen
      console.log "listen: #{listen}"
      address = '0.0.0.0'
      port = PORT

      chrome.runtime.onSuspend.addListener ->
        console.log 'closing listen socket'
        chrome.tcpServer.close listen

      tcpServer.listen listen, address, port, (result)->
        console.log 'listen'
#        console.assert(0 == result)
        tcpServer.getInfo listen, (info) ->
          console.log('server listening on localhost:' + info.localPort)
          accept = (acceptInfo) ->
            console.log 'accepted'
            if acceptInfo.clientSocketId == 0
              return
            local = acceptInfo.clientSocketId
            console.log "accept #{local}"

            encryptor = new Encryptor(KEY, METHOD)
            # connect remote now
            tcp.create {}, (socketInfo) ->
              remote = socketInfo.socketId
              tcp.connect remote, SERVER, REMOTE_PORT, (result)->
                console.log "connect #{remote}"
                if result != 0
                  console.log "close #{local} #{remote}"
                  tcp.close local
                  tcp.close remote
                  delete receiveCallbacks[local]
                  delete receiveCallbacks[remote]
                  return
#                console.assert(0 == result)
                tcp.setPaused remote, true
                read local, (data, error)->
                  console.log 'read 1'
                  console.log data.byteLength

                  tcp.send local, string2ArrayBuffer('\x05\x00'), (readInfo) ->
                    console.log 'send 1'
                    console.log data.byteLength
                    console.assert readInfo.bytesSent == 2
                    read local, (data, error)->

                      console.log 'read 2'
                      console.log data.byteLength
                      addrToSend = new Uint8Array(data).subarray(3)
                      console.assert readInfo.resultCode > 0

                      tcp.send local, string2ArrayBuffer('\x05\x00\x00\x01\x00\x00\x00\x00\x00\x00'), (readInfo) ->
                        console.log 'send 2'
                        console.assert readInfo.bytesSent == 10
                        localToRemote=(data, error) ->
#                          console.log 'localToRemote'
                          if error
                            console.log "close #{local} #{remote}"
                            tcp.close local
                            tcp.close remote
                            delete receiveCallbacks[local]
                            delete receiveCallbacks[remote]
                            return
                          if addrToSend
                            # TODO use better ways
                            tmp = new Uint8Array(data.byteLength + addrToSend.byteLength)
                            tmp.set addrToSend, 0
                            tmp.set new Uint8Array(data), addrToSend.byteLength
                            addrToSend = null
                            data = tmp

#                          console.assert readInfo.resultCode > 0
                          data = encryptor.encrypt(data)
                          tcp.send remote, data, (sendInfo)->
#                            console.log 'remote sent'
#                            console.log sendInfo.bytesSent, sendInfo.resultCode
                            if sendInfo.resultCode < 0
                              console.log "close #{local} #{remote}"
                              tcp.close local
                              tcp.close remote
                              delete receiveCallbacks[local]
                              delete receiveCallbacks[remote]
                              return
#                            console.assert readInfo.bytesSent == data.byteLength
                        remoteToLocal=(data, error) ->
#                          console.log 'remoteToLocal'
                          if error
                            console.log "close #{local} #{remote}"
                            tcp.close remote
                            tcp.close local
                            delete receiveCallbacks[local]
                            delete receiveCallbacks[remote]
                            return
#                          console.assert readInfo.resultCode > 0
                          data = encryptor.decrypt(data)
                          tcp.send local, data, (sendInfo)->
#                            console.log 'local sent'
#                            console.log sendInfo.bytesSent, sendInfo.resultCode
                            if sendInfo.resultCode < 0
                              console.log "close #{local} #{remote}"
                              tcp.close local
                              tcp.close remote
                              return
#                            console.assert readInfo.bytesSent == data.byteLength
                        read local, localToRemote
                        read remote, remoteToLocal
          tcpServer.onAccept.addListener accept

  close: ->
    console.log @listen
    if @listen
      tcpServer.close @listen

window.Local = Local




