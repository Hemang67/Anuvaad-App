# Anuvaad POC — acceptance report

Fill this in from [m4-m7-acceptance-test.md](m4-m7-acceptance-test.md) and the exported latency CSV.
**v1.0.0-poc** is tagged on the build that passes every row marked *Required*.

- Build tested: v0.4.0 (4) or later: ______
- Tested by: ______  ·  Dates: ______
- Phones: ______

## Results

| # | Check | Required | Result (pass / fail / partial) | Notes |
|---|---|---|---|---|
| 1 | Update from the previous version installs and keeps settings | Yes | | |
| 2 | Definition of MVP complete (§2 of the sheet) | Yes | | |
| 3 | Six directions: ASR, translation and voice | Yes | | |
| 4 | Hands-free turns, Pause/End within half a second, no self-translation | Yes | | |
| 5 | Errors pause the session with a clear notice (network, mic, call/alarm, background) | Yes | | |
| 6 | S3 auto-detect: ≥ 90% detected-or-unclear, ≤ 5% wrong (Android 14+) | No — decides whether Automatic stays | | |
| 7 | Review reply: Edit, Play, Discard | Yes | | |
| 8 | History: off by default, saves when on or on Save, search/copy/share/delete | Yes | | |
| 9 | Voices, speech speed, language status | Yes | | |
| 10 | Hindi and Gujarati UI reviewed; wording fixes listed | Yes | | |
| 11 | Meeting mode | Yes | | |
| 12 | TalkBack and largest font size | Yes | | |
| 13 | Earbuds → you, speaker → reply, disconnect fallback (M3 sheet) | Yes | | |
| 14 | Latency: end of speech → first audio, p95 under 3 s on good Wi-Fi | No — target, not guarantee (R35) | | |

## Latency summary (from the CSV)

| Pair | Device | Network | Turns | Median (s) | p95 (s) |
|---|---|---|---|---|---|
| | | | | | |

## Issues found

| # | What happened | Phone | Severity | Fixed in |
|---|---|---|---|---|
| | | | | |

## Decision

- [ ] Every required row passes → tag **v1.0.0-poc** on build ______.
- [ ] Not yet → fixes listed above go into the next build, and this report is updated.
