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


logging = 
  VERBOSE:  0x01   # For raw data transfer log
  DEBUG:    0x03   # For handshake, auth, cmd and transfer event log
  LOG:      0x07   # For SOCKS5 link establish log 
  INFO:     0x0F   # For generic error
  WARN:     0x1F   # For warning
  ERROR:    0x3F   # For unrecoverable error
  _empty:   ()->


logging.setLevel = (level) ->
  console._verbose = if (level & logging.VERBOSE) is level then console.debug else logging._empty
  console._debug   = if (level & logging.DEBUG)   is level then console.debug else logging._empty
  console._log     = if (level & logging.LOG)     is level then console.log   else logging._empty
  console._info    = if (level & logging.INFO)    is level then console.info  else logging._empty
  console._warn    = if (level & logging.WARN)    is level then console.warn  else logging._empty
  console._error   = if (level & logging.ERROR)   is level then console.error else logging._empty
  return

logging.setLevel logging.WARN