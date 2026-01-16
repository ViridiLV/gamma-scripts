#!/usr/bin/env bash
SCRIPT_VERSION="1.0"
WORK_DIR="$(pwd)"
cd $WORK_DIR
cd ..
GAMMA_DIR=$(pwd)
LOG_FILE_NAME=gamma-scripts.log
LOG_FILE="$WORK_DIR/logs/$LOG_FILE_NAME"
set -Eeuo pipefail
SCRIPT_NAME="$(basename "$0")"
START_TIME="$(date +%s)"
# ---- User vars ----
DOWNLOAD_THREADS="2"
GAMMA_FOLDER="GAMMA"
ANOMALY_FOLDER="Anomaly"
MAJOR_VERSION=1
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
# --- For stalker-gamma-cli github acess
MAJOR_VERSION=1
TARGET="/download/$MAJOR_VERSION."
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


install() {
    cd $GAMMA_DIR
    install_get_stalker_gamma_cli
    install_check_stalker_gamma_cli_version
    install_create_gamma_cli_config
    install_full_install
    install_update_check
    local end_time
    end_time="$(date +%s)"
    log "Main: action finished in $((end_time - START_TIME)) seconds"
}
install_init() {
    source /etc/os-release
    cd $WORK_DIR
    if [ -f logs/$LOG_FILE_NAME ]; then
        echo "Purging old log."
        cd logs
        rm -v $LOG_FILE_NAME
        cd ..
    fi
    log "install_Init: starting initialization"
    log cyan "install_Init: Work variables:"
    log cyan "install_Init Script version is [$SCRIPT_VERSION]"
    log cyan "install_Init: [DOWNLOAD_THREADS] is [${DOWNLOAD_THREADS}]"
    log cyan "install_Init: [GAMMA_FOLDER] is [${GAMMA_FOLDER}]"
    log cyan "install_Init: [ANOMALY_FOLDER] is [${ANOMALY_FOLDER}]"
    log cyan "install_Init: [MAJOR_VERSION] is [${MAJOR_VERSION}]"
    log cyan "install_Init: [TARGET] is [${TARGET}]"
    log cyan "install_Init: [LOG_FILE] is [${LOG_FILE}]"
    log cyan "install_Init: [GAMMA_DIR] is [${GAMMA_DIR}]"
    log cyan "install_Init: Distro info:[ID] is [${ID}]"
    log "install_Init: completed successfully"
}
setup_init() {
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
setup_check_if_distro_is_supported(){
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
setup() {
    log "setup: Starting GAMMA setup"
    setup_flatpak_check
    setup_flatpak_update
    setup_flatpak_perms
    setup_bottles_check_if_inital_setup_done
    setup_bottles_get_dll
    setup_runner_install
    setup_bottles_makebottle
    setup_bottles_configure
    setup_prefix_configure
    setup_prefix_verify
    log "setup: processing finished"
    local end_time
    end_time="$(date +%s)"
    log "Main: action finished in $((end_time - START_TIME)) seconds"
}
setup_runner_install() {
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
setup_flatpak_update() {
    log "flatpak_update: Updating flatpak packages"
    flatpak update
}
setup_flatpak_check() {
    log "Checking if flatpak Bottles installed."
    if flatpak list --app | grep -q "com.usebottles.bottles"; then
        log green "com.usebottles.bottles is installed."
    else
        log red "com.usebottles.bottles is not installed."
        log yellow "Installing now"
        flatpak install flathub com.usebottles.bottles
    fi
}
setup_flatpak_perms() {
    log "Checking if flatpak Bottles has file access permissions."
    if flatpak info --show-permissions com.usebottles.bottles | grep -q "host"; then
        log green "Bottles has filesystem=host acess."
    else
        log red "Bottles does not have filesystem=host acess."
        log yellow "Asking permission to execute: flatpak override com.usebottles.bottles --filesystem=host ?"
        flatpak install flathub com.usebottles.bottles
    fi
}
setup_bottles_makebottle() {
    log cyan "bottles_makebottle: Making a bottle for the game"
    flatpak run --command=bottles-cli com.usebottles.bottles new --bottle-name "$BOTTLE_NAME" --environment gaming --runner "$RUNNER_NAME" > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    log cyan "bottles_makebottle: bottles-cli new ended"
}
setup_bottles_configure() {
    log cyan "bottles_configure: Adding MO2 to bottles"
    flatpak run --command=bottles-cli com.usebottles.bottles add -b "$BOTTLE_NAME" --name "$LAUNCHER_NAME" --path "$GAMMA_DIR/GAMMA/ModOrganizer.exe" > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    log cyan "bottles_configure: bottles-cli add ended"
}
setup_prefix_configure() {
    log "prefix_configure: Installing dependencies"
    if [ $WINEFIX==1 ]; then
        WINE="$BOTTLES_RUNNER_WINE" WINEPREFIX="$BOTTLES_PREFIX_PATH" $BOTTLES_RUNNER_WINETRICKS list-installed > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    else
        WINEPREFIX="$BOTTLES_PREFIX_PATH" $BOTTLES_RUNNER_WINETRICKS list-installed >> >(tee "$LOG_FILE") > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    fi
}
setup_prefix_verify() {
    log cyan "prefix_verify: Listing detected dependencies, might be useful for debugging, might be bugged"
    if [ $WINEFIX==1 ]; then
        WINE="$BOTTLES_RUNNER_WINE" WINEPREFIX="$BOTTLES_PREFIX_PATH" $BOTTLES_RUNNER_WINETRICKS list-installed >> >(tee "$LOG_FILE") > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    else
        WINEPREFIX="$BOTTLES_PREFIX_PATH" $BOTTLES_RUNNER_WINETRICKS list-installed >> >(tee "$LOG_FILE") > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    fi
}
setup_bottles_check_if_inital_setup_done() {
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
setup_bottles_get_dll() {
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
install_update_check() {
    log cyan "update_check: Commencing update check for verification"
    ./stalker-gamma*.AppImage update check > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
}
install_full_install() {
    log cyan "install_full_install: Commencing full install"
    ./stalker-gamma*.AppImage full-install > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
}
install_create_gamma_cli_config() {
    log cyan "install_create_gamma_cli_config: Making a config in the stalker-gamma-cli"
    ./stalker-gamma*.AppImage config create --anomaly "$ANOMALY_FOLDER" --gamma "$GAMMA_FOLDER" --cache cache --download-threads "$DOWNLOAD_THREADS" > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    log cyan "install_create_gamma_cli_config: done"
}
install_check_stalker_gamma_cli_version() {
    log cyan "install_check_stalker_gamma_cli_version: Check version:"
    ./stalker-gamma.AppImage --version > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
}
install_get_stalker_gamma_cli() {
    log cyan "install_get_stalker_gamma_cli: Downloading latest release of stalker-gamma-cli"
    wget -O - https://api.github.com/repos/FaithBeam/stalker-gamma-cli/releases?per_page=100 \
        | jq -r --arg target "$TARGET" 'first(.[].assets[] | .browser_download_url | select(contains("linux") and contains("x64") and contains($target)))' \
        | wget -i - -O stalker-gamma.AppImage \
    && chmod +x stalker-gamma.AppImage > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
}
die() {
    log red "ERROR: $*"
    log "Press any key to close this program."
    read -r user_input && exit 1
}
die_exit() {
    log "Exitting due to user input selection - Exit"
    log "Bye!"
}
greet() {
    log "Stalker GAMMA community install/setup shell scripts"
    log "version: [$SCRIPT_VERSION]"
    log "For ducumentation see:"
    log "https://github.com/ViridiLV/G.A.M.M.A-Community-Linux-Install-Setup-shell-scripts"
}
select() {
    log "-------------------------------------------------"
    log "Possible actions:"
    log "[1] - Install game files with stalker-gamma-cli"
    log "[2] - Setup flatpak GAMMA bottle"
    log "[3] - Exit"
    log "-------------------------------------------------"
    user_input_select=""
    selected=false
    while [ selected==false ]; do
        log "Please select your action:"
        read -p user_input
        if user_input_select==1; then
            install_init
            install
            selected=true
        elif user_input_select==2; then
            setup_init
            setup
            selected=true
        elif user_input_select==3; then
            die_exit
        else
            log red "[${user_input_select}]Not a valid input!"
        fi
    done
}
main() {
    log "Main: script started (${SCRIPT_NAME})"
    greet
    select
    
    log "Main: script end. Input anything to exit. \o"
    read -r user_input && exit
}
main "$@"
