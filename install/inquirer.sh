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

    # Other variables:
    declare TRIMMED_OPTIONS=()
    declare DIALOG_OPTIONS=()
    declare DIALOG_WIDTH=0
    declare SELECTED_KEY=""

    # MAIN LOGIC.
    # Trim leading and trailing white space for each option.
    for OPTION in "${INPUT_OPTIONS[@]}"; do
        TRIMMED_OPTIONS+=("$(echo "$OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')")
    done

    # Prepare menu options (key1 label1 key2 label2 ...)
    local i=1
    for OPTION in "${TRIMMED_OPTIONS[@]}"; do
        DIALOG_OPTIONS+=("$i" "$OPTION")
        ((i++))
    done

    # Show menu and capture output
    SELECTED_KEY=$(kdialog --menu "$DIALOG_TEXT" "${DIALOG_OPTIONS[@]}" 2>&1 >/dev/tty)
    
    # Check if dialog was canceled
    if [[ $? -ne 0 ]]; then
        echo "Dialog was cancelled." >&2
        exit 0
    fi

    # Convert the selected key (1-based) to the actual option
    RETURN_STRING="${TRIMMED_OPTIONS[$((SELECTED_KEY - 1))]}"

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

    # Other variables:
    declare TRIMMED_OPTIONS=()
    declare PADDED_OPTIONS=()
    declare DIALOG_OPTIONS=()
    declare DIALOG_WIDTH=0
    declare SELECTED_KEYS_RAW=""
    declare FORMATTED_OUTPUT=""
    declare -a KEYS=()
    declare -a TEMP_RETURN_ARRAY=()

    # MAIN LOGIC.
    # Trim leading and trailing white space for each option.
    for OPTION in "${INPUT_OPTIONS[@]}"; do
        TRIMMED_OPTIONS+=("$(echo "$OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')")
    done

    # Find the length of the longest option to set the dialog width.
    for OPTION in "${TRIMMED_OPTIONS[@]}"; do
        if [ "${#OPTION}" -gt "$DIALOG_WIDTH" ]; then
            DIALOG_WIDTH=${#OPTION}
        fi
    done

    # Apply the offset value to the dialog width.
    DIALOG_WIDTH=$((DIALOG_WIDTH + CHK_OPTION_WIDTH_OFFSET))

    # Adjust the dialog width again if the dialog text is longer.
    if [ "$DIALOG_WIDTH" -lt $((${#DIALOG_TEXT} + TEXT_WIDTH_OFFSET)) ]; then
        DIALOG_WIDTH="$((${#DIALOG_TEXT} + TEXT_WIDTH_OFFSET))"
    fi

    # Pad option text with trailing white space to left-align all options.
    for OPTION in "${TRIMMED_OPTIONS[@]}"; do
        local PAD_LENGTH=$((DIALOG_WIDTH - CHK_OPTION_WIDTH_OFFSET - ${#OPTION}))
        local PADDED_OPTION="${OPTION}$(printf '%*s' $PAD_LENGTH)"
        PADDED_OPTIONS+=("$PADDED_OPTION")
    done

    # Convert options into the appropriate format for a 'kdialog' checkbox.
    local i=1
    for PADDED_OPTION in "${PADDED_OPTIONS[@]}"; do
        DIALOG_OPTIONS+=("$i" "$PADDED_OPTION" "off")
        ((i++))
    done

    # Show checklist and capture the raw output.
    SELECTED_KEYS_RAW=$(kdialog --checklist "$DIALOG_TEXT" "${DIALOG_OPTIONS[@]}" 2>&1 >/dev/tty)
    
    # Check if dialog was canceled or no selection was made.
    if [[ $? -ne 0 || -z "$SELECTED_KEYS_RAW" ]]; then
        echo "Dialog was cancelled or no option was selected." >&2
        exit 0
    fi

    # Convert the raw output string from kdialog into an array of keys.
    IFS=" " read -r -a KEYS <<< "$SELECTED_KEYS_RAW"

    # Build the formatted output string to match the original dialog format.
    for KEY in "${KEYS[@]}"; do
        local ORIGINAL_OPTION="${TRIMMED_OPTIONS[$((KEY - 1))]}"
        FORMATTED_OUTPUT+="\"$ORIGINAL_OPTION\" "
    done
    
    # Remove the last trailing space.
    FORMATTED_OUTPUT="${FORMATTED_OUTPUT% }"

    # Process the formatted output string into the return array, just like the original script.
    while IFS= read -r LINE; do
        LINE="${LINE/#\"/}"
        LINE="${LINE/%\"/}"
        TEMP_RETURN_ARRAY+=("$LINE")
    done < <(echo "$FORMATTED_OUTPUT" | sed 's/\" \"/\"\n\"/g')

    # Final modifications on the temporary array.
    for ((i = 0; i < ${#TEMP_RETURN_ARRAY[@]}; i++)); do
        TEMP_RETURN_ARRAY[i]=$(echo "${TEMP_RETURN_ARRAY[i]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        TEMP_RETURN_ARRAY[i]=${TEMP_RETURN_ARRAY[i]//\\/}
    done

    # Assign the final array to the return variable.
    RETURN_ARRAY=("${TEMP_RETURN_ARRAY[@]}")

    # Display question and response.
    echo -e "${ANSI_LIGHT_GREEN}Q) ${ANSI_CLEAR_TEXT}${ANSI_LIGHT_BLUE}${DIALOG_TEXT}${ANSI_CLEAR_TEXT} --> ${ANSI_LIGHT_GREEN}${FORMATTED_OUTPUT}${ANSI_CLEAR_TEXT}"
    return 0
}