shadowsocks-chromeapp
===========

This is Chrome App version of shadowsocks.

Other ports and clients could be found at
[here](https://github.com/shadowsocks/shadowsocks/wiki/Ports-and-Clients).

Usage
-----------

This app needs Chrome version higher than 41 (include 41).

Since this is a development version, node.js and CoffeeScript is required for build.
You can run `cake build` under root directory to build once
or use `cake watch` to watch the code change.

Open chrome://extensions/, check `Developer Mode`.
Click `Load Unpacked Extension`, select the root directory of this project.

Open a new Tab, click Apps, then click shadowsocks. Fill in the blanks and click
`Save`.

Minimize the window will hide it from taskbar, but will not affect the proxy function,
if you have enabled Chrome background app support,
close all Chrome window will not affect the proxy function too.

Encryption methods
-----------

Currently, this app supports the following encryption methods:
* RC4-MD5
* AES-128-CFB
* AES-192-CFB
* AES-256-CFB
* AES-128-OFB
* AES-192-OFB
* AES-256-OFB
* AES-128-CTR
* AES-192-CTR
* AES-256-CTR