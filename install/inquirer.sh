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
    declare OPTION_NUMBER=0
    declare SELECTED_OPTIONS_STRING=""

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

    # Produce checkbox.
    local SELECTED_KEYS
    SELECTED_KEYS=$(kdialog --checklist "$DIALOG_TEXT" "${DIALOG_OPTIONS[@]}" 2>&1 >/dev/tty) || return 1

    # Convert kdialog output to the format expected by the original dialog script.
    local FORMATTED_OUTPUT=""
    local -a KEYS
    IFS=" " read -r -a KEYS <<< "$SELECTED_KEYS"

    for KEY in "${KEYS[@]}"; do
        # Use the padded option string directly, just like the original script.
        FORMATTED_OUTPUT+="\"${PADDED_OPTIONS[$((KEY - 1))]}\" "
    done
    
    # Remove the trailing space.
    FORMATTED_OUTPUT="${FORMATTED_OUTPUT% }"

    # Process the formatted output string exactly like the original dialog script.
    RETURN_ARRAY=()
    while IFS= read -r LINE; do
        LINE="${LINE/#\"/}"
        LINE="${LINE/%\"/}"
        RETURN_ARRAY+=("$LINE")
    done < <(echo "$FORMATTED_OUTPUT" | sed 's/\" \"/\"\n\"/g')

    # Final modifications.
    for ((i = 0; i < ${#RETURN_ARRAY[@]}; i++)); do
        # Remove white space added previously.
        RETURN_ARRAY[i]=$(echo "${RETURN_ARRAY[i]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        # Remove escapes (introduced by 'dialog' if options have parentheses).
        RETURN_ARRAY[i]=${RETURN_ARRAY[i]//\\/}
    done

    # Display question and response, matching the original format.
    echo -e "${ANSI_LIGHT_GREEN}Q) ${ANSI_CLEAR_TEXT}${ANSI_LIGHT_BLUE}${DIALOG_TEXT}${ANSI_CLEAR_TEXT} --> ${ANSI_LIGHT_GREEN}${FORMATTED_OUTPUT}${ANSI_CLEAR_TEXT}"
    return 0
}