#!/usr/bin/env bash
SCRIPT_VERSION="1.0"
WORK_DIR="$(pwd)"
cd $WORK_DIR
cd ..
GAMMA_DIR=$(pwd)
LOG_FILE_NAME=install.log
LOG_FOLDER="$WORK_DIR/logs"
LOG_FILE="$LOG_FOLDER/$LOG_FILE_NAME"
set -Eeuo pipefail
# ---- User vars ----
WINEFIX=true
BOTTLE_NAME="StalkerGAMMA"
LAUNCHER_NAME="ModOrganizer"
# ---- Global vars ----
SCRIPT_NAME="$(basename "$0")"
START_TIME="$(date +%s)"
RUNNER_NAME="ge-proton9-20"
BOTTLES_CHECK_PATH="/home/$USER/.var/app/com.usebottles.bottles"
BOTTLES_PREFIX_PATH="/home/$USER/.var/app/com.usebottles.bottles/data/bottles/bottles/$BOTTLE_NAME"
BOTTLES_RUNNER_PATH="/home/$USER/.var/app/com.usebottles.bottles/data/bottles/runners/"
BOTTLES_DXVK_PATH="/home/$USER/.var/app/com.usebottles.bottles/data/bottles/dxvk/"
BOTTLES_VKD3D_PATH="/home/$USER/.var/app/com.usebottles.bottles/data/bottles/vkd3d/"
BOTTLES_NVAPI_PATH="/home/$USER/.var/app/com.usebottles.bottles/data/bottles/nvapi/"
BOTTLES_LFLEX_PATH="/home/$USER/.var/app/com.usebottles.bottles/data/bottles/latencyflex/"
BOTTLES_RUNNER_WINE="$BOTTLES_RUNNER_PATH/$RUNNER_NAME/files/bin/wine"
BOTTLES_RUNNER_WINETRICKS="$BOTTLES_RUNNER_PATH/$RUNNER_NAME/protonfixes/winetricks"
TROUBLESOME_DISTROS=(bobrkurwa goyim_os)

# ---- Logging ----
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
die() {
    log red "ERROR: $*"
    log "Press any key to close this program."
    read -r user_input && exit 1
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
    log cyan "Init: Script version is [$SCRIPT_VERSION]"
    log cyan "Init: [WORK_DIR] is [${WORK_DIR}]"
    log cyan "Init: [LOG_FILE] is [${LOG_FILE}]"
    log cyan "Init: [BOTTLE_NAME] is [${BOTTLE_NAME}]"
    log cyan "Init: [LAUNCHER_NAME] is [${LAUNCHER_NAME}]"
    log cyan "Init: [RUNNER_NAME] is [${RUNNER_NAME}]"
    log cyan "Init: [BOTTLES_PREFIX_PATH] is [${BOTTLES_PREFIX_PATH}]"
    log cyan "Init: [BOTTLES_RUNNER_PATH] is [${BOTTLES_RUNNER_PATH}]"
    log cyan "Init: [BOTTLES_RUNNER_WINE] is [${BOTTLES_RUNNER_WINE}]"
    log cyan "Init: [BOTTLES_RUNNER_WINETRICKS] is [${BOTTLES_RUNNER_WINETRICKS}]"
    log cyan "Init: Distro info:"
    log cyan "Init: [ID] is [${ID}]"
    check_if_distro_is_supported
    log "Init: completed successfully"
}
check_if_distro_is_supported(){
    found=false
    for item in "${TROUBLESOME_DISTROS[@]}"; do
        if [[ "$item" == "$ID" ]]; then
            found=true
            break
        fi
    done
    if $found; then
        log red "Init: Your distro [${ID}] is know to have issues with this script."
        die "Distro [${ID}] is NOT supported"
    else
        log green "Init: Your distro [${ID}] is not known to have issues."
    fi
}
work() {
    log "Work: Starting GAMMA setup"
    flatpak_check
    flatpak_update
    flatpak_perms
    bottles_check_if_inital_setup_done
    bottles_get_dll
    runner_install
    bottles_makebottle
    bottles_configure
    prefix_configure
    prefix_verify
    log "Work: processing finished"
}
# ---- Actual Stuff ---- #
runner_install() {
    log "runner_INSTALL: Checking if the runner exists"
    cd $BOTTLES_RUNNER_PATH
    if [ -d "$RUNNER_NAME" ]; then
        log green "The folder of runner '$RUNNER_NAME' already exists!"
        
    else
        log red "No runner '$RUNNER_NAME' detected!"
        log yellow "runner_install: Installing proton in Bottles runners folder"
        cd $BOTTLES_RUNNER_PATH
        wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton9-20/GE-Proton9-20.tar.gz
        tar -xvzf GE-Proton9-20.tar.gz
        mv GE-Proton9-20 ge-proton9-20
        rm -v GE-Proton9-20.tar.gz
        log green "Runner '$RUNNER_NAME' installed!"
    fi
}
flatpak_update() {
    log "flatpak_update: Updating flatpak packages"
    flatpak update
}
flatpak_check() {
    log "Checking if flatpak Bottles installed."
    if flatpak list --app | grep -q "com.usebottles.bottles"; then
        log green "com.usebottles.bottles is installed."
    else
        log red "com.usebottles.bottles is not installed."
        log yellow "Installing now"
        flatpak install flathub com.usebottles.bottles
    fi
}
flatpak_perms() {
    log "Checking if flatpak Bottles has file access permissions."
    if flatpak info --show-permissions com.usebottles.bottles | grep -q "host"; then
        log green "Bottles has filesystem=host acess."
    else
        log red "Bottles does not have filesystem=host acess."
        log yellow "Asking permission to execute: flatpak override com.usebottles.bottles --filesystem=host ?"
        flatpak install flathub com.usebottles.bottles
    fi
}
bottles_makebottle() {
    log cyan "bottles_makebottle: Making a bottle for the game"
    flatpak run --command=bottles-cli com.usebottles.bottles new --bottle-name "$BOTTLE_NAME" --environment gaming --runner "$RUNNER_NAME" > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    log cyan "bottles_makebottle: bottles-cli new ended"
}
bottles_configure() {
    log cyan "bottles_configure: Adding MO2 to bottles"
    flatpak run --command=bottles-cli com.usebottles.bottles add -b "$BOTTLE_NAME" --name "$LAUNCHER_NAME" --path "$GAMMA_DIR/GAMMA/ModOrganizer.exe" > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    log cyan "bottles_configure: bottles-cli add ended"
}
prefix_configure() {
    log "prefix_configure: Installing dependencies"
    if [ $WINEFIX==1 ]; then
        WINE="$BOTTLES_RUNNER_WINE" WINEPREFIX="$BOTTLES_PREFIX_PATH" $BOTTLES_RUNNER_WINETRICKS list-installed > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    else
        WINEPREFIX="$BOTTLES_PREFIX_PATH" $BOTTLES_RUNNER_WINETRICKS list-installed >> >(tee "$LOG_FILE") > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    fi
}
prefix_verify() {
    log cyan "prefix_verify: Listing detected dependencies, might be useful for debugging, might be bugged"
    if [ $WINEFIX==1 ]; then
        WINE="$BOTTLES_RUNNER_WINE" WINEPREFIX="$BOTTLES_PREFIX_PATH" $BOTTLES_RUNNER_WINETRICKS list-installed >> >(tee "$LOG_FILE") > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    else
        WINEPREFIX="$BOTTLES_PREFIX_PATH" $BOTTLES_RUNNER_WINETRICKS list-installed >> >(tee "$LOG_FILE") > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    fi
}
bottles_check_if_inital_setup_done() {
    cd /home/$USER/.var/app
    while [ ! -d com.usebottles.bottles ]; do
        log red "No Bottles directory 'com.usebottles.bottles' found in /home/$USER/.var/app "
        log yellow "Please open Bottles and complete initial setup!"
        log yellow "When done, close bottles and press any key to attempt Stalker GAMMA bottle setup!"
        read -r user_input
    done
    log green "Bottles directory 'com.usebottles.bottles' was found in /home/$USER/.var/app"
    log "Continuing setting up of bottle for Stalker GAMMA"
}
bottles_get_dll() {
    log "bottles_get_dll: Get some older .dll in case Bottles auto-download-latest was broken"
    
    cd $BOTTLES_DXVK_PATH
    log "Checking if Bottles failed to download a DXVK version"
    if ! ls -d dxvk*/ >/dev/null 2>&1; then
        log red "No DXVK found"
        log yellow "Getting DXVK"
        wget https://github.com/doitsujin/dxvk/releases/download/v2.7.1/dxvk-2.7.1.tar.gz > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
        tar -xf dxvk-2.7.1.tar.gz > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
        rm -v dxvk*.tar.gz > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    else log green "DXVK found"
    fi
    cd $BOTTLES_VKD3D_PATH
    log "Checking if Bottles failed to download a VKD3D version"
    if ! ls -d vkd3d*/ >/dev/null 2>&1; then
        log red "No VKD3D found"
        log yellow "Getting VKD3D"
        wget https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v3.0b/vkd3d-proton-3.0b.tar.zst > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
        tar -xf vkd3d-proton-3.0b.tar.zst > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
        mv vkd3d-proton-3.0b vkd3d-proton-3.0 > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
        rm -v vkd3d-proton*.tar.zst > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    else log green "VKD3D found"
    fi
    log "Checking if Bottles failed to download a NVAPI version"
    cd $BOTTLES_NVAPI_PATH
    if ! ls -d dxvk-nvapi*/ >/dev/null 2>&1; then
        log red "No dxvk-nvapi found"
        log yellow "Getting dxvk-nvapi"
        wget https://github.com/jp7677/dxvk-nvapi/releases/download/v0.9.0/dxvk-nvapi-v0.9.0.tar.gz > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
        mkdir dxvk-nvapi-v0.9.0 > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
        tar -xf dxvk-nvapi-v0.9.0.tar.gz -C "$BOTTLES_NVAPI_PATH/dxvk-nvapi-v0.9.0" > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
        rm -v dxvk-nvapi-v0.9.0.tar.gz > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    else log green "dxvk-nvapi found"
    fi
    cd $BOTTLES_LFLEX_PATH
    log "Checking if Bottles failed to download a LatencyFlex version"
    if ! ls -d latencyflex*/ >/dev/null 2>&1; then
        log red "No latencyflex found"
        log yellow "Getting latencyflex"
        wget https://github.com/ishitatsuyuki/LatencyFleX/releases/download/v0.1.1/latencyflex-v0.1.1.tar.xz > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
        tar -xf latencyflex-v0.1.1.tar.xz > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
        rm -v latencyflex*.tar.xz > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    else log green "latencyflex found"
    fi
}
# ---- Main entry point ----
main() {
    # Making sure LOG_FOLDER exists.
    mkdir -p $LOG_FOLDER

    log "Main: script started (${SCRIPT_NAME})"
    init
    work
    local end_time
    end_time="$(date +%s)"
    log "Main: script finished in $((end_time - START_TIME)) seconds"
    log green "Enjoy your time in the zone, Stalker! \o"
    read -r user_input && exit
}
main "$@"
