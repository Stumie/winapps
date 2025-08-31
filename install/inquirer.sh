#!/usr/bin/env bash
# Copyright (c) 2024 kahkhang
# All rights reserved.
#
# SPDX-License-Identifier: MIT
# For original source, see https://github.com/kahkhang/Inquirer.sh

# Replaces original functions with 'dialog' by a 'kdialog' variant.

### GLOBAL CONSTANTS ###
declare -r ANSI_LIGHT_BLUE="\033[1;94m" # Light blue text.
declare -r ANSI_LIGHT_GREEN="\033[92m"  # Light green text.
declare -r ANSI_CLEAR_TEXT="\033[0m"    # Default text.
declare -r DIALOG_HEIGHT=14             # Height of dialog window.
declare -r TEXT_WIDTH_OFFSET=4          # Offset for fitting title text.
declare -r CHK_OPTION_WIDTH_OFFSET=10   # Offset for fitting options.
declare -r MNU_OPTION_WIDTH_OFFSET=7    # Offset for fitting options.

### FUNCTIONS ###
function inqMenu() {
    # DECLARE VARIABLES.
    declare DIALOG_TEXT="$1"
    declare INPUT_OPTIONS_VAR="$2"
    declare RETURN_STRING_VAR="$3"
    declare -n INPUT_OPTIONS="$INPUT_OPTIONS_VAR"
    declare -n RETURN_STRING="$RETURN_STRING_VAR"

    # Prepare menu options (key1 label1 key2 label2 ...)
    declare DIALOG_OPTIONS=()
    local i=1
    for OPTION in "${INPUT_OPTIONS[@]}"; do
        local TRIMMED="$(echo "$OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')"
        DIALOG_OPTIONS+=("$i" "$TRIMMED")
        ((i++))
    done

    # Show menu and capture output
    local SELECTED_KEY
    SELECTED_KEY=$(kdialog --menu "$DIALOG_TEXT" "${DIALOG_OPTIONS[@]}" 2>&1 >/dev/tty)
    
    # Check if dialog was canceled
    if [[ $? -ne 0 ]]; then
        echo "Dialog was cancelled." >&2
        return 1
    fi

    # Convert the selected key (1-based) to the actual option
    RETURN_STRING="${INPUT_OPTIONS[$((SELECTED_KEY - 1))]}"

    # Output to match original format
    echo -e "${ANSI_LIGHT_GREEN}Q) ${ANSI_CLEAR_TEXT}${ANSI_LIGHT_BLUE}${DIALOG_TEXT}${ANSI_CLEAR_TEXT} --> ${ANSI_LIGHT_GREEN}${RETURN_STRING}${ANSI_CLEAR_TEXT}"
    return 0
}

function inqChkBx() {
    # DECLARE VARIABLES.
    declare DIALOG_TEXT="$1"
    declare INPUT_OPTIONS_VAR="$2"
    declare RETURN_ARRAY_VAR="$3"
    declare -n INPUT_OPTIONS="$INPUT_OPTIONS_VAR"
    declare -n RETURN_ARRAY="$RETURN_ARRAY_VAR"

    # Prepare checklist options (key1 label1 off key2 label2 off ...)
    declare DIALOG_OPTIONS=()
    local i=1
    for OPTION in "${INPUT_OPTIONS[@]}"; do
        local TRIMMED="$(echo "$OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')"
        DIALOG_OPTIONS+=("$i" "$TRIMMED" "off")
        ((i++))
    done

    # Show checklist
    local SELECTED_KEYS
    SELECTED_KEYS=$(kdialog --checklist "$DIALOG_TEXT" "${DIALOG_OPTIONS[@]}" 2>&1 >/dev/tty)
    
    # Check if dialog was canceled
    if [[ $? -ne 0 ]]; then
        echo "Dialog was cancelled." >&2
        return 1
    fi

    # Convert the output string into a temporary array based on the keys
    local -a TEMP_RETURN_ARRAY=()
    local -a KEYS
    IFS=" " read -r -a KEYS <<< "$SELECTED_KEYS"
    
    # Replicate the original output format
    local FORMATTED_OUTPUT=""
    for KEY in "${KEYS[@]}"; do
        local ORIGINAL_OPTION="${INPUT_OPTIONS[$((KEY - 1))]}"
        
        # Remove original leading/trailing whitespace
        local TRIMMED_OPTION="$(echo "$ORIGINAL_OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')"
        
        # Add to temporary array
        TEMP_RETURN_ARRAY+=("$TRIMMED_OPTION")
        
        # Build the final formatted output string with quotes and a space
        FORMATTED_OUTPUT+="\"$TRIMMED_OPTION\" "
    done

    # Assign the temporary array to the return variable
    RETURN_ARRAY=("${TEMP_RETURN_ARRAY[@]}")

    # Display question and response, matching the original format
    echo -e "${ANSI_LIGHT_GREEN}Q) ${ANSI_CLEAR_TEXT}${ANSI_LIGHT_BLUE}${DIALOG_TEXT}${ANSI_CLEAR_TEXT} --> ${ANSI_LIGHT_GREEN}${FORMATTED_OUTPUT% }${ANSI_CLEAR_TEXT}"
    return 0
}