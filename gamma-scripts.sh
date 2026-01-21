#!/usr/bin/env bash
SCRIPT_VERSION="1.1"
GAMMA_DIR="$(pwd)"
LOG_FILE_NAME="gamma-scripts$(date --utc +%Y-%m-%dT%H:%M:%S%Z).log"
LOG_FOLDER="$GAMMA_DIR/logs"
LOG_FILE="$LOG_FOLDER/$LOG_FILE_NAME"
set -Eeuo pipefail
SCRIPT_NAME="$(basename "$0")"
START_TIME="$(date +%s)"
# ---- User vars ----
DOWNLOAD_THREADS="2"
GAMMA_FOLDER="GAMMA"
ANOMALY_FOLDER="Anomaly"
CACHE_FOLDER="cache"
WINEFIX=true
BOTTLE_NAME="StalkerGAMMA"
LAUNCHER_NAME="ModOrganizer"
# ---- Global vars ----
SCRIPT_NAME="$(basename "$0")"
START_TIME="$(date +%s)"
RUNNER_NAME="ge-proton9-20"
STALKER_GAMMA_CLI_URL="https://github.com/FaithBeam/stalker-gamma-cli/releases/latest/download/stalker-gamma+linux.x64.AppImage"
PROTON_GE_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton9-20/GE-Proton9-20.tar.gz"
PROTON_GE_NAME="GE-Proton9-20" # fix this latter with name-agnostic code
BOTTLES_CHECK_PATH="~/.var/app/com.usebottles.bottles"
BOTTLES_PREFIX_PATH="~/.var/app/com.usebottles.bottles/data/bottles/bottles/$BOTTLE_NAME"
BOTTLES_RUNNER_PATH="~/.var/app/com.usebottles.bottles/data/bottles/runners/"
BOTTLES_DXVK_PATH="~/.var/app/com.usebottles.bottles/data/bottles/dxvk/"
BOTTLES_VKD3D_PATH="~/.var/app/com.usebottles.bottles/data/bottles/vkd3d/"
BOTTLES_NVAPI_PATH="~/.var/app/com.usebottles.bottles/data/bottles/nvapi/"
BOTTLES_LFLEX_PATH="~/.var/app/com.usebottles.bottles/data/bottles/latencyflex/"
BOTTLES_RUNNER_WINE="$BOTTLES_RUNNER_PATH/$RUNNER_NAME/files/bin/wine"
BOTTLES_RUNNER_WINETRICKS="$BOTTLES_RUNNER_PATH/$RUNNER_NAME/protonfixes/winetricks"
TROUBLESOME_DISTROS=(bobrkurwa goyim_os)

install_init() {
    source /etc/os-release

    cd $GAMMA_DIR

    log "install_Init: starting initialization"
    log cyan "install_Init: Work variables:"
    log cyan "install_Init Script version is [$SCRIPT_VERSION]"
    log cyan "install_Init: [DOWNLOAD_THREADS] is [${DOWNLOAD_THREADS}]"
    log cyan "install_Init: [GAMMA_FOLDER] is [${GAMMA_FOLDER}]"
    log cyan "install_Init: [ANOMALY_FOLDER] is [${ANOMALY_FOLDER}]"
    log cyan "install_Init: [LOG_FILE] is [${LOG_FILE}]"
    log cyan "install_Init: [GAMMA_DIR] is [${GAMMA_DIR}]"
    log cyan "install_Init: Distro info:[ID] is [${ID}]"
    log "install_Init: completed successfully"
}
setup_init() {
    source /etc/os-release
   
    cd $GAMMA_DIR

    log "setup_init: starting initialization"
    log cyan "setup_init: Work variables:"
    log cyan "setup_init: Script version is [$SCRIPT_VERSION]"
    log cyan "setup_init: [GAMMA_DIR] is [${GAMMA_DIR}]"
    log cyan "setup_init: [LOG_FILE] is [${LOG_FILE}]"
    log cyan "setup_init: [BOTTLE_NAME] is [${BOTTLE_NAME}]"
    log cyan "setup_init: [LAUNCHER_NAME] is [${LAUNCHER_NAME}]"
    log cyan "setup_init: [RUNNER_NAME] is [${RUNNER_NAME}]"
    log cyan "setup_init: [WINEFIX] is [${WINEFIX}]"
    log cyan "setup_init: [BOTTLES_PREFIX_PATH] is [${BOTTLES_PREFIX_PATH}]"
    log cyan "setup_init: [BOTTLES_RUNNER_PATH] is [${BOTTLES_RUNNER_PATH}]"
    log cyan "setup_init: [BOTTLES_RUNNER_WINE] is [${BOTTLES_RUNNER_WINE}]"
    log cyan "setup_init: [BOTTLES_RUNNER_WINETRICKS] is [${BOTTLES_RUNNER_WINETRICKS}]"
    log cyan "setup_init: Distro info:"
    log cyan "setup_init: [ID] is [${ID}]"
    setup_check_if_distro_is_supported
    log "setup_init: completed successfully"
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
        log red "setup_check_if_distro_is_supported: Your distro [${ID}] is know to have issues with this script."
        die "Distro [${ID}] is NOT supported"
    else
        log green "Init: Your distro [${ID}] is not known to have issues."
    fi
}
setup_runner_install() {
    log "setup_runner_install: Checking if the runner exists"
    cd $BOTTLES_RUNNER_PATH
    if [ -d "$RUNNER_NAME" ]; then
        log green "The folder of runner '$RUNNER_NAME' already exists!"
        
    else
        log red "No runner '$RUNNER_NAME' detected!"
        log yellow "runner_install: Installing proton in Bottles runners folder"
        cd $BOTTLES_RUNNER_PATH
        wget $PROTON_GE_URL -O $PROTON_GE_NAME.tar.gz # TODO: Name-agnostic code with regex or someting
        tar -xvzf $PROTON_GE_NAME.tar.gz # TODO: Name-agnostic code with regex or someting
        mv $PROTON_GE_NAME ge-proton9-20 # TODO: Name-agnostic code with regex or someting
        rm -v $PROTON_GE_NAME.tar.gz # TODO: Name-agnostic code with regex or someting
        log green "Runner '$RUNNER_NAME' installed!"
    fi
}
setup_flatpak_update() {
    log "setup_flatpak_update: Updating flatpak packages"
    flatpak update
}
setup_flatpak_check() {
    log "setup_flatpak_check: Checking if flatpak Bottles installed."
    if flatpak list --app | grep -q "com.usebottles.bottles"; then
        log green "com.usebottles.bottles is installed."
    else
        log red "com.usebottles.bottles is not installed."
        log yellow "Installing now"
        flatpak install flathub com.usebottles.bottles
    fi
}
setup_flatpak_perms() {
    log "setup_flatpak_perms: Checking if flatpak Bottles has file access permissions."
    if flatpak info --show-permissions com.usebottles.bottles | grep -q "host"; then
        log green "Bottles has filesystem=host acess."
    else
        log red "Bottles does not have filesystem=host acess."
        log yellow "Asking permission to execute: flatpak override com.usebottles.bottles --filesystem=host ?"
        flatpak install flathub com.usebottles.bottles
    fi
}
setup_bottles_makebottle() {
    log cyan "setup_bottles_makebottle: Making a bottle for the game"
    flatpak run --command=bottles-cli com.usebottles.bottles new --bottle-name "$BOTTLE_NAME" --environment gaming --runner "$RUNNER_NAME" > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    log cyan "setup_bottles_makebottle: bottles-cli new ended"
}
setup_bottles_configure() {
    log cyan "setup_bottles_configure: Adding MO2 to bottles"
    flatpak run --command=bottles-cli com.usebottles.bottles add -b "$BOTTLE_NAME" --name "$LAUNCHER_NAME" --path "$GAMMA_DIR/GAMMA/ModOrganizer.exe" > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    log cyan "\nbottles_configure: bottles-cli add ended"
}
setup_prefix_configure() {
    log "setup_prefix_configure: Installing dependencies"
    if [ $WINEFIX==1 ]; then
        WINE="$BOTTLES_RUNNER_WINE" WINEPREFIX="$BOTTLES_PREFIX_PATH" $BOTTLES_RUNNER_WINETRICKS cmd d3dx9 dx8vb d3dcompiler_42 d3dcompiler_43 d3dcompiler_46 d3dcompiler_47 d3dx10_43 d3dx10 d3dx11_42 d3dx11_43 dxvk quartz > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    else
        WINEPREFIX="$BOTTLES_PREFIX_PATH" $BOTTLES_RUNNER_WINETRICKS cmd d3dx9 dx8vb d3dcompiler_42 d3dcompiler_43 d3dcompiler_46 d3dcompiler_47 d3dx10_43 d3dx10 d3dx11_42 d3dx11_43 dxvk quartz >> >(tee "$LOG_FILE") > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    fi
}
setup_prefix_verify() {
    log cyan "setup_prefix_verify: Listing detected dependencies, might be useful for debugging, might be bugged"
    if [ $WINEFIX==1 ]; then
        WINE="$BOTTLES_RUNNER_WINE" WINEPREFIX="$BOTTLES_PREFIX_PATH" $BOTTLES_RUNNER_WINETRICKS list-installed > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    else
        WINEPREFIX="$BOTTLES_PREFIX_PATH" $BOTTLES_RUNNER_WINETRICKS list-installed > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    fi
}
setup_bottles_check_if_inital_setup_done() {
    cd ~.var/app
    while [ ! -d com.usebottles.bottles ]; do
        log red "No Bottles directory 'com.usebottles.bottles' found in ~/.var/app "
        log yellow "Please open Bottles and complete initial setup!"
        log yellow "When done, close bottles and press any key to attempt Stalker GAMMA bottle setup!"
        read -r user_input
    done
    log green "Bottles directory 'com.usebottles.bottles' was found in ~/.var/app"
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
    cd $GAMMA_DIR
    log cyan "update_check: Commencing update check for verification"
    ./stalker-gamma*.AppImage update check > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
}
install_full_install() {
    cd $GAMMA_DIR
    log cyan "install_full_install: Commencing full install"
    ./stalker-gamma*.AppImage full-install > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
}
install_create_gamma_cli_config() {
    cd $GAMMA_DIR
    log cyan "install_create_gamma_cli_config: Making a config in the stalker-gamma-cli"
    ./stalker-gamma*.AppImage config create --anomaly "$ANOMALY_FOLDER" --gamma "$GAMMA_FOLDER" --cache "$CACHE_FOLDER" --download-threads "$DOWNLOAD_THREADS" > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
    log cyan "install_create_gamma_cli_config: done"
}
install_check_stalker_gamma_cli_version() {
    cd $GAMMA_DIR
    log cyan "install_check_stalker_gamma_cli_version: Check version:"
    ./stalker-gamma.AppImage --version > >(tee> >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2) -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
}
install_get_stalker_gamma_cli() {
    cd $GAMMA_DIR

    log cyan "install_get_stalker_gamma_cli: Downloading latest release of stalker-gamma-cli"

    wget $STALKER_GAMMA_CLI_URL -O stalker-gamma.AppImage

    chmod +x stalker-gamma.AppImage > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >&2)
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
    user_chooses
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
    user_chooses
}

greet() {
    log "Stalker GAMMA community install/setup shell scripts"
    log "version: [$SCRIPT_VERSION]"
    log "For ducumentation see:"
    log "https://github.com/ViridiLV/gamma-scripts/"
    log "-------------------------------------------------"
    log "Possible actions:"
    log "[1] - Install game files with stalker-gamma-cli"
    log "[2] - Setup flatpak GAMMA bottle"
    log "[3] - Exit"
    log "-------------------------------------------------"
}
user_chooses() {
    user_input_select=""
    selected=false
    while [ selected==false ]; do
        greet
        log "Please select your action:"
        read -r user_input
        user_input_select="$user_input"
        if [ "$user_input_select" = "1" ]; then
            install_init
            install
            selected=true
        elif [ "$user_input_select" = "2" ]; then
            setup_init
            setup
            selected=true
        elif [ "$user_input_select" = "3" ]; then
            die_exit
        else
            log red "[${user_input_select}] - Not a valid input!"
        fi
    done
}

# ---- Utility functions ----
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

die_exit() {
    log "Exitting due to user input selection - Exit"
    log "Bye!"
    exit 1
}

die() {
    log red "ERROR: $*"
    log "Press any key to close this program."
    read -r user_input && exit 1
}


main() {
    mkdir -p $GAMMA_DIR
    cd $GAMMA_DIR
    # Making sure LOG_FOLDER exists.
    mkdir -p $LOG_FOLDER
    log "Main: script started (${SCRIPT_NAME})"
    user_chooses
    log "Main: unexpected script end. Input anything to exit. \o"
    read -r user_input && exit
}
main "$@"
