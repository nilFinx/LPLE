# LiquidProxy Lua Edition

Note: This repository is available in [tangled](https://tangled.org/nilfinx.tngl.sh/LPLE), [Codeberg](https://codeberg.org/nilfinx/LPLE) and [GitHub](https://github.com/nilFinx/LPLE).

This is [LiquidProxy](https://tangled.org/nilfinx.tngl.sh/liquidproxy), but with Lua, and not Go.

WARNING: This has been uploaded publicly for sake of tracking my progress, and backing up the work. Features listed below may not exist, and the documentation is to be made. Feel free to try if you know what you're doing, but (MIT full-caps "no warranty" block)

## What this is

* A fix for "could not start a secure connection" and other TLS/SSL issues
* A way to connect to modern mail servers without TLS version/cipher limit

## What this isn't

* Complete fix for web browsing
* Secure way to do anything at all (as you're still seeing the stuff in older ciphers/SSL version)
* Fix for (insert app name) that has completely different API by now
* Fix for (insert tweak name)
* A way to browse (very few) laggy websites without lag

## What this should be used for

* A normal HTTP proxy, as clients with TLSv1.3 and HTTP/2 will have the data just sent without MitM (assuming that the force-mitm flag is off)
* Get mails on ancient devices that your mail provider rejects
* Use some HTTP services with same or compatible API (such as CalDAV on strict servers like Disroot)

## Extra features

* Static web UI to quickly obtain the certificate
* Ability to block modern clients (if detected, don't rely on it)
* Ability to block ancient clients (TLSv1.1 or lower)
* Authentication (mess, but works)
* Better documentation and generally less headache of manually hosting it outside of legacy OSX
* Mail and HTTP proxy combined into one project
* Source code is split into multiple files, making maintenance easier
* Makefile for building

## RISK WARNING

Do NOT use any third party instanced of LiquidProxy, unless you trust them. Due to nature of TLS MitM proxies, the server owner is able to see everything that goes through the proxy. HTTPS WEBSITES WILL STILL BE INTERCEPTED! THERE IS NO WAY TO DEFEND AGAINST THIS RISK, OTHER THAN TO HOST YOUR OWN PROXY.

Exposed servers = all local IPs are exposed. Fix on that is planned but isn't here yet.

## Documentation

Documentation is available in [docs](./docs/install.md). Alternatively, use [my website](https://recycledplist.space/projects/liquidproxy/install) like before.

## LICENSE

This project uses LGPLv3.

cydia.css uses CSS from [cydia.saurik.com](https://cydia.saurik.com/), and few parts of index.html is taken from Victor Lobe's personal website ([gh:victorlobe/victorlobe.me](https://github.com/victorlobe/victorlobe.me)), as a reference on how to use cydia.css. Nothing too big, I think.

/ext includes lua-url and ext from [gh:thenumbernine](https://github.com/thenumbernine). MIT licensed. The license file is available under [ext/LICENSE](./ext/LICENSE).
