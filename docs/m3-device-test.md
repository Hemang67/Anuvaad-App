# M3 device test — v0.3.0 (spoken translations and earphone mode)

Run this on a real phone after v0.3.0 is published. Tick each box or write what you saw.
Spikes S5 (voices) and S2 (audio routing) from the design are sections 2 and 3.

Phone model: ____________ · Android version: ____ · Earbuds/headset model: ____________

**Who hears what.** A translation of the other person (**Listen**) is for you. It plays in your earphones, or on the phone
speaker when none are connected. A translation of your reply (**Speak**) is for them. It plays aloud on the phone speaker.
Each card says where it actually played (**Output: …**), because Android may route sound differently from the choice.

## 1. Update from 0.2.0

- [ ] 0.2.0 is installed.
- [ ] Opening the app shows **Update available · 0.3.0** with the What's new notes.
- [ ] **Update now** downloads, Android asks to install, and the app reopens on 0.3.0.
- [ ] A one-time **What's new in 0.3.0** sheet appears.
- [ ] Settings → About shows v0.3.0 (3).

## 2. Voices (S5)

Android's speech engine (Speech Services by Google) supplies the voices. For each language, start a conversation where the
translation is in that language and note what happens.

| Language | Voice: available / needs download / unsupported | Card shows | Install voice opens Android's voice screen | After installing, Replay speaks it |
|---|---|---|---|---|
| English | | | | |
| Hindi | | | | |
| Gujarati | | | | |

- [ ] When a voice is missing, the card says **No {language} voice on this phone, so this translation is text only.** and
      offers **Install voice**.
- [ ] After installing a voice and coming back to the app, **Replay translation** on the no-voice card speaks it, and
      the next translation in that language is spoken.
- [ ] If Speech Services by Google is disabled (Settings → Apps), cards show the no-voice line, not an error. After
      enabling it again, the next translation is spoken without restarting the app.
- [ ] The spoken words match the text on the card (no cut-off endings, numbers read sensibly).

## 3. Routing matrix (S2)

Open Settings → **Audio devices** (or the headphones button on the conversation screen). Leave the defaults:
**Translated voice · You** = Earphones, **Your reply · Other person** = Phone speaker.

For each setup, do one **Listen** turn and one **Speak** turn. Write the device you expected, the device the card shows
(**Output: …**), and where you actually heard it.

| Setup | Role | Expected | Card shows | Heard on | "Now:" line on Audio devices | Test output sound plays on / "Played on …" |
|---|---|---|---|---|---|---|
| Phone speaker only | You (Listen) | Phone speaker | | | | |
| Phone speaker only | Other person (Speak) | Phone speaker | | | | |
| Wired earphones | You (Listen) | Wired earphones | | | | |
| Wired earphones | Other person (Speak) | Phone speaker | | | | |
| Bluetooth earbuds | You (Listen) | Earbuds (by name) | | | | |
| Bluetooth earbuds | Other person (Speak) | Phone speaker | | | | |
| Neckband (if available) | You (Listen) | Neckband (by name) | | | | |
| Neckband (if available) | Other person (Speak) | Phone speaker | | | | |

- [ ] Device names are correct (Bluetooth devices show their own name, for example "Galaxy Buds"; wired shows
      **Wired earphones**).
- [ ] With no earphones, **Translated voice · You** says **No earphones connected, so this plays on the phone speaker.**
- [ ] Switching **Translated voice · You** to **Phone speaker** makes the next Listen translation play on the speaker,
      and the choice is still there after closing and reopening the app.
- [ ] Set **Your reply · Other person** to **Earphones**: replies play in the earphones, with no warning notice.
- [ ] If a reply could not go to the speaker, the notice **Couldn't use the phone speaker. Your reply played in {device}.**
      names the device it used. Note here if this happened: ______________________

## 4. Disconnect

- [ ] Between turns: with earbuds connected, turn them off (or unplug wired earphones). The notice
      **Earphones disconnected. Translations now play on the phone speaker.** appears, with a short tone on the speaker.
- [ ] The next Listen translation plays on the phone speaker, and its card says **Output: Phone speaker**.
- [ ] During playback: start a long Listen translation playing in the earbuds, then turn them off. The notice appears
      (no tone, so the translation isn't cut off), Android moves the rest of it to the phone speaker, and the card's
      **Output:** line changes to **Phone speaker**. Write what you heard: ______________
- [ ] Reconnect the earbuds: the next Listen translation goes back to them.

## 5. Talk over playback

- [ ] While a translation is playing (**Playing…** on the card), tap **Listen**. Playback stops at once and the
      microphone opens.
- [ ] The app does not translate its own voice: the new card shows only what the other person said.
- [ ] Same with **Speak** mid-playback.
- [ ] Press Home while your reply is still being translated (straight after Stop): nothing plays in the background.
- [ ] **Replay translation** on an older card plays it again, the list stays where it is, and its **Output:** line
      updates if the device changed.

## 6. Interruption

- [ ] A phone call arriving during playback stops the translation. After the call, nothing resumes by itself;
      **Replay translation** plays it again.
- [ ] An alarm or timer going off during playback stops the translation.
- [ ] Pressing Home during playback stops it.
- [ ] Leaving the conversation (Back) stops any playback.

## M3 is done when

On at least one phone with Bluetooth earbuds:

- [ ] the other person's translation plays in the earbuds;
- [ ] your reply plays on the speaker, or the card honestly names where it played;
- [ ] disconnecting falls back to the speaker with the notice;
- [ ] Listen stops playback.

Notes:
