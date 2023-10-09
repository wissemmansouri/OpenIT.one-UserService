#!/bin/bash

set -e

readonly OPEN_EXEC=openit-user-service
readonly OPEN_SERVICE=openit-user-service.service

OPEN_SERVICE_PATH=$(systemctl show ${OPEN_SERVICE} --no-pager  --property FragmentPath | cut -d'=' -sf2)
readonly OPEN_SERVICE_PATH

OPEN_CONF=$( grep -i ExecStart= "${OPEN_SERVICE_PATH}" | cut -d'=' -sf2 | cut -d' ' -sf3)
if [[ -z "${OPEN_CONF}" ]]; then
    OPEN_CONF=/etc/openit/user-service.conf
fi

OPEN_DB_PATH=$( (grep -i dbpath "${OPEN_CONF}" || echo "/var/lib/openit/db") | cut -d'=' -sf2 | xargs )
readonly OPEN_DB_PATH

OPEN_DB_FILE=${OPEN_DB_PATH}/user-service.db

readonly aCOLOUR=(
    '\e[38;5;154m' # green  	| Lines, bullets and separators
    '\e[1m'        # Bold white	| Main descriptions
    '\e[90m'       # Grey		| Credits
    '\e[91m'       # Red		| Update notifications Alert
    '\e[33m'       # Yellow		| Emphasis
)

Show() {
    # OK
    if (($1 == 0)); then
        echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[0]}  OK  $COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2"
    # FAILED
    elif (($1 == 1)); then
        echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[3]}FAILED$COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2"
    # INFO
    elif (($1 == 2)); then
        echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[0]} INFO $COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2"
    # NOTICE
    elif (($1 == 3)); then
        echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[4]}NOTICE$COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2"
    fi
}

Warn() {
    echo -e "${aCOLOUR[3]}$1$COLOUR_RESET"
}

trap 'onCtrlC' INT
onCtrlC() {
    echo -e "${COLOUR_RESET}"
    exit 1
}

if [[ ! -x "$(command -v ${OPEN_EXEC})" ]]; then
    Show 2 "${OPEN_EXEC} is not detected, exit the script."
    exit 1
fi

while true; do
    echo -n -e "         ${aCOLOUR[4]}Do you want delete user database? Y/n :${COLOUR_RESET}"
    read -r input
    case $input in
    [yY][eE][sS] | [yY])
        REMOVE_USER_DATABASE=true
        break
        ;;
    [nN][oO] | [nN])
        REMOVE_USER_DATABASE=false
        break
        ;;
    *)
        echo -e "         ${aCOLOUR[3]}Invalid input, please try again.${COLOUR_RESET}"
        ;;
    esac
done

while true; do
    echo -n -e "         ${aCOLOUR[4]}Do you want delete user directory? Y/n :${COLOUR_RESET}"
    read -r input
    case $input in
    [yY][eE][sS] | [yY])
        REMOVE_USER_DIRECTORY=true
        break
        ;;
    [nN][oO] | [nN])
        REMOVE_USER_DIRECTORY=false
        break
        ;;
    *)
        echo -e "         ${aCOLOUR[3]}Invalid input, please try again.${COLOUR_RESET}"
        ;;
    esac
done

Show 2 "Stopping ${OPEN_SERVICE}..."
systemctl disable --now "${OPEN_SERVICE}" || Show 3 "Failed to disable ${OPEN_SERVICE}"

rm -rvf "$(which ${OPEN_EXEC})" || Show 3 "Failed to remove ${OPEN_EXEC}"
rm -rvf "${OPEN_CONF}" || Show 3 "Failed to remove ${OPEN_CONF}"

if [[ "${REMOVE_USER_DATABASE}" == true ]]; then
    rm -rvf "${OPEN_DB_FILE}" || Show 3 "Failed to remove ${OPEN_DB_FILE}"
fi

if [[ "${REMOVE_USER_DIRECTORY}" == true ]]; then
    Show 2 "Removing user directories..."
    rm -rvf /var/lib/openit/[1-9]*
fi
