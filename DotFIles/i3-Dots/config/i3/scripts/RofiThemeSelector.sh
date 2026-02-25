#!/usr/bin/env bash
# Rofi theme selector with preview and apply workflow.

ROFI_THEMES_DIR_CONFIG="$HOME/.config/rofi/themes"
ROFI_THEMES_DIR_LOCAL="$HOME/.local/share/rofi/themes"
ROFI_CONFIG_FILE="$HOME/.config/rofi/config.rasi"
ROFI_THEME_FOR_THIS_SCRIPT="$HOME/.config/rofi/config-rofi-theme.rasi"
IDIR="$HOME/.config/swaync/images"

notify_user() {
    notify-send -u low -i "$1" "$2" "$3"
}

restore_original_config() {
    printf "%s" "$original_rofi_config_content_backup" >"$ROFI_CONFIG_FILE"
}

apply_rofi_theme_to_config() {
    local theme_name_to_apply="$1"
    local theme_path=""
    local theme_path_with_tilde
    local temp_rofi_config_file

    if [[ -f "$ROFI_THEMES_DIR_CONFIG/$theme_name_to_apply" ]]; then
        theme_path="$ROFI_THEMES_DIR_CONFIG/$theme_name_to_apply"
    elif [[ -f "$ROFI_THEMES_DIR_LOCAL/$theme_name_to_apply" ]]; then
        theme_path="$ROFI_THEMES_DIR_LOCAL/$theme_name_to_apply"
    else
        notify_user "$IDIR/error.png" "Error" "Theme file not found: $theme_name_to_apply"
        return 1
    fi

    theme_path_with_tilde="~${theme_path#$HOME}"
    temp_rofi_config_file=$(mktemp)

    awk -v theme="$theme_path_with_tilde" '
        /^\s*\/\/\s*@theme/ { next }
        /^\s*@theme\s*"/ { next }
        { print }
        END { print "@theme \"" theme "\"" }
    ' "$ROFI_CONFIG_FILE" >"$temp_rofi_config_file" || return 1

    mv "$temp_rofi_config_file" "$ROFI_CONFIG_FILE"
    return 0
}

if [[ ! -d "$ROFI_THEMES_DIR_CONFIG" && ! -d "$ROFI_THEMES_DIR_LOCAL" ]]; then
    notify_user "$IDIR/error.png" "Error" "No Rofi themes directory found."
    exit 1
fi

if [[ ! -f "$ROFI_CONFIG_FILE" ]]; then
    notify_user "$IDIR/error.png" "Error" "Rofi config file not found: $ROFI_CONFIG_FILE"
    exit 1
fi

if [[ ! -f "$ROFI_THEME_FOR_THIS_SCRIPT" ]]; then
    ROFI_THEME_FOR_THIS_SCRIPT="$ROFI_CONFIG_FILE"
fi

original_rofi_config_content_backup=$(cat "$ROFI_CONFIG_FILE")

mapfile -t available_theme_names < <((
    [[ -d "$ROFI_THEMES_DIR_CONFIG" ]] && find "$ROFI_THEMES_DIR_CONFIG" -maxdepth 1 -name "*.rasi" -type f -printf "%f\n"
    [[ -d "$ROFI_THEMES_DIR_LOCAL" ]] && find "$ROFI_THEMES_DIR_LOCAL" -maxdepth 1 -name "*.rasi" -type f -printf "%f\n"
) | sort -V -u)

if [[ ${#available_theme_names[@]} -eq 0 ]]; then
    notify_user "$IDIR/error.png" "No Rofi Themes" "No .rasi files found in theme directories."
    exit 1
fi

current_selection_index=0
current_active_theme_path=$(awk -F'"' '/^[[:space:]]*@theme[[:space:]]*"/ { theme=$2 } END { print theme }' "$ROFI_CONFIG_FILE")
if [[ -n "$current_active_theme_path" ]]; then
    current_active_theme_name=$(basename "$current_active_theme_path")
    for i in "${!available_theme_names[@]}"; do
        if [[ "${available_theme_names[$i]}" == "$current_active_theme_name" ]]; then
            current_selection_index=$i
            break
        fi
    done
fi

while true; do
    theme_to_preview_now="${available_theme_names[$current_selection_index]}"

    if ! apply_rofi_theme_to_config "$theme_to_preview_now"; then
        restore_original_config
        notify_user "$IDIR/error.png" "Preview Error" "Failed to apply $theme_to_preview_now."
        exit 1
    fi

    rofi_input_list=""
    for theme_name_in_list in "${available_theme_names[@]}"; do
        rofi_input_list+="$(basename "$theme_name_in_list" .rasi)\n"
    done
    rofi_input_list_trimmed="${rofi_input_list%\\n}"

    chosen_index_from_rofi=$(echo -e "$rofi_input_list_trimmed" |
        rofi -dmenu -i \
            -format "i" \
            -p "Rofi Theme" \
            -mesg "Enter: Preview | Ctrl+S: Apply and Exit | Esc: Cancel" \
            -config "$ROFI_THEME_FOR_THIS_SCRIPT" \
            -selected-row "$current_selection_index" \
            -kb-custom-1 "Control+s")
    rofi_exit_code=$?

    if [[ $rofi_exit_code -eq 0 ]]; then
        if [[ "$chosen_index_from_rofi" =~ ^[0-9]+$ ]] && [[ "$chosen_index_from_rofi" -lt "${#available_theme_names[@]}" ]]; then
            current_selection_index="$chosen_index_from_rofi"
        fi
    elif [[ $rofi_exit_code -eq 1 ]]; then
        restore_original_config
        notify_user "$IDIR/note.png" "Rofi Theme" "Selection cancelled. Restored previous theme."
        break
    elif [[ $rofi_exit_code -eq 10 ]]; then
        notify_user "$IDIR/ja.png" "Rofi Theme Applied" "$(basename "$theme_to_preview_now" .rasi)"
        break
    else
        restore_original_config
        notify_user "$IDIR/error.png" "Rofi Error" "Unexpected Rofi exit ($rofi_exit_code)."
        break
    fi
done

exit 0
