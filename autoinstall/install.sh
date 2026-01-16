#!/usr/bin/env bash
SCRIPT_VERSION="1.0"
WORK_DIR="$(pwd)"
cd $WORK_DIR
cd ..
GAMMA_DIR=$(pwd)
LOG_FILE_NAME=install.log
LOG_FILE="$WORK_DIR/logs/$LOG_FILE_NAME"
set -Eeuo pipefail
SCRIPT_NAME="$(basename "$0")"
START_TIME="$(date +%s)"
# ---- User vars ----
DOWNLOAD_THREADS="2"
GAMMA_FOLDER="GAMMA"
ANOMALY_FOLDER="Anomaly"
MAJOR_VERSION=1
# --- For stalker-gamma-cli github acess
MAJOR_VERSION=1
TARGET="/download/$MAJOR_VERSION."
# ---
log() {
    local color_reset="\033[0m"
    local color=""
    local message=""
    case "${1:-}" in
        red)    color="\033[31m"; shift ;;
        green)  color="\033[32m"; shift ;;
        yellow) color="\033[33m"; shift ;;
        blue)   color="\033[34m"; shift ;;
        magenta)color="\033[35m"; shift ;;
        cyan)   color="\033[36m"; shift ;;
    esac
    message="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    # Print to terminal with color
    if [ -n "$color" ]; then
        echo -e "${color}${message}${color_reset}"
    else
        echo "$message"
    fi
    # Log the message without color codes
    echo -e "$message" >> "$LOG_FILE"
}
work() {
    cd $GAMMA_DIR
    get_stalker_gamma_cli
    check_stalker_gamma_cli_version
    create_gamma_cli_config
    full_install
    update_check
}
init() {
    source /etc/os-release
    cd $WORK_DIR
    if [ -f logs/$LOG_FILE_NAME ]; then
        echo "Purging old log."
        cd logs
        rm -v $LOG_FILE_NAME
        cd ..
    fi
    log "Init: starting initialization"
    log cyan "Init: Work variables:"
    log cyan "Init Script version is [$SCRIPT_VERSION]"
    log cyan "Init: [DOWNLOAD_THREADS] is [${DOWNLOAD_THREADS}]"
    log cyan "Init: [GAMMA_FOLDER] is [${GAMMA_FOLDER}]"
    log cyan "Init: [ANOMALY_FOLDER] is [${ANOMALY_FOLDER}]"
    log cyan "Init: [MAJOR_VERSION] is [${MAJOR_VERSION}]"
    log cyan "Init: [TARGET] is [${TARGET}]"
    log cyan "Init: [LOG_FILE] is [${LOG_FILE}]"
    log cyan "Init: [GAMMA_DIR] is [${GAMMA_DIR}]"
    log cyan "Init: Distro info:[ID] is [${ID}]"
    log "Init: completed successfully"
}
update_check() {
    log cyan "update_check: Commencing update check for verification"
    ./stalker-gamma*.AppImage update check > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
}
full_install() {
    log cyan "full_install: Commencing full install"
    ./stalker-gamma*.AppImage full-install > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
}
create_gamma_cli_config() {
    log cyan "create_gamma_cli_config: Making a config in the stalker-gamma-cli"
    ./stalker-gamma*.AppImage config create --anomaly "$ANOMALY_FOLDER" --gamma "$GAMMA_FOLDER" --cache cache --download-threads "$DOWNLOAD_THREADS" > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    log cyan "create_gamma_cli_config: done"
}
check_stalker_gamma_cli_version() {
    log cyan "check_stalker_gamma_cli_version: Check version:"
    ./stalker-gamma.AppImage --version > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
}
get_stalker_gamma_cli() {
    log cyan "get_stalker_gamma_cli: Downloading latest release of stalker-gamma-cli"
    wget -O - https://api.github.com/repos/FaithBeam/stalker-gamma-cli/releases?per_page=100 \
        | jq -r --arg target "$TARGET" 'first(.[].assets[] | .browser_download_url | select(contains("linux") and contains("x64") and contains($target)))' \
        | wget -i - -O stalker-gamma.AppImage \
    && chmod +x stalker-gamma.AppImage > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
}
main() {
    log "Main: script started (${SCRIPT_NAME})"
    init
    work
    local end_time
    end_time="$(date +%s)"
    log "Main: script finished in $((end_time - START_TIME)) seconds"
    log green "DONE! Input anything to exit. \o"
    read -r user_input && exit
}
main "$@"

