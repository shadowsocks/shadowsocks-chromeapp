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


SOCKS5 = (config) ->
  @socket_info = {}
  @socket_server_id = null
  {@server, @server_port, @password, @method, @local_port, @timeout} = config
  setInterval () =>
    do @sweep_socket
  , @timeout * 1000
  return


SOCKS5::handle_accept = (info) ->
  {socketId, clientSocketId} = info
  return if socketId isnt @socket_server_id
  @socket_info[clientSocketId] =
    type:            "local"
    status:          "auth"
    cipher:          new Encryptor @password, @method
    socket_id:       clientSocketId
    cipher_action:   "encrypt"
    peer_socket_id:  null
    last_connection: do Date.now
  chrome.sockets.tcp.setPaused clientSocketId, false
  # console.debug "Accepting to new socket: #{clientSocketId}"


SOCKS5::handle_recv = (info) ->
  {socketId, data} = info
  if socketId not of @socket_info
    console.debug "Unknown or closed socket: #{socketId}"
    return

  array = new Uint8Array data
  switch @socket_info[socketId].status
    when "cmd" then @cmd socketId, array
    when "auth" then @auth socketId, array
    when "tcp_relay" then @tcp_relay socketId, array
    else console.error "FSM: Not a valid state."


SOCKS5::handle_accepterr = (info) ->
  {socketId, resultCode} = info
  console.warn "Accepting on server socket #{socketId} occurs accept error #{resultCode}"


SOCKS5::handle_recverr = (info) ->
  {socketId, resultCode} = info
  console.debug "Socket #{socketId} occurs receive error #{resultCode}" if resultCode isnt -100
  @close_socket socketId


SOCKS5::listen = () ->
  chrome.sockets.tcpServer.create {}, (createInfo) =>
    @socket_server_id = createInfo.socketId
    chrome.sockets.tcpServer.listen @socket_server_id, '0.0.0.0', @local_port, (result) =>
      if result < 0 or chrome.runtime.lastError
        console.error "Listen on port #{@local_port} failed:", chrome.runtime.lastError
        chrome.sockets.tcpServer.close @socket_server_id
        @socket_server_id = null
        return

      console.debug "Listening on port #{@local_port}..."
      chrome.sockets.tcpServer.onAccept.addListener      @accept_handler = (info) =>    @handle_accept info
      chrome.sockets.tcpServer.onAcceptError.addListener @accepterr_handler = (info) => @handle_accepterr info
      chrome.sockets.tcp.onReceive.addListener           @recv_handler = (info) =>      @handle_recv info
      chrome.sockets.tcp.onReceiveError.addListener      @recverr_handler = (info) =>   @handle_recverr info


SOCKS5::terminate = () ->
  chrome.sockets.tcpServer.onAccept.removeListener       @accept_handler
  chrome.sockets.tcpServer.onAcceptError.removeListener  @accepterr_handler
  chrome.sockets.tcp.onReceive.removeListener            @recv_handler
  chrome.sockets.tcp.onReceiveError.removeListener       @recverr_handler

  chrome.sockets.tcpServer.close @socket_server_id
  @socket_server_id = null

  for socket_id in @socket_info
    @close_socket socket_id, false
  return


SOCKS5::auth = (socket_id, data) ->
  if data[0] isnt 0x05  # VER
    @close_socket socket_id
    console.warn "Not a valid SOCKS5 auth packet, closed."
    return

  if Common.typedIndexOf(data, 0x00, 2) is -1   # Bypass VER and NMETHODS
    console.warn "Client doesn't support no authentication."
    chrome.sockets.tcp.send socket_id, new Uint8Array([0x05, 0xFF]).buffer, () =>
      @close_socket socket_id
    return

  chrome.sockets.tcp.send socket_id, new Uint8Array([0x05, 0x00]).buffer, () =>
    @socket_info[socket_id].status = "cmd"
    @socket_info[socket_id].last_connection = do Date.now
    # console.debug "SOCKS5 auth passed"


SOCKS5::cmd = (socket_id, data) ->
  if data[0] isnt 0x05 or data[2] isnt 0x00   # VER and RSV
    console.warn "Not a valid SOCKS5 cmd packet."
    @close_socket socket_id
    return

  header = Common.parseHeader data
  switch header.cmd
    when 0x01 then @cmd_connect  socket_id, header, data
    when 0x02 then @cmd_bind     socket_id, header, data
    when 0x03 then @cmd_udpassoc socket_id, header, data
    else
      reply = Common.packHeader 0x07, 0x01, '0.0.0.0', 0
      chrome.sockets.tcp.send socket_id, reply.buffer, () =>
        @close_socket socket_id
      console.error "Not a valid CMD field."
  @socket_info[socket_id].last_connection = do Date.now


SOCKS5::cmd_connect = (socket_id, header, origin_data) ->
  chrome.sockets.tcp.create name: 'remote_socket', (createInfo) =>
    @socket_info[socket_id].peer_socket_id = createInfo.socketId

    chrome.sockets.tcp.connect createInfo.socketId, @server, @server_port, (result) =>
      error_reply = Common.packHeader 0x01, 0x01, '0.0.0.0', 0
      if result < 0 or chrome.runtime.lastError
        console.error "Failed to connect to shadowsocks server:", chrome.runtime.lastError
        chrome.sockets.tcp.send socket_id, error_reply.buffer, () =>
          @close_socket socket_id
        return

      @socket_info[createInfo.socketId] =
        type:            "remote"
        status:          "tcp_relay"
        cipher:          new Encryptor @password, @method
        socket_id:       createInfo.socketId
        peer_socket_id:  socket_id
        cipher_action:   "decrypt"
        last_connection: do Date.now

      data = @socket_info[socket_id].cipher.encrypt new Uint8Array origin_data.subarray 3
      chrome.sockets.tcp.send createInfo.socketId, data.buffer, (sendInfo) =>
        if sendInfo.resultCode < 0 or chrome.runtime.lastError
          console.error "Failed to send encrypted request to shadowsocks server:", chrome.runtime.lastError
          chrome.sockets.tcp.send socket_id, error_reply.buffer, () =>
            @close_socket socket_id
          return

        data = Common.packHeader 0x00, 0x01, '0.0.0.0', 0
        chrome.sockets.tcp.send socket_id, data.buffer, (sendInfo) =>
          if sendInfo.resultCode < 0 or chrome.runtime.lastError
            console.error "Failed to send connect success reply to client:", chrome.runtime.lastError
            @close_socket socket_id
            return

          @socket_info[socket_id].status = "tcp_relay"
          # console.debug "SOCKS5 connect okay"


SOCKS5::cmd_bind = (socket_id, header, origin_data) ->
  console.warn "CMD BIND is not implemented in shadowsocks."
  data = Common.packHeader 0x07, 0x01, '0.0.0.0', 0
  chrome.sockets.tcp.send socket_id, data.buffer, () =>
    @close_socket socket_id


SOCKS5::cmd_udpassoc = (socket_id, header, origin_data) ->
  console.error "Not implemented yet."


SOCKS5::tcp_relay = (socket_id, data_array) ->
  socket_info = @socket_info[socket_id]
  socket_info.last_connection = do Date.now
  peer_socket_id = socket_info.peer_socket_id
  @socket_info[peer_socket_id].last_connection = do Date.now

  data = socket_info.cipher[socket_info.cipher_action](data_array)
  chrome.sockets.tcp.send peer_socket_id, data.buffer, (sendInfo) =>
    if sendInfo.resultCode < 0 or chrome.runtime.lastError and socket_id of @socket_info
      console.debug "Failed to relay data from #{socket_info.type}
        #{socket_id} to peer #{peer_socket_id}:", chrome.runtime.lastError
      @close_socket socket_id
      return


SOCKS5::close_socket = (socket_id, close_peer = true) ->
  if socket_id of @socket_info
    peer_socket_id = @socket_info[socket_id].peer_socket_id
    delete @socket_info[socket_id]['cipher']
    delete @socket_info[socket_id]
  chrome.sockets.tcp.close socket_id, () ->
    if chrome.runtime.lastError
      console.debug "Error on close socket #{socket_id}", chrome.runtime.lastError
  # console.debug "Socket #{socket_id} closed"
  if peer_socket_id of @socket_info and close_peer
    @close_socket peer_socket_id, false


SOCKS5::sweep_socket = () ->
  console.debug "Sweeping timeout socket..."
  for socket_id, socket of @socket_info
    if Date.now() - socket.last_connection >= @timeout * 1000
      chrome.sockets.tcp.getInfo socket_id, (socketInfo) =>
        @close_socket socket_id if not socketInfo.connected
        console.debug "Socket #{socket_id} has been swept"
  return