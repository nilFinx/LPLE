# LiquidProxy Lua Edition

Note: This repository is available in [tangled](https://tangled.org/nilfinx.tngl.sh/LPLE), [Codeberg](https://codeberg.org/nilfinx/LPLE) and [GitHub](https://github.com/nilFinx/LPLE).

GitHub is potentially being deprecated. Avoid linking whenever possible.

This is [LiquidProxy](https://tangled.org/nilfinx.tngl.sh/liquidproxy), but with Lua, and not Go.

WARNING: This has been uploaded publicly for sake of tracking my progress, and backing up the work. Features listed below may not exist, and the documentation is to be made. Feel free to try if you know what you're doing, but (MIT full-caps "no warranty" block)

## What this is

* A fix for "could not start a secure connection" and other TLS/SSL issues
* A way to connect to modern mail servers without TLS version/cipher limit
* A way to get online on Jabber/XMPP again, on old clients (with limited XEP compliance, of course. Maybe some ancient clients can still top some modern ones?)
* A fix for certain services (Apple Maps (partial) on older devices, GravityBox activation (use `YES` for transaction ID), and more?)

## What this isn't

* A fix for web browsing (no, you won't be able to browse the certain iconic websites on your 3G for a meme)
* A secure way to do anything at all (as you have an extra layer transmitting the stuff in older ciphers/SSL/TLS version, with an old and potentially insecure client)
* A fix for (insert app name) that has an incompatible different API by now (such as green shit, yellow garbage, fruit store, etc)
* A way to browse laggy websites without lag (device issue, website issue, doesn't matter)

## What this can be used for

* A normal HTTP proxy, as clients with TLSv1.3 and HTTP/2 will have the data just sent without MitM (assuming that the config is set up for it)
* To get mails on ancient devices that your mail provider rejects (likely including PDAs)
* To use some HTTP services with same or nearly compatible API (such as Cal/CardDAV)
* An alternative for many proxies, such as squid, primarily for uses with simple scripting to replace the HTTP request/response

## New features (compared to AquaProxy)

* Static web UI to quickly obtain the certificate
* Ability to block modern clients (if detected, don't rely on it)
* Ability to block ancient clients (TLSv1.1 or lower)
* Authentication (mess, but works)
* Better documentation and generally less headache of manually hosting it outside of legacy OSX

## New features (compared to LiquidProxy)

* More config options. Like way more.
* Improved config schema. Goodbye awkward text files, hello lua file!
* TODO: Fill more

## RISK WARNING

Do NOT use any third party instanced of LiquidProxy (Lua Edition or not), unless you trust them. Due to nature of TLS MitM proxies, the server owner is able to see everything that goes through the proxy. HTTPS WEBSITES WILL STILL BE INTERCEPTED! THERE IS NO WAY TO DEFEND AGAINST THIS RISK, OTHER THAN TO HOST YOUR OWN PROXY.

Exposed server = all local IPs are exposed. This is especially dangerous on certain VPSes because yes all users should be able to contact machine management APIs somehow (IIRC). Fix on that is planned but isn't here yet, due to complexity of implement such measures perfectly, only to pray that the user does not have a modified hosts file.

## Documentation

Documentation is available in [docs](./docs/install.md). Alternatively, use [my website](https://recycledplist.space/projects/liquidproxy/install) like before.

## LICENSE

This project uses LGPLv3.

cydia.css uses CSS from [cydia.saurik.com](https://cydia.saurik.com/), and few parts of index.html is taken from Victor Lobe's personal website ([gh:victorlobe/victorlobe.me](https://github.com/victorlobe/victorlobe.me)), as a reference on how to use cydia.css. Nothing too big, I think.

/ext includes lua-url and chunks of their extlib from [gh:thenumbernine](https://github.com/thenumbernine). MIT licensed. The license file is available under [ext/LICENSE](./ext/LICENSE).

Many parts of the code is taken from [gh:Wowfunhappy/AquaProxy](https://github.com/Wowfunhappy/AquaProxy). The license is available under [app/tlspeek.lua](./app/tlspeek.lua).

# TODO

More log_ip stuff.

