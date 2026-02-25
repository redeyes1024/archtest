#!/usr/bin/env python3
"""Build searchable i3 keybind entries for rofi/yad helpers."""

from __future__ import annotations

import argparse
import glob
import os
import re
import shlex
from collections import OrderedDict
from dataclasses import dataclass

SET_RE = re.compile(r"^\s*set\s+(\$[A-Za-z0-9_]+)\s+(.+?)\s*$")
INCLUDE_RE = re.compile(r"^\s*include\s+(.+?)\s*$")
BIND_RE = re.compile(r"^\s*(bindsym|bindcode)\s+(.+?)\s*$")
VAR_RE = re.compile(r"\$[A-Za-z0-9_]+")

KEY_ALIASES = {
    "mod1": "ALT",
    "mod4": "SUPER",
    "control": "CTRL",
    "ctrl": "CTRL",
    "shift": "SHIFT",
    "return": "ENTER",
    "space": "SPACE",
    "escape": "ESC",
    "esc": "ESC",
    "print": "PRINT",
    "prior": "PAGEUP",
    "next": "PAGEDOWN",
    "left": "LEFT",
    "right": "RIGHT",
    "up": "UP",
    "down": "DOWN",
}

SCRIPT_LABELS = {
    "Brightness.sh": "Screen brightness control",
    "BrightnessKbd.sh": "Keyboard backlight control",
    "ClipManager.sh": "Clipboard manager",
    "DarkLight.sh": "Switch dark/light theme",
    "KeyboardLayout.sh": "Keyboard layout switcher",
    "KeyBinds.sh": "Search keybinds",
    "KeyHints.sh": "Open keybind cheat sheet",
    "Kitty_themes.sh": "Choose Kitty theme",
    "Kool_Quick_Settings.sh": "Open i3 quick settings menu",
    "MediaCtrl.sh": "Media playback controls",
    "MonitorProfiles.sh": "Choose monitor profile",
    "powermenu.sh": "Power menu",
    "Refresh.sh": "Refresh i3/polybar colors",
    "RofiThemeSelector.sh": "Choose Rofi theme",
    "ScreenShot.sh": "Screenshot workflow",
    "ThemeChanger.sh": "Choose global wallust theme",
    "TouchPad.sh": "Toggle touchpad",
    "Volume.sh": "Volume and mic controls",
    "WallustFeh.sh": "Apply wallpaper + wallust palette",
    "autostart.sh": "Run startup services",
    "lock.sh": "Lock screen",
}

SCRIPT_ARG_LABELS = {
    ("Brightness.sh", "--inc"): "Increase screen brightness",
    ("Brightness.sh", "--dec"): "Decrease screen brightness",
    ("BrightnessKbd.sh", "--inc"): "Increase keyboard backlight",
    ("BrightnessKbd.sh", "--dec"): "Decrease keyboard backlight",
    ("KeyboardLayout.sh", "switch"): "Switch keyboard layout",
    ("MonitorProfiles.sh", ""): "Choose monitor profile",
    ("ScreenShot.sh", "--now"): "Take full screenshot",
    ("ScreenShot.sh", "--area"): "Take area screenshot",
    ("ScreenShot.sh", "--in5"): "Take screenshot in 5s",
    ("ScreenShot.sh", "--in10"): "Take screenshot in 10s",
    ("ScreenShot.sh", "--active"): "Take active-window screenshot",
    ("TouchPad.sh", "toggle"): "Toggle touchpad",
    ("Volume.sh", "--inc"): "Increase volume",
    ("Volume.sh", "--dec"): "Decrease volume",
    ("Volume.sh", "--inc-precise"): "Increase volume (1%)",
    ("Volume.sh", "--dec-precise"): "Decrease volume (1%)",
    ("Volume.sh", "--toggle"): "Toggle output mute",
    ("Volume.sh", "--toggle-mic"): "Toggle microphone mute",
    ("MediaCtrl.sh", "--pause"): "Play / pause media",
    ("MediaCtrl.sh", "--nxt"): "Next media track",
    ("MediaCtrl.sh", "--prv"): "Previous media track",
    ("MediaCtrl.sh", "--stop"): "Stop media playback",
}


@dataclass
class Binding:
    combo: str
    description: str
    command: str
    norm_key: str


def strip_quotes(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def strip_inline_comment(line: str) -> tuple[str, str]:
    in_single = False
    in_double = False
    escaped = False
    for idx, char in enumerate(line):
        if escaped:
            escaped = False
            continue
        if char == "\\":
            escaped = True
            continue
        if char == "'" and not in_double:
            in_single = not in_single
            continue
        if char == '"' and not in_single:
            in_double = not in_double
            continue
        if char == "#" and not in_single and not in_double:
            return line[:idx].rstrip(), line[idx + 1 :].strip()
    return line.rstrip(), ""


def shorten_home(path_text: str) -> str:
    home = os.path.expanduser("~")
    if path_text.startswith(home):
        return "~" + path_text[len(home) :]
    return path_text


def substitute_vars(text: str, variables: dict[str, str], max_depth: int = 8) -> str:
    out = text
    for _ in range(max_depth):
        replaced = False

        def repl(match: re.Match[str]) -> str:
            nonlocal replaced
            name = match.group(0)
            if name in variables:
                replaced = True
                return variables[name]
            return name

        new_out = VAR_RE.sub(repl, out)
        out = new_out
        if not replaced:
            break
    return out


def humanize_combo_part(part: str) -> str:
    cleaned = part.strip()
    lowered = cleaned.lower()
    if lowered in KEY_ALIASES:
        return KEY_ALIASES[lowered]
    if lowered in {"shift_l", "shift_r"}:
        return "SHIFT"
    if lowered in {"control_l", "control_r"}:
        return "CTRL"
    if re.fullmatch(r"[a-z]", cleaned):
        return cleaned.upper()
    if cleaned.startswith("XF86"):
        return cleaned
    return cleaned


def humanize_combo(combo_raw: str, variables: dict[str, str], bind_type: str, options: list[str]) -> str:
    expanded = substitute_vars(combo_raw, variables)
    parts = [humanize_combo_part(part) for part in expanded.split("+") if part]
    combo = "+".join(parts) if parts else expanded

    if bind_type == "bindcode":
        combo = f"code:{combo}"

    labels = []
    if "--release" in options:
        labels.append("release")
    if "--locked" in options:
        labels.append("locked")

    for label in labels:
        combo += f" [{label}]"
    return combo


def describe_i3_action(command: str) -> str | None:
    command = command.strip()
    if command == "kill":
        return "Close focused window"
    if command == "restart":
        return "Restart i3"
    if command == "reload":
        return "Reload i3 config"
    if command == "fullscreen toggle":
        return "Toggle fullscreen"
    if command == "floating toggle":
        return "Toggle floating mode"
    if command.startswith("focus "):
        return "Focus " + command.split(" ", 1)[1]
    if command.startswith("move container to workspace "):
        return "Move container to workspace " + command.split(" ", 4)[4]
    if command.startswith("move "):
        return "Move container " + command.split(" ", 1)[1]
    if command.startswith("workspace "):
        return "Switch to workspace " + command.split(" ", 1)[1]
    if command.startswith("layout "):
        return "Set layout: " + command.split(" ", 1)[1]
    return None


def describe_external(exec_tokens: list[str]) -> str:
    if not exec_tokens:
        return "Run command"

    tool = exec_tokens[0]
    args = exec_tokens[1:]

    if tool in {"bash", "sh", "zsh"} and args:
        script_path = args[0]
        script_name = os.path.basename(script_path)
        script_args = args[1:]
    else:
        script_path = tool
        script_name = os.path.basename(tool)
        script_args = args

    if script_name in SCRIPT_LABELS:
        if script_args:
            label = SCRIPT_ARG_LABELS.get((script_name, script_args[0]))
            if label:
                return label
        generic = SCRIPT_ARG_LABELS.get((script_name, ""))
        if generic:
            return generic
        return SCRIPT_LABELS[script_name]

    if tool == "rofi":
        try:
            show_idx = args.index("-show")
            if show_idx + 1 < len(args):
                return f"Launch rofi ({args[show_idx + 1]})"
        except ValueError:
            pass
        return "Launch rofi"

    if tool == "i3-msg" and args:
        return "Send i3 command: " + " ".join(args)

    return "Run: " + shorten_home(" ".join(exec_tokens))


def describe_command(command: str) -> str:
    direct = describe_i3_action(command)
    if direct:
        return direct

    try:
        tokens = shlex.split(command, posix=True)
    except ValueError:
        return shorten_home(command)

    if not tokens:
        return "Run command"

    if tokens[0] == "exec":
        idx = 1
        while idx < len(tokens) and tokens[idx].startswith("--"):
            idx += 1
        return describe_external(tokens[idx:])

    return shorten_home(command)


def normalize_key(bind_type: str, combo_raw: str, options: list[str], variables: dict[str, str]) -> str:
    expanded = substitute_vars(combo_raw, variables).lower().replace(" ", "")
    release = "release" if "--release" in options else "press"
    locked = "locked" if "--locked" in options else "normal"
    return f"{bind_type}:{expanded}:{release}:{locked}"


def parse_bind_line(line: str, variables: dict[str, str]) -> Binding | None:
    uncommented, inline_comment = strip_inline_comment(line)
    match = BIND_RE.match(uncommented)
    if not match:
        return None

    bind_type = match.group(1)
    rest = match.group(2).strip()

    try:
        tokens = shlex.split(rest, posix=True)
    except ValueError:
        return None

    if len(tokens) < 2:
        return None

    idx = 0
    options: list[str] = []
    while idx < len(tokens) and tokens[idx].startswith("--"):
        options.append(tokens[idx])
        idx += 1

    if idx >= len(tokens) - 1:
        return None

    combo_raw = tokens[idx]
    command_raw = " ".join(tokens[idx + 1 :]).strip()
    if not command_raw:
        return None

    command = substitute_vars(command_raw, variables)
    combo = humanize_combo(combo_raw, variables, bind_type, options)
    description = inline_comment if inline_comment else describe_command(command)
    norm_key = normalize_key(bind_type, combo_raw, options, variables)
    return Binding(combo=combo, description=description, command=command, norm_key=norm_key)


def resolve_include_paths(include_expr: str, base_dir: str, variables: dict[str, str]) -> list[str]:
    try:
        patterns = shlex.split(include_expr, posix=True)
    except ValueError:
        patterns = [include_expr]

    paths: list[str] = []
    for pattern in patterns:
        candidate = substitute_vars(strip_quotes(pattern), variables)
        candidate = os.path.expanduser(candidate)
        if not os.path.isabs(candidate):
            candidate = os.path.join(base_dir, candidate)

        matches = sorted(glob.glob(candidate))
        if matches:
            paths.extend(path for path in matches if os.path.isfile(path))
        elif os.path.isfile(candidate):
            paths.append(candidate)
    return paths


def parse_config_file(
    config_path: str,
    variables: dict[str, str],
    visited: set[str],
    bindings: OrderedDict[str, Binding],
) -> None:
    expanded_path = os.path.expanduser(config_path)
    if not os.path.isfile(expanded_path):
        return

    real_path = os.path.realpath(expanded_path)
    if real_path in visited:
        return
    visited.add(real_path)

    base_dir = os.path.dirname(real_path)
    with open(real_path, "r", encoding="utf-8", errors="ignore") as handle:
        for raw_line in handle:
            stripped_line, _ = strip_inline_comment(raw_line)
            line = stripped_line.strip()
            if not line:
                continue

            set_match = SET_RE.match(line)
            if set_match:
                variables[set_match.group(1)] = substitute_vars(strip_quotes(set_match.group(2)), variables)
                continue

            include_match = INCLUDE_RE.match(line)
            if include_match:
                for nested_file in resolve_include_paths(include_match.group(1), base_dir, variables):
                    parse_config_file(nested_file, variables, visited, bindings)
                continue

            binding = parse_bind_line(raw_line, variables)
            if not binding:
                continue

            if binding.norm_key in bindings:
                del bindings[binding.norm_key]
            bindings[binding.norm_key] = binding


def main() -> int:
    parser = argparse.ArgumentParser(description="Parse i3 keybinds for helper menus.")
    parser.add_argument(
        "--format",
        choices=("rofi", "tsv"),
        default="rofi",
        help="Output format.",
    )
    parser.add_argument(
        "config_files",
        nargs="*",
        default=[os.path.expanduser("~/.config/i3/config")],
        help="i3 config files to parse.",
    )
    args = parser.parse_args()

    bindings: OrderedDict[str, Binding] = OrderedDict()
    variables: dict[str, str] = {}
    visited: set[str] = set()

    for file_path in args.config_files:
        parse_config_file(file_path, variables, visited, bindings)

    if not bindings:
        return 1

    for entry in bindings.values():
        description = re.sub(r"\s+", " ", entry.description.strip())
        command = shorten_home(entry.command)
        if args.format == "tsv":
            print(f"{entry.combo}\t{description}\t{command}")
        else:
            print(f"{entry.combo} - {description}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
