#!/usr/bin/env bash
# Copyright (c) 2024 kahkhang
# All rights reserved.
#
# SPDX-License-Identifier: MIT
# For original source, see https://github.com/kahkhang/Inquirer.sh

# Replaced original functions with 'dialog' by a 'kdialog' variant envisioned from ChatGPT

### GLOBAL CONSTANTS ###
declare -r ANSI_LIGHT_BLUE="\033[1;94m"
declare -r ANSI_LIGHT_GREEN="\033[92m"
declare -r ANSI_CLEAR_TEXT="\033[0m"

### FUNCTIONS ###
function inqMenu() {
    declare DIALOG_TEXT="$1"
    declare INPUT_OPTIONS_VAR="$2"
    declare RETURN_STRING_VAR="$3"
    declare -n INPUT_OPTIONS="$INPUT_OPTIONS_VAR"
    declare -n RETURN_STRING="$RETURN_STRING_VAR"

    # Menüeinträge vorbereiten (key1 label1 key2 label2 ...)
    declare DIALOG_OPTIONS=()
    local i=1
    for OPTION in "${INPUT_OPTIONS[@]}"; do
        local TRIMMED="$(echo "$OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')"
        DIALOG_OPTIONS+=("$i" "$TRIMMED")
        ((i++))
    done

    # Menü anzeigen
    local SELECTED_KEY
    SELECTED_KEY=$(kdialog --menu "$DIALOG_TEXT" "${DIALOG_OPTIONS[@]}") || exit 0

    # Rückgabe-Index in tatsächliche Option umwandeln
    RETURN_STRING="${INPUT_OPTIONS[$((SELECTED_KEY - 1))]}"

    # Ausgabe
    echo -e "${ANSI_LIGHT_GREEN}Q) ${ANSI_CLEAR_TEXT}${ANSI_LIGHT_BLUE}${DIALOG_TEXT}${ANSI_CLEAR_TEXT} --> ${ANSI_LIGHT_GREEN}${RETURN_STRING}${ANSI_CLEAR_TEXT}"
}

function inqChkBx() {
    declare DIALOG_TEXT="$1"
    declare INPUT_OPTIONS_VAR="$2"
    declare RETURN_ARRAY_VAR="$3"
    declare -n INPUT_OPTIONS="$INPUT_OPTIONS_VAR"
    declare -n RETURN_ARRAY="$RETURN_ARRAY_VAR"

    # Checkliste vorbereiten
    declare DIALOG_OPTIONS=()
    local i=1
    for OPTION in "${INPUT_OPTIONS[@]}"; do
        local TRIMMED="$(echo "$OPTION" | sed 's/^[ \t]*//;s/[ \t]*$//')"
        DIALOG_OPTIONS+=("$i" "$TRIMMED" "off")
        ((i++))
    done

    # Checkliste anzeigen
    local SELECTED_KEYS
    SELECTED_KEYS=$(kdialog --checklist "$DIALOG_TEXT" "${DIALOG_OPTIONS[@]}") || exit 0

    # Rückgabe in tatsächliche Optionen umwandeln
    IFS=" " read -r -a KEYS <<< "$SELECTED_KEYS"
    for KEY in "${KEYS[@]}"; do
        RETURN_ARRAY+=("${INPUT_OPTIONS[$((KEY - 1))]}")
    done

    # Ausgabe
    echo -e "${ANSI_LIGHT_GREEN}Q) ${ANSI_CLEAR_TEXT}${ANSI_LIGHT_BLUE}${DIALOG_TEXT}${ANSI_CLEAR_TEXT} --> ${ANSI_LIGHT_GREEN}${RETURN_ARRAY[*]}${ANSI_CLEAR_TEXT}"
}
