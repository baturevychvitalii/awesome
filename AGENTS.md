# AGENTS.md

AwesomeWM configuration for Arch Linux. Written in Lua. Manages the window manager, custom wibar widgets, keybindings, window placement rules, and startup applications.

## Design

- **Widget pattern**: each module exports `init(theme)` → produces `module.widget` and optionally `module.keys`; keys are merged into the global keymap in `rc.lua`
- **Multi-monitor**: `myutils.preferred_screen()` used in window rules to gracefully target screens with a fallback
- **External script dependencies**: hardware control scripts (volume, brightness, screenshot, bluetooth) live in `/opt/scripts`, not here
- **Theme coupling**: widget modules receive the theme object from `rc.lua`; colors and sizing are centralised in `theme.lua`

## Navigation

| Where | What |
|---|---|
| `rc.lua` | Main entry point — tags, wibar layout, keybindings, window rules, signals |
| `theme.lua` | Colors, fonts, wallpaper, widget-specific color vars, DPI sizing |
| `autorun.sh` | Startup script — launches background apps at WM start |
| `battery.lua` | Wibar widget — battery level and low-battery notifications |
| `volume.lua` | Wibar widget — audio volume bar and media keybindings |
| `brightness.lua` | Wibar widget — screen brightness bar and keybindings |
| `keyboard.lua` | Wibar widget — per-client keyboard layout switching |
| `myutils.lua` | Utility helpers — screen targeting with fallback |
| `keyboard_layouts/` | Flag icons consumed by `keyboard.lua` |
