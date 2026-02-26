# Polybar Conversion Notes

This Polybar setup is a fuller i3/Xorg equivalent of the richer Waybar layout:

- `main` bar (bottom): launcher, system stats, workspaces, weather, battery, brightness, audio, mic, power profile, keyboard, night-light, power menu.
- `aux` bar (top): lock, idle inhibitor, media player, notifications, update counter, clock, theme toggle.

## Required Packages

Install these to get all modules working:

```bash
sudo pacman -S --needed polybar rofi playerctl pamixer pavucontrol brightnessctl lm_sensors curl dunst xorg-xset power-profiles-daemon upower
```

For Arch update counter support:

```bash
sudo pacman -S --needed pacman-contrib
```

## Optional Packages

- `gammastep` or `redshift` for the night-light toggle module.
- `networkmanager` + `nm-applet` (already used by i3 autostart in this repo).

## Module Scripts

Polybar helper scripts live in:

- `~/.config/polybar/scripts/`

They are called via `bash ...` in `config.ini`, so executable bits are not required.
