# ThreatBrain – Source Collector Scripts

Feed-collector scripts and source-evaluation material from **ThreatBrain**, a
Private Threat Intelligence platform prototyped at the TIM Security Lab in
2014 within the ELIS Junior Consultant programme.

> **Scope of this repository.** ThreatBrain as a whole was a Ruby on Rails web
> application (dashboard, reputation engine, source-ranking algorithm, vendor
> export policies). This repository contains only the *public-feed collector
> scripts* (`sourceScript/`) and the *third-party source analysis*
> (`analysis/`) that preceded them. The web application, the ranking engine,
> the vendor export scripts and the collectors for internal (non-public)
> sources are **not** included.

## What ThreatBrain did

ThreatBrain collected Indicators of Compromise (IoCs) from public and private
feeds, normalised them, scored them, and pushed them to network security
appliances. The pipeline was:

1. **Sources** – one Ruby script per feed, run periodically by the platform.
   Each script downloads the feed and emits a normalised XML file.
2. **Reputation** – every element (Hash, IP, URL, Domain) receives a reputation
   on a configurable scale. Hashes are checked against VirusTotal; detections
   above a threshold mark the element as malicious, otherwise a default
   reputation is assigned.
3. **Source ranking** – each source is re-scored periodically from
   (a) the false positives it produced and (b) the average change in
   VirusTotal detection between two observations separated by a configurable
   period. Antivirus engines are weighted using the AV-TEST classification.
4. **Vendors and policies** – a policy defines which element types, above
   which reputation and source rank, are exported to a given vendor (e.g. a
   security gateway) and at which frequency, through a vendor-specific Ruby
   script.
5. **Dashboard** – statistics per source and per vendor, false-positive
   management, and the four per-type source rankings.

## Repository layout

```
.
├── sourceScript/                  # one collector script per public feed
│   ├── blocklistde.script.rb
│   ├── cybercrime.script.rb
│   ├── iscsans.script.rb
│   ├── kleissner.script.rb
│   ├── malc0de.script.rb
│   ├── malwaredomainlist.script.rb
│   ├── malwareurls.script.rb
│   ├── nothink.script.rb
│   ├── openbl.script.rb
│   ├── supportcleanmx.script.rb
│   ├── vxvault.script.rb
│   └── zeustracker.script.rb
├── analysis/                      # source evaluation, July–October 2014 (Italian)
│   ├── ranking_2014-07_first-pass.xlsx   # first scoring of ~45 candidate feeds
│   ├── ranking_2014-10_final_v0.3.xlsx   # final scoring, per IoC type
│   ├── feed_overlap_2014-07.xlsx         # pairwise overlap between feeds
│   ├── notes_spam-dnsbl-providers.docx   # notes on LashBack, CBL, Spamhaus
│   └── csv/                              # the same sheets as CSV
├── LICENSE
└── README.md
```

## Collector scripts

### Contract with the platform

Every script follows the same minimal protocol:

- **Input** – one line on *stdin*: the directory where the output XML must be
  written (trailing slash included).
- **Output** – `<output dir>/<source>.xml` with the structure below, plus
  progress messages on *stdout*.
- **Proxy** – the outbound proxy is taken from the `http_proxy` environment
  variable.

```xml
<Items>
  <Item>
    <Type>Hash | Ip | Url | Domain</Type>
    <Value>…</Value>
    <Date>…</Date>                <!-- optional, if the feed provides it -->
    <Reputation>…</Reputation>    <!-- optional, if the feed provides it -->
    <Comment>…</Comment>          <!-- optional -->
    <HashAlgorithm>MD5|SHA1</HashAlgorithm>  <!-- Hash items only -->
  </Item>
</Items>
```

Each script validates entries with a regular expression per type (IPv4,
domain, MD5) or with `URI.parse` for URLs, and silently drops anything that
does not match.

### Sources

| Script | Feed | IoC types | Feed status (checked Sep 2026) |
|---|---|---|---|
| `blocklistde.script.rb` | api.blocklist.de `getlast.php` | IP | alive |
| `cybercrime.script.rb` | cybercrime-tracker.net `all.php` | URL | alive |
| `iscsans.script.rb` | isc.sans.edu `suspiciousdomains_High.txt` | Domain | discontinued (404) |
| `kleissner.script.rb` | kleissner.org ZeuS GameOver domains | Domain | offline |
| `malc0de.script.rb` | malc0de.com RSS | Domain, IP, URL, Hash | discontinued (404) |
| `malwaredomainlist.script.rb` | malwaredomainlist.com `mdl.xml` | Domain, IP, URL, Hash | discontinued (domain parked) |
| `malwareurls.script.rb` | malwareurls.joxeankoret.com | Domain, URL | discontinued (404) |
| `nothink.script.rb` | nothink.org honeypot MD5 list | Hash | discontinued (404) |
| `openbl.script.rb` | openbl.org `base_1days.txt` | IP | discontinued (403) |
| `supportcleanmx.script.rb` | support.clean-mx.de `xmlviruses.php` | Hash | unreachable |
| `vxvault.script.rb` | vxvault.siri-urz.net `URL_List.php` | URL | moved to vxvault.net (alive) |
| `zeustracker.script.rb` | zeustracker.abuse.ch RSS + binaries feed | Domain, IP, URL, Hash | retired by abuse.ch in 2019 |

The platform also ingested two internal TIM sources (a honeynet hpfeeds API
and a mobile-security lab hash list). Those collectors are not published.

The `zeustracker` script also maps the feed's hosting "level" to a human
readable comment (fast-flux, free hosting, hacked webserver, bulletproof
hosting).

### Requirements

- Ruby 1.9/2.x (the code was developed in 2014)
- gems: `curb`, `nokogiri`

```sh
gem install curb nokogiri
```

### Running a script by hand

```sh
cd sourceScript
export http_proxy=http://proxy.example:3128   # optional
echo "/tmp/out/" | ruby blocklistde.script.rb
cat /tmp/out/blocklistde.xml
```

## Source evaluation (`analysis/`)

Before writing collectors, about 45 public feeds were surveyed and scored.
The final methodology (`ranking_2014-10_final_v0.3.xlsx`) scores each feed,
separately for Hash, IP, Domain and URL, on:

| Criterion | Weight | Scale (1 / 3 / 7) |
|---|---|---|
| List reputation (share of a 200-entry sample reported by VirusTotal) | 0.40 | < 40 % / 40–70 % / > 70 % |
| Update frequency | 0.25 | weekly / daily / real-time |
| Number of entries | 0.10 | < 5 000 / 5 000–25 000 / > 25 000 |
| Ease of download | 0.20 | HTML parsing / file download / API or rsync |
| Credibility (partners, adoption by others) | 0.05 | none / minor / strong |

`feed_overlap_2014-07.xlsx` reports the pairwise overlap between feeds for
domains, IPs and hashes (entries and fraction of each list found in the
other), which was used to judge how complementary the sources were. Overlap
between most pairs was below 1 %.

References consulted during the evaluation:

- M. Kührer, T. Holz, *An Empirical Analysis of Malware Blacklists*,
  PIK 35(1), 2012.
- F. Leder, T. Werner, *Know Your Enemy: Containing Conficker*, The Honeynet
  Project, 2009. https://www.honeynet.org/papers/kye-containing-conficker/
- Cuckoo Sandbox Book, release 1.1, 2014. https://cuckoo.readthedocs.io/

## Authors

Andrea Morichetta, with Giovanni Urbinello and Claudio Cavina, supervised by
Davide Pellegrino (TIM Security Lab). ELIS Junior Consultant programme,
June–December 2014.

## Status and licence

Historical, unmaintained. The scripts target 2014 feed formats and most of
those feeds no longer exist; the code is published for reference under the
MIT licence (see `LICENSE`).
