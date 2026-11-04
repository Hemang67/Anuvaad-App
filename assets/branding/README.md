# Interim brand assets

Interim assets extracted from Anuvaad spec v1.2 (`Anuvaad_Developer_Specification_v1.1.html`) by
`tool/brand/extract_spec_assets.dart`. Replace them with the approved high-resolution masters (design Q2).

| File | Source |
|---|---|
| `logo_interim.png` | Embedded "Approved Anuvaad logo" (372×320 PNG), bytes unchanged. Note: the spec image is cropped at the bottom. |
| `globe_light_interim.jpg` | Approved splash artwork (900×1609 JPEG), crop x 0, y 610, width 900, height 710: globe only, no wordmark, tagline, progress bar or caption. |
| `icon_full_interim.png` | Logo at width 720, centred on 1024×1024 filled with the logo's background colour `#FCFCFE` (median of its border pixels). |
| `icon_foreground_interim.png` | Logo at width 960, centred on transparent 1024×1024 (adaptive icon foreground; flutter_launcher_icons adds a 16% inset). |
| `splash_icon_interim.png` | Logo at width 560, centred on transparent 1152×1152 (Android 12+ splash icon). |

No dark-theme globe exists at usable resolution yet, so the dark splash shows no globe.
