function inqChkBx() {
    # DECLARE VARIABLES.
    declare DIALOG_TEXT="$1"
    declare INPUT_OPTIONS_VAR="$2"
    declare RETURN_ARRAY_VAR="$3"
    declare -n INPUT_OPTIONS="$INPUT_OPTIONS_VAR"
    declare -n RETURN_ARRAY="$RETURN_ARRAY_VAR"

    # Other variables:
    declare TRIMMED_OPTIONS=()       # Input array post-trimming.
    declare DIALOG_OPTIONS=()        # Input array for options dialog.
    declare DIALOG_WIDTH=0           # Width of dialog window.
    declare OPTION_NUMBER=0          # Number of options in dialog window.
    declare SELECTED_OPTIONS_STRING="" # Output value from dialog window.

    # MAIN LOGIC.
    # Trim leading and trailing white space for each option.
    for OPTION in "${INPUT_OPTIONS[@]}"; do
        TRIMMED_OPTIONS+=("$(echo "$OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')")
    done

    # Prepare kdialog options (key1 label1 off key2 label2 off ...)
    local i=1
    for OPTION in "${TRIMMED_OPTIONS[@]}"; do
        DIALOG_OPTIONS+=("$i" "$OPTION" "off")
        ((i++))
    done

    # Show checklist
    local SELECTED_KEYS
    SELECTED_KEYS=$(kdialog --checklist "$DIALOG_TEXT" "${DIALOG_OPTIONS[@]}" 2>&1 >/dev/tty) || return 1
    
    # Check if dialog was canceled
    if [[ $? -ne 0 ]]; then
        echo "Dialog was cancelled." >&2
        return 1
    fi

    # Convert the output from kdialog to the format expected by the original script.
    local SELECTED_OPTIONS_STRING=""
    local -a KEYS
    IFS=" " read -r -a KEYS <<< "$SELECTED_KEYS"

    for KEY in "${KEYS[@]}"; do
        local ORIGINAL_OPTION="${INPUT_OPTIONS[$((KEY - 1))]}"
        local TRIMMED_OPTION="$(echo "$ORIGINAL_OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')"
        SELECTED_OPTIONS_STRING+="\"$TRIMMED_OPTION\" "
    done
    
    # Remove the last trailing space.
    SELECTED_OPTIONS_STRING="${SELECTED_OPTIONS_STRING% }"

    # Process the formatted output string exactly like the original dialog script.
    RETURN_ARRAY=()
    while IFS= read -r LINE; do
        LINE="${LINE/#\"/}"      # Remove leading double quote.
        LINE="${LINE/%\"/}"      # Remove trailing double quote.
        RETURN_ARRAY+=("$LINE")  # Add to array.
    done < <(echo "$SELECTED_OPTIONS_STRING" | sed 's/\" \"/\"\n\"/g')

    # Final modifications.
    for ((i = 0; i < ${#RETURN_ARRAY[@]}; i++)); do
        # Remove white space added previously.
        RETURN_ARRAY[i]=$(echo "${RETURN_ARRAY[i]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        # Remove escapes (introduced by 'dialog' if options have parentheses).
        RETURN_ARRAY[i]=${RETURN_ARRAY[i]//\\/}
    done

    # Display question and response, matching the original format.
    echo -e "${ANSI_LIGHT_GREEN}Q) ${ANSI_CLEAR_TEXT}${ANSI_LIGHT_BLUE}${DIALOG_TEXT}${ANSI_CLEAR_TEXT} --> ${ANSI_LIGHT_GREEN}${SELECTED_OPTIONS_STRING}${ANSI_CLEAR_TEXT}"
    return 0
}