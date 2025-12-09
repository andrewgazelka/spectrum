# quick start

## if you're a spectrum user having ssl issues

```bash
git clone ssh://git@codeberg.org/azzie/spectrum.git
cd spectrum/client-tests
./run-tests.sh
```

look at the output. if you see `ff ff ff ff ff`, you hit the bug.

upload the `results/` folder to https://codeberg.org/azzie/spectrum/issues

## if you run a website

and spectrum users can't connect:

```bash
git clone ssh://git@codeberg.org/azzie/spectrum.git
cd spectrum/server-analysis
./analyze-logs.sh /var/log/nginx/access.log
```

check the output for spectrum asn failures.

## if you want to help collect data

host the diagnostic page:

```bash
git clone ssh://git@codeberg.org/azzie/spectrum.git
cd spectrum/web
python3 -m http.server 8080
```

share http://your-server:8080/diagnostic.html with spectrum users.

or run the report collector:

```bash
node report-collector.js
```

reports get saved to `results/web-reports/`.

## precomputed data

check `research-results/` for:
- 5600+ spectrum ip ranges across 15 asns
- downloaded network management policy pages
- asn/company mapping
- see summary.md for overview

this was all generated automatically, no spectrum access needed.

## requirements

client tests need:
- bash
- curl
- openssl
- traceroute

server analysis needs:
- bash
- whois

web stuff needs:
- python3 (for simple server)
- node.js (for report collector)

## what to report

when filing an issue, include:

1. your location (city, state)
2. your spectrum asn (from test output)
3. when it happens (always? sometimes? time of day?)
4. test results from `results/` folder
5. what you were trying to access

the more data we have, the better the fcc complaint.
