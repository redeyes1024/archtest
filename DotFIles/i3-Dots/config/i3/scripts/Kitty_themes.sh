#!/usr/bin/env bash
# Kitty theme selector with preview and apply workflow.

kitty_themes_dir="$HOME/.config/kitty/kitty-themes"
kitty_config="$HOME/.config/kitty/kitty.conf"
iDIR="$HOME/.config/swaync/images"
rofi_theme_for_this_script="$HOME/.config/rofi/config-kitty-theme.rasi"
default_rofi_config="$HOME/.config/rofi/config.rasi"

notify_user() {
    notify-send -u low -i "$1" "$2" "$3"
}

reload_running_kitty() {
    if pidof kitty >/dev/null 2>&1; then
        for pid_kitty in $(pidof kitty); do
            [[ -n "$pid_kitty" ]] && kill -SIGUSR1 "$pid_kitty"
        done
    fi
}

restore_original_kitty_config() {
    printf "%s" "$original_kitty_config_content_backup" >"$kitty_config"
    reload_running_kitty
}

apply_kitty_theme_to_config() {
    local theme_name_to_apply="$1"
    local apply_mode="${2:-preview}"
    local theme_file_path_to_apply
    local include_target
    local temp_kitty_config_file

    if [[ -z "$theme_name_to_apply" ]]; then
        echo "Error: no theme name provided." >&2
        return 1
    fi

    if [[ "$theme_name_to_apply" == "Set by wallpaper" ]]; then
        theme_file_path_to_apply="$kitty_themes_dir/00-Default.conf"
    else
        theme_file_path_to_apply="$kitty_themes_dir/$theme_name_to_apply.conf"
    fi

    if [[ ! -f "$theme_file_path_to_apply" ]]; then
        notify_user "$iDIR/error.png" "Error" "Theme file not found: $(basename "$theme_file_path_to_apply")"
        return 1
    fi

    temp_kitty_config_file=$(mktemp)
    cp "$kitty_config" "$temp_kitty_config_file"

    include_target="include ./kitty-themes/$(basename "$theme_file_path_to_apply")"
    if grep -q -E '^[#[:space:]]*include\s+\./kitty-themes/.*\.conf' "$temp_kitty_config_file"; then
        sed -i -E "s|^([#[:space:]]*include\s+\./kitty-themes/).*\.conf|$include_target|g" "$temp_kitty_config_file"
    else
        if [[ -s "$temp_kitty_config_file" ]]; then
            printf "\n" >>"$temp_kitty_config_file"
        fi
        echo "$include_target" >>"$temp_kitty_config_file"
    fi

    mv "$temp_kitty_config_file" "$kitty_config"

    if pidof kitty >/dev/null 2>&1; then
        if [[ "$apply_mode" == "apply" ]] && command -v kitty >/dev/null 2>&1; then
            kitty @ load-config >/dev/null 2>&1
            kitty @ set-colors --all --configured "$theme_file_path_to_apply" >/dev/null 2>&1
        fi
        reload_running_kitty
    fi

    return 0
}

if [[ ! -d "$kitty_themes_dir" ]]; then
    notify_user "$iDIR/error.png" "Error" "Kitty themes directory not found: $kitty_themes_dir"
    exit 1
fi

if [[ ! -f "$kitty_config" ]]; then
    notify_user "$iDIR/error.png" "Error" "Kitty config file not found: $kitty_config"
    exit 1
fi

if [[ ! -f "$rofi_theme_for_this_script" ]]; then
    rofi_theme_for_this_script="$default_rofi_config"
fi

if [[ ! -f "$rofi_theme_for_this_script" ]]; then
    notify_user "$iDIR/error.png" "Error" "Rofi config not found for Kitty selector."
    exit 1
fi

original_kitty_config_content_backup=$(cat "$kitty_config")

mapfile -t available_theme_names < <(
    find "$kitty_themes_dir" -maxdepth 1 -name "*.conf" -type f -printf "%f\n" |
        sed 's/\.conf$//' |
        grep -v -E '^(00-Default|01-Wallust)$' |
        sort
)
available_theme_names=("Set by wallpaper" "${available_theme_names[@]}")

if [[ ${#available_theme_names[@]} -eq 0 ]]; then
    notify_user "$iDIR/error.png" "No Kitty Themes" "No theme files found in $kitty_themes_dir."
    exit 1
fi

current_selection_index=0
current_active_theme_name=$(awk -F'include ./kitty-themes/|\\.conf' '/^[[:space:]]*include \\.\/kitty-themes\/.*\\.conf/ { print $2; exit }' "$kitty_config")
if [[ "$current_active_theme_name" == "00-Default" ]]; then
    current_active_theme_name="Set by wallpaper"
fi

if [[ -n "$current_active_theme_name" ]]; then
    for i in "${!available_theme_names[@]}"; do
        if [[ "${available_theme_names[$i]}" == "$current_active_theme_name" ]]; then
            current_selection_index=$i
            break
        fi
    done
fi

while true; do
    theme_to_preview_now="${available_theme_names[$current_selection_index]}"

    rofi_input_list=""
    for theme_name_in_list in "${available_theme_names[@]}"; do
        rofi_input_list+="$theme_name_in_list\n"
    done
    rofi_input_list_trimmed="${rofi_input_list%\\n}"

    chosen_index_from_rofi=$(echo -e "$rofi_input_list_trimmed" |
        rofi -dmenu -i \
            -format "i" \
            -p "Kitty Theme" \
            -mesg "Enter: Preview | Ctrl+S: Apply and Exit | Esc: Cancel" \
            -config "$rofi_theme_for_this_script" \
            -selected-row "$current_selection_index" \
            -kb-custom-1 "Control+s")
    rofi_exit_code=$?

    if [[ $rofi_exit_code -eq 0 ]]; then
        if [[ "$chosen_index_from_rofi" =~ ^[0-9]+$ ]] && [[ "$chosen_index_from_rofi" -lt "${#available_theme_names[@]}" ]]; then
            current_selection_index="$chosen_index_from_rofi"
            theme_to_preview_now="${available_theme_names[$current_selection_index]}"
            if ! apply_kitty_theme_to_config "$theme_to_preview_now" "preview"; then
                restore_original_kitty_config
                notify_user "$iDIR/error.png" "Preview Error" "Failed to apply $theme_to_preview_now."
                exit 1
            fi
        fi
    elif [[ $rofi_exit_code -eq 1 ]]; then
        restore_original_kitty_config
        notify_user "$iDIR/note.png" "Kitty Theme" "Selection cancelled. Restored previous theme."
        break
    elif [[ $rofi_exit_code -eq 10 ]]; then
        if apply_kitty_theme_to_config "$theme_to_preview_now" "apply"; then
            notify_user "$iDIR/ja.png" "Kitty Theme Applied" "$theme_to_preview_now"
        fi
        break
    else
        restore_original_kitty_config
        notify_user "$iDIR/error.png" "Rofi Error" "Unexpected Rofi exit ($rofi_exit_code)."
        break
    fi
done

exit 0
