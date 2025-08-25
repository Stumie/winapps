#!/usr/bin/env bash
# Copyright (c) 2024 kahkhang
# All rights reserved.
#
# SPDX-License-Identifier: MIT
# For original source, see https://github.com/kahkhang/Inquirer.sh

# Replaced original functions with 'dialog' by a 'kdialog' variant envisioned from Google Gemini 2.5 Flash.

### GLOBAL CONSTANTS ###
declare -r ANSI_LIGHT_BLUE="\033[1;94m" # Light blue text.
declare -r ANSI_LIGHT_GREEN="\033[92m"  # Light green text.
declare -r ANSI_CLEAR_TEXT="\033[0m"    # Default text.

### FUNCTIONS ###
function inqMenu() {
    # DECLARE VARIABLES.
    # Variables created from function arguments:
    declare DIALOG_TEXT="$1"                      # Dialog heading.
    declare INPUT_OPTIONS_VAR="$2"                # Input variable name.
    declare RETURN_STRING_VAR="$3"                # Output variable name.
    declare -n INPUT_OPTIONS="$INPUT_OPTIONS_VAR" # Input array nameref.
    declare -n RETURN_STRING="$RETURN_STRING_VAR" # Output string nameref.

    # Other variables:
    declare DIALOG_OPTIONS=()          # Input array for options dialog.
    declare SELECTED_OPTIONS_STRING="" # Output value from kdialog.

    # MAIN LOGIC.
    # The original script prepares padded options for `dialog`.
    # kdialog doesn't need this, so we can directly use the trimmed options.
    for OPTION in "${INPUT_OPTIONS[@]}"; do
        TRIMMED_OPTIONS+=("$(echo "$OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')")
    done
    
    # kdialog expects a list of options, typically as separate arguments.
    # The --menu option takes a text label and then a list of items.
    # We will use the --radiolist option which is a better match for a single-choice menu.
    for OPTION in "${TRIMMED_OPTIONS[@]}"; do
        DIALOG_OPTIONS+=("" "$OPTION" off)
    done

    # Produce menu dialog using kdialog.
    # The output is captured from stdout.
    SELECTED_OPTIONS_STRING=$(kdialog \
        --title "Selection" \
        --radiolist "$DIALOG_TEXT" \
        "${DIALOG_OPTIONS[@]}" \
        2>&1)

    # If the user cancelled, exit.
    if [ $? -ne 0 ]; then
        exit 0
    fi

    # Set the return variable.
    RETURN_STRING="$SELECTED_OPTIONS_STRING"
    
    # Display question and response.
    echo -e "${ANSI_LIGHT_GREEN}Q) ${ANSI_CLEAR_TEXT}${ANSI_LIGHT_BLUE}${DIALOG_TEXT}${ANSI_CLEAR_TEXT} --> ${ANSI_LIGHT_GREEN}${RETURN_STRING}${ANSI_CLEAR_TEXT}"
}

function inqChkBx() {
    # DECLARE VARIABLES.
    # Variables created from function arguments:
    declare DIALOG_TEXT="$1"                      # Dialog heading.
    declare INPUT_OPTIONS_VAR="$2"                # Input variable name.
    declare RETURN_ARRAY_VAR="$3"                 # Output variable name.
    declare -n INPUT_OPTIONS="$INPUT_OPTIONS_VAR" # Input array nameref.
    declare -n RETURN_ARRAY="$RETURN_ARRAY_VAR"   # Output array nameref.

    # Other variables:
    declare DIALOG_OPTIONS=()          # Input array for options dialog.
    declare SELECTED_OPTIONS_STRING="" # Output value from kdialog.

    # MAIN LOGIC.
    # kdialog doesn't need the options to be padded. We'll build the options array directly.
    for OPTION in "${INPUT_OPTIONS[@]}"; do
        TRIMMED_OPTIONS+=("$(echo "$OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')")
    done
    
    # kdialog --checklist expects a list of tags, items, and statuses.
    for OPTION in "${TRIMMED_OPTIONS[@]}"; do
        DIALOG_OPTIONS+=("" "$OPTION" off)
    done

    # Produce checkbox dialog using kdialog.
    SELECTED_OPTIONS_STRING=$(kdialog \
        --title "Selection" \
        --checklist "$DIALOG_TEXT" \
        "${DIALOG_OPTIONS[@]}" \
        2>&1)

    # If the user cancelled, exit.
    if [ $? -ne 0 ]; then
        exit 0
    fi

    # Convert the output string into an array. kdialog returns selected items as a space-separated string.
    # We must properly handle spaces within the option names themselves. kdialog encloses each item in quotes.
    # For example: '"Option 1" "The Second Option" "Option 3"'.
    # We need to parse this string into an array.
    IFS=$'\n' read -d '' -r -a RETURN_ARRAY < <(echo "$SELECTED_OPTIONS_STRING" | sed 's/\" \"/\"\n\"/g' | tr -d '"')

    # Final modifications.
    for ((i = 0; i < ${#RETURN_ARRAY[@]}; i++)); do
        # kdialog does not introduce escapes like dialog, so no need to remove them.
        # We also don't need to trim whitespace, as the parsing handles this.
        # The logic is simpler.
        : # This is a placeholder for any future modifications, no action needed here.
    done
}