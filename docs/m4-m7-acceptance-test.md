# M4–M7 acceptance test — v0.4.0

Run this on real phones after v0.4.0 is published, then fill in [acceptance-report.md](acceptance-report.md).
When everything required passes, the build is tagged **v1.0.0-poc**. Tick each box or write what you saw.

| | Phone 1 | Phone 2 |
|---|---|---|
| Model | | |
| Android version | | |
| Earphones / headset | | |
| Network (Wi-Fi / mobile) | | |

## 1. Update from 0.3.0

- [ ] Opening 0.3.0 offers **Update available · 0.4.0** with the What's new notes; Update now installs it.
- [ ] The one-time **What's new in 0.4.0** sheet appears; Settings → About shows v0.4.0 (4).

## 2. Definition of MVP complete (spec §16)

- [ ] Choose any two of English, Hindi and Gujarati (Languages tab), start **In-person conversation**.
- [ ] **Listen**: the other person's speech appears live, then the translation, which plays in your earphones.
- [ ] **Speak**: your reply is translated and plays aloud on the phone speaker.
- [ ] Both texts are on screen; **End conversation** shows the summary; Done returns Home.
- [ ] No loop: the app never translates its own voice (try 10 turns in a quiet room and 10 with background noise).
- [ ] After End, the microphone indicator at the top of the screen goes off within half a second.

## 3. Six directions

For each row, one Listen turn and one Speak turn. ASR = the text is right; Translation = it means the same; Voice = you heard it.

| Direction | ASR | Translation | Voice | Notes |
|---|---|---|---|---|
| English → Hindi | | | | |
| Hindi → English | | | | |
| English → Gujarati | | | | |
| Gujarati → English | | | | |
| Hindi → Gujarati | | | | |
| Gujarati → Hindi | | | | |

## 4. Hands-free turns

- [ ] Tap **Listen** once: after each translation has played, it listens again by itself (the chip shows LISTENING).
- [ ] It never listens while a translation is playing (SPEAKING), and the waveform moves with the voice.
- [ ] **Pause** stops the microphone and the voice at once; a sentence half said is kept and translated, not spoken.
- [ ] **Speak** during Listen mode: your reply plays, then listening resumes.
- [ ] Say nothing for a minute: it pauses with **Listening paused after a minute of silence**.
- [ ] Turn on airplane mode while listening: it pauses with the connection notice, and doesn't keep retrying.
- [ ] A phone call or alarm during playback pauses the session (**Paused for a call or alarm**).
- [ ] Press Home during a conversation: it pauses; coming back does not open the microphone by itself.
- [ ] Revoke the microphone permission in Android settings mid-session: the notice offers **Allow**, no dialog loop.

## 5. Automatic language detection (S3) — Android 14 or later

Set the other person's language to **Automatic detection**. Record 60 short clips: 20 per language that isn't yours.
Mark each: **D** = detected right (card says DETECTED), **U** = "Language unclear" (asked you), **W** = wrong language.
Pass: at least 90% D+U, at most 5% W.

| Language | D | U | W |
|---|---|---|---|
| | | | |
| | | | |

- [ ] An unclear card offers the languages; picking the right one translates it; picking another asks them to repeat.
- [ ] Below Android 14: Settings shows the switch disabled, and the app asks the language once, then remembers it.

## 6. Review your reply

- [ ] Settings → **Review my reply before playing** on: a reply waits with Edit, Play and Discard.
- [ ] Edit changes the text and translates again; Play speaks it on the speaker; Discard removes it.

## 7. Saved conversations

- [ ] With **Save conversations** off (default), End offers **Save to history**; nothing is saved unless you tap it.
- [ ] With it on, every ended conversation appears in History (Home → History, and Recent conversations on Home).
- [ ] Search finds a word from the original and from the translation.
- [ ] Detail shows both languages with times; Copy and Share work (try sharing to WhatsApp or Gmail).
- [ ] Delete removes one; Settings → Delete all conversations removes all; turning saving off asks Keep or Delete all.
- [ ] Kill the app (swipe it away) mid-conversation with saving on: the conversation is in History afterwards.

## 8. Voices, speed and languages

- [ ] Settings → Speech speed Slow / Normal / Fast changes how fast the next translation is spoken.
- [ ] Settings → Voices lists voices per language; Test speaks the sample; a chosen voice is used in conversations.
- [ ] Languages tab: each language shows Speech input, Offline translation and Voice status that match the phone.
- [ ] Download (offline model) works on mobile data when you choose **Use mobile data too**.

## 9. App in Hindi and Gujarati (owner review, spec R47)

- [ ] Settings → App language → हिन्दी: every screen reads naturally. Note wording to change: ______________________
- [ ] Settings → App language → ગુજરાતી: same. Note wording to change: ______________________
- [ ] Phone's language follows the phone; a phone in another language gets English.

## 10. Meeting mode

- [ ] Home → **Online meeting** explains that Android can't capture Zoom/Meet/Teams/WhatsApp audio.
- [ ] Test microphone with a meeting playing on a laptop nearby shows **We heard: …**.
- [ ] Start needs the consent box; the meeting session listens continuously, with no Speak button.

## 11. Accessibility

- [ ] TalkBack: each card is read as one sentence ("Other person, Hindi: … Translation: …"); the status is announced.
- [ ] Android font size at the largest setting: no cut-off or overlapping text on Home, Conversation, Settings.

## 12. Latency (spec R35)

- [ ] Do 20 turns per direction you use, on good Wi-Fi.
- [ ] Settings → Latency report shows each pair; note the **End of speech → first audio** median and p95 below.
- [ ] Export CSV and attach it to the acceptance report.

| Pair | Turns | Median (s) | p95 (s) | Under 3 s p95? |
|---|---|---|---|---|
| | | | | |
