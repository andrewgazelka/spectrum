# research summary

automated research run on 2025-12-08

## spectrum asns discovered

found 15 total spectrum/charter/twc asns:
- AS3456, AS7843, AS10796, AS10994, AS11060
- AS11351, AS11426, AS11427, AS12271, AS20001
- AS20115, AS33363, AS33490, AS33491, AS63365

these include:
- charter communications (current)
- legacy time warner cable (acquired by charter)
- legacy bright house networks (acquired by charter)

## ip ranges

fetched complete ip range lists for all 15 asns via whois radb queries

total coverage: thousands of ip blocks across north america

see spectrum-ranges-*.txt for full lists

## network management policies

attempted to fetch spectrum's published network management practices from:
- https://www.spectrum.com/policies/network-management-practices
- https://www.spectrum.net/support/internet/network-management
- https://www.charter.com/about-us/policies
- https://www.spectrum.com/policies/privacy-policy

downloaded pages saved as page-*.html files

need manual review to check for ssl/tls inspection disclosure

## next steps for researchers

manual tasks still needed:
1. review downloaded policy pages for keywords: ssl, tls, inspection, decrypt, dpi, middlebox
2. search fcc complaint database for existing spectrum ssl issues
3. search reddit/twitter/github for user reports
4. identify dpi vendor (sandvine, allot, cisco, etc) from 0xff pattern
5. find procurement records showing what gear spectrum bought

## automated searches

generated search urls for:
- reddit r/spectrum threads (ssl error, https error, certificate error, cloudflare issues)
- twitter/x searches (@GetSpectrum ssl, charter https broken, tls errors)
- github issues (spectrum ssl, charter tls, isp ssl interception)
- stack overflow questions (isp breaking tls, charter ssl errors)

see complaints-20251208-202131.txt for all urls

## legal/regulatory research

generated search urls for:
- fcc enforcement actions (charter consent decree, spectrum complaints)
- class action lawsuits (securities fraud, consumer protection)
- state attorney general actions (ny ag, california ag)
- net neutrality violations (throttling, blocking, paid prioritization)

see legal-history-20251208-202131.txt for all urls

## dpi vendor research

researched potential vendors:
- sandvine packetlogic
- procera packetlogic
- allot netenforcer
- cisco waas
- bluecoat proxysg
- palo alto networks

generated cve search urls and exploit-db searches for each

academic paper searches:
- isp ssl interception
- transparent tls proxy
- middlebox tls failures
- deep packet inspection bugs

see dpi-vendors-20251208-202131.txt for all urls

## files in this directory

- summary.md (this file)
- spectrum-ranges-*.txt (5600+ ip ranges for 15 asns)
- spectrum-asns-*.txt (list of 15 asns with verification urls)
- network-practices-*.txt (urls to spectrum policy pages)
- page-*.html (downloaded policy pages, need manual review)
- complaints-*.txt (search urls for user reports)
- legal-history-*.txt (search urls for regulatory actions)
- dpi-vendors-*.txt (search urls for vendor identification)

run research/run-all.sh to regenerate all of this
