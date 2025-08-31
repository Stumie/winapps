#!/usr/bin/env bash
# Copyright (c) 2024 kahkhang
# All rights reserved.
#
# SPDX-License-Identifier: MIT
# For original source, see https://github.com/kahkhang/Inquirer.sh

# Replaced original functions with 'dialog' by a 'kdialog' variant envisioned from ChatGPT and Google Gemini

### GLOBAL CONSTANTS ###
declare -r ANSI_LIGHT_BLUE="\033[1;94m" # Light blue text.
declare -r ANSI_LIGHT_GREEN="\033[92m"  # Light green text.
declare -r ANSI_CLEAR_TEXT="\033[0m"    # Default text.

### FUNCTIONS ###

function inqMenu() {
    # Named references for passing variables
    declare -n INPUT_OPTIONS_REF="$2"
    declare -n RETURN_STRING_REF="$3"
    declare DIALOG_TEXT="$1"

    # Prepare menu options (key1 label1 key2 label2 ...)
    local DIALOG_OPTIONS=()
    local i=1
    for OPTION in "${INPUT_OPTIONS_REF[@]}"; do
        local TRIMMED="$(echo "$OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')"
        DIALOG_OPTIONS+=("$i" "$TRIMMED")
        ((i++))
    done

    # Show menu
    local SELECTED_KEY
    # 2>&1 >/dev/tty redirects kdialog's output to be correctly captured in SELECTED_KEY
    SELECTED_KEY=$(kdialog --menu "$DIALOG_TEXT" "${DIALOG_OPTIONS[@]}" 2>&1 >/dev/tty)
    
    # Check if the dialog was cancelled (e.g., by pressing "Cancel")
    if [[ $? -ne 0 ]]; then
        echo "Dialog was cancelled." >&2
        return 1
    fi

    # Convert the selected index (1-based) to the actual option
    RETURN_STRING_REF="${INPUT_OPTIONS_REF[$((SELECTED_KEY - 1))]}"

    # Output
    echo -e "${ANSI_LIGHT_GREEN}Q) ${ANSI_CLEAR_TEXT}${ANSI_LIGHT_BLUE}${DIALOG_TEXT}${ANSI_CLEAR_TEXT} --> ${ANSI_LIGHT_GREEN}${RETURN_STRING_REF}${ANSI_CLEAR_TEXT}"
    return 0
}

function inqChkBx() {
    # Named references for passing variables
    declare -n INPUT_OPTIONS_REF="$2"
    declare -n RETURN_ARRAY_REF="$3"
    declare DIALOG_TEXT="$1"

    # Prepare checklist options (key1 label1 off key2 label2 off ...)
    local DIALOG_OPTIONS=()
    local i=1
    for OPTION in "${INPUT_OPTIONS_REF[@]}"; do
        local TRIMMED="$(echo "$OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')"
        DIALOG_OPTIONS+=("$i" "$TRIMMED" "off")
        ((i++))
    done

    # Show checklist
    local SELECTED_KEYS
    # 2>&1 >/dev/tty redirects kdialog's output to be correctly captured in SELECTED_KEYS
    SELECTED_KEYS=$(kdialog --checklist "$DIALOG_TEXT" "${DIALOG_OPTIONS[@]}" 2>&1 >/dev/
}