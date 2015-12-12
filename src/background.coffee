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


sswindow = null
sslocal = new SOCKS5()

chrome.app.runtime.onLaunched.addListener () ->
  chrome.app.window.create '../views/window.html',
    id: 'shadowsocks-gui'
    innerBounds:
      width:  360
      height: 480
    resizable: false
  , (createdWindow) ->
    if createdWindow isnt sswindow
      sswindow = createdWindow
      sswindow.onMinimized.addListener () ->
        do sswindow.hide
    do sswindow.show


chrome.runtime.onMessage.addListener (msg, sender, sendResp) ->
  {type, config} = msg;
  return if type isnt "SOCKS5OP"
  sslocal.terminate () ->
    sslocal.config config if config
    sslocal.listen (info) ->
      sendResp info
  return true
