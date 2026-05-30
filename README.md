# SGLite

**Lightweight SG Pinyin optimizer — removes bloatware, keeps IME core only.**

> ⚠️ **Disclaimer**: This software is provided "AS IS" without warranty. Use at your own risk. See [LICENSE](LICENSE) for details.

## GitHub Repository

🔗 **https://github.com/dmtang-jpg/SGLite**

## What it does

SG Pinyin ships with **30+ unnecessary components** that consume memory, show ads, and collect data. SGLite disables them while keeping the core input method functional.

| Category | Removed | Impact |
|----------|---------|--------|
| **Extra Programs** | 16 exe files (ads, updater, cloud sync, etc.) | -140MB RAM |
| **Extra Plugins** | 14 plugin directories (skins, games, themes, etc.) | Cleaner UI |
| **Bundled Software** | PDF tools, compression tools, photo viewer | No more bloat |

## Features

- ✅ **One-click cleanup** — single command removes all bloatware
- ✅ **Auto-detect version** — works across SG Pinyin updates
- ✅ **Fully reversible** — all changes can be undone via Restore options
- ✅ **Admin check** — prompts for elevation when needed
- ✅ **Safe operations** — renames files (.disabled) instead of deleting
- ✅ **Interactive menu** — easy-to-use colored interface

## Quick Start

### Method 1: Double-click
1. Download and extract the ZIP
2. Double-click `SGLite.bat`
3. Accept the disclaimer
4. Select option `1` for full cleanup
5. Reboot your PC

### Method 2: PowerShell (Advanced)
```powershell
# Run as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
.\SGLite.ps1
```

## Menu Options

```
  [Menu]

    1. Full Cleanup (Recommended)
    2. Stop extra processes only
    3. Disable extra programs only
    4. Disable extra plugins only
    5. Clean bundled software only
    ---
    6. Restore all programs
    7. Restore all plugins
    0. Exit
```

## What gets removed

### Programs (16 exe files)
| File | Purpose |
|------|---------|
| `SGTool.exe` | Toolbox / ad popups |
| `SGDownload.exe` | Download manager |
| `SGWangzai.exe` | AI assistant |
| `SGWebRender.exe` | Web renderer |
| `SGWizard.exe` | Setup wizard |
| `SGKaomoji.exe` | Emoji tool |
| `SGIGuideHelper.exe` | Guide helper |
| `SogouCloud.exe` | Cloud sync |
| `SGSmartAssistant.exe` | Smart assistant |
| `screencapture.exe` | Screen capture |
| `sgfeedbackhelper.exe` | Feedback tool |
| `userNetSchedule.exe` | Network scheduler |
| `PinyinUp.exe` | Auto-updater |
| `SGBizLauncher.exe` | Business launcher |
| `SogouToolkits.exe` | Toolkits |
| `crashrpt.exe` | Crash reporter |

> Note: `SogouCloud.exe` and `SogouToolkits.exe` are actual file names on disk.

### Plugins (14 directories)
`AppBox`, `IChat`, `PicFace`, `SGDeskControl`, `SkinBox`, `SogouFlash`, `Theme`, `VoiceInput`, `WriteSpirit`, `biz_center`, `biz_pdf`, `game_center`, `isgpet`, `systembeautify`

### Bundled Software
`fastpdf_sogou`, `kdiskmgr_sogou`, `kfastpic_sogou`, `kzip_sogou`, `sogoupdf`, `sogousdk`

> Note: Above names are actual directory names on disk.

## How it works

SGLite uses **file renaming** (`.exe` → `.exe.disabled`) rather than deletion:

1. Terminates running bloatware processes
2. Renames unnecessary `.exe` files with `.disabled` suffix
3. Renames plugin directories with `.disabled` suffix
4. Deletes bundled software from AppData

This approach is **safe and reversible** — you can restore everything via menu options 6/7.

## Requirements

- Windows 10/11
- SG Pinyin installed (auto-detected)
- Administrator privileges (auto-elevated)

## FAQ

**Q: Will this break my input method?**
A: No. Only the IME core (`SogouImeBroker.exe`) is preserved. All other components are non-essential.

**Q: Can I undo the changes?**
A: Yes. Run the tool again and select options 6 (Restore programs) and 7 (Restore plugins).

**Q: Will updates undo the changes?**
A: Possibly. Re-run SGLite after input method updates.

**Q: Is this legal?**
A: This tool modifies files on your own computer. It does not crack, pirate, or redistribute any software. See [Legal Notice](#legal-notice).

## Legal Notice

This project is not affiliated with, endorsed by, or connected to any input method software vendor.

This tool is provided for educational and personal use only.

## License

MIT License — see [LICENSE](LICENSE) file.

## Contributing

Contributions are welcome! Please open an issue first to discuss changes.

## Changelog

### v1.0.0 (2025-05-29)
- Initial release
- One-click cleanup
- Auto version detection
- Admin privilege handling
- Full restore capability
