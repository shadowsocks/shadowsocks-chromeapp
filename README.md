shadowsocks-chromeapp
===========

This is Chrome App version of shadowsocks.

Note that this version **does not work on Windows** due to the Chrome socket
API is experimental and buggy.

Other ports and clients can be found
[here](https://github.com/clowwindy/shadowsocks/wiki/Ports-and-Clients).

usage
-----------

First, update your Chrome to the newest version.

Open [chrome://flags](chrome://flags) , enable `Experimental Extension APIs`,
restart Chrome.

Open [chrome://extensions/](chrome://extensions/), check `Developer Mode`.
Click `Load Unpacked Extension`, select the root directory of this project.

Open a new Tab, click Apps, then click shadowsocks. Fill in the blanks and click
`Save`.