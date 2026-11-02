<p align="center">
  <img src="icon/AppIcon.png" width="128" alt="Claude Usage Bar icon">
</p>

<h1 align="center">Claude Usage Bar</h1>

<p align="center">
  A tiny native macOS menu bar widget that shows your Claude plan usage at a glance.<br>
  <b>✳ S 9%  W 2%</b> — current session and weekly limit, right next to the clock.
</p>

---

## Features

- **Session usage** (5-hour window) and **weekly limit** in percent, directly in the menu bar
- **Reset times** in the dropdown, e.g. `Reset um 15:00 (in 1 h 12 min)` or `Reset Sa. 07.11. um 23:00 (in 5 T 10 h)`
- **Color warnings**: orange from 70 %, red from 90 %
- Refreshes every 5 minutes and when you open the menu (at most once per minute)
- Adapts to light and dark menu bars (template icon)
- Pure Swift + AppKit, no dependencies, no Dock icon, ~200 KB

## Requirements

- macOS 13 or later
- Xcode Command Line Tools (`xcode-select --install`)
- [Claude Code](https://claude.com/claude-code) logged in with a Claude subscription (Pro/Max/Team)

## How it works

The widget reads the OAuth token that Claude Code stores in the macOS Keychain
(`Claude Code-credentials`) and asks `https://api.anthropic.com/api/oauth/usage` for the
current utilization — the same data Claude Code's `/usage` shows. The token never leaves
your machine except in that request to Anthropic.

If the token has expired, the menu bar shows `⚠︎`; start Claude Code once to refresh it.

## Install

```sh
git clone git@github.com:mihneacojocaru/CaludeUsageBar.git
cd CaludeUsageBar
./build.sh
```

`build.sh` compiles the app, generates the icon, ad-hoc signs it, installs it to
`~/Applications/ClaudeUsageBar.app` and (re)starts it.

### Start at login

```sh
osascript -e 'tell application "System Events" to make login item at end with properties {path:"'$HOME'/Applications/ClaudeUsageBar.app", hidden:true}'
```

Or add it under **System Settings › General › Login Items**.

## Project layout

| File | Purpose |
| --- | --- |
| `main.swift` | Menu bar app: fetches usage, renders title and menu |
| `Starburst.swift` | Draws the starburst glyph (menu bar + app icon) |
| `icon/main.swift` | Generates the `.iconset` for the app icon |
| `build.sh` | Build, sign, install and launch |

## Disclaimer

Unofficial tool, not affiliated with Anthropic. It uses an undocumented endpoint that may
change at any time.
