# spectrum ssl bug

spectrum/charter is breaking ssl connections to cloudflare sites. their transparent inspection gear returns garbage data (0xff bytes) instead of valid tls responses.

## what's happening

when you try to connect to sites behind cloudflare (like staging.drafted.ai), spectrum's middlebox intercepts the connection and returns 256 bytes of 0xff instead of a proper tls handshake. browsers show `ERR_SSL_PROTOCOL_ERROR`, openssl shows `packet length too long`.

this is sporadic - sometimes it works, sometimes it doesn't. seems to depend on region and time.

## if you're on spectrum

run the test to see if you're affected:

```bash
cd client-tests
chmod +x *.sh
./run-tests.sh
```

if you see the 0xff pattern in the output, you hit the bug.

for full diagnostics with packet capture:

```bash
sudo ./test-all.sh
```

this will create a `results/` folder with all the data. please upload that to the issues page.

## what the test does

checks your ip and isp, attempts tls 1.2 and 1.3 handshakes, tests ipv6 and http/3 (which sometimes bypass the bug), runs traceroute to find where interception happens, looks for the characteristic 0xff garbage pattern

## if you run a server

and you're seeing spectrum users fail to connect:

```bash
cd server-analysis
./analyze-logs.sh /path/to/your/access.log
```

this will parse your logs and count failures by asn.

## web diagnostic

open `web/diagnostic.html` in a browser or host it somewhere. it'll test connections and show if you're affected.

to collect reports from users:

```bash
cd web
node report-collector.js
```

this starts a server on port 8080 that serves the diagnostic page and saves reports.

## technical details

spectrum/charter/twc asns (15 total): AS3456, AS7843, AS10796, AS10994, AS11060, AS11351, AS11426, AS11427, AS12271, AS20001, AS20115, AS33363, AS33490, AS33491, AS63365

includes legacy time warner cable and bright house networks asns now owned by charter.

the bug pattern is always the same: 256 bytes of 0xff starting with `ff ff ff ff ff`. openssl interprets the first 5 bytes (0xffffffffff) as a ~4gb packet length and immediately fails.

## workarounds

what helps: vpn (bypasses spectrum's inspection), ipv6 (often not inspected), http/3 over udp (tcp-based inspection can't touch it), mobile data (different network)

what doesn't help: different tls versions, different cipher suites, different ports (they inspect all 443 traffic)

## why this matters

spectrum is running transparent ssl interception without disclosure. when it works, it's invasive. when it breaks (like this), it's unusable.

we're collecting evidence to file an fcc complaint because they're intercepting encrypted traffic without consent, their gear is broken and blocking legitimate sites, they don't disclose these practices, and it violates net neutrality (degrading specific traffic)

## how to help

if you're on spectrum and can reproduce this, run the tests, upload results to issues, note your location (city/state) and when it happens (time of day, consistency). we need data from multiple regions to show this is widespread.

## research tools

the `research/` folder has scripts to dig up more evidence:

```bash
cd research
./run-all.sh
```

fetches all spectrum ip ranges by asn, downloads spectrum's network management policies and searches for disclosure, researches dpi vendors and known bugs, searches for existing complaints online, looks up spectrum's legal/regulatory history. use this to find more ammunition for the fcc complaint.

## repo structure

```
client-tests/       tests you run if you're on spectrum
server-analysis/    scripts for analyzing server logs
web/                diagnostic page and report collector
research/           scripts to research spectrum practices
results/            where test output goes (created by tests)
```

## contact

open an issue at https://codeberg.org/azzie/spectrum/issues or message me on irc: azzie at libera.chat

this isn't theoretical, real users can't access real sites because spectrum's gear is busted.
