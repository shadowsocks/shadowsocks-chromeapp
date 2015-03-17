/**
 Copyright (c) 2014 clowwindy

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 **/

var RC4 = function(key) { "use strict";
    if (!(this instanceof RC4))
        return new RC4(key);

    // [] is faster than Uint8Array in Chrome
    var s = [], i, j = 0, x;
    for (i = 0; i < 256; i++) {
        s[i] = i;
    }
    for (i = 0; i < 256; i++) {
        j = (j + s[i] + key[i % key.length]) % 256;
        x = s[i];
        s[i] = s[j];
        s[j] = x;
    }
    this._s = s;
    this._i = 0;
    this._j = 0;
};

RC4.prototype.update = function(cipherText, plainText, bytes) { "use strict";
    var x, y, p, i = this._i, j = this._j, s = this._s;
    for (p = 0; p < bytes; p++) {
        i = (i + 1) % 256;
        x = s[i];
        j = (j + x) % 256;
        y = s[j];
        s[i] = y;
        s[j] = x;
        cipherText[p] = plainText[p] ^ s[(x + y) % 256];
    }
    this._i = i;
    this._j = j;
};
