# Brand assets

Generated from the approved artwork in the Anuvaad spec v1.2 (`Anuvaad_Developer_Specification_v1.1.html`) by
`tool/brand/extract_spec_assets.dart`. Replace them with the approved high-resolution masters when available (design Q2).

| File | Source |
|---|---|
| `logo.png` | The complete approved logo, cropped from the approved splash artwork (900×1609 JPEG) at x 278, y 172, 342×305. The separately embedded logo image in the spec is cut off at the bottom, so it is not used. |
| `globe_light_interim.jpg` | Splash artwork crop x 0, y 610, 900×710: globe only, no wordmark, tagline, progress bar or caption. |
| `icon_full_interim.png` | Logo at width 720, centred on 1024×1024 filled with the logo's background colour `#FBFDFE` (median of its border pixels). |
| `icon_foreground_interim.png` | Logo at width 960, centred on transparent 1024×1024 (adaptive icon foreground; flutter_launcher_icons adds a 16% inset). |
| `splash_icon_interim.png` | Logo at width 560, centred on transparent 1152×1152 (Android 12+ splash icon). |

No dark-theme globe exists at usable resolution yet, so the dark splash shows no globe.
