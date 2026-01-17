# S.T.A.L.K.E.R G.A.M.M.A Community Linux Install/Setup shell scripts

Community made scripts made to semi-automatically install gamma and  set up a bottle to play the game on Linux systems.

Includes a step-by-step guide.

# Guide
## Step 0 - obtaining dependencies to run the scripts

For scripts to work need libraries/packages that it uses.

For Ubuntu/Debian systems:
```
apt install flatpak wget tar fq findutils
```

For Others... *to be included*
## Step 1 - getting the scripts

Scripts are maintained in a rolling release manner, meaning you get them straight from the github repo.
Version numbers inside the scripts are informative for troubleshooting logs.

1.1 Open a terminal instance in the main directory where your gamma and anomaly files will be.

Make a folder and `cd` into it in your terminal.

For example:
```
cd /home/$USER/Games/GAMMA
```
1.2. Download the script file:

```
wget https://raw.githubusercontent.com/ViridiLV/gamma-scripts/refs/heads/main/gamma-scripts.sh
```

1.3. Make it executable(optional if you choose to execute from already open terminal)

```
chmod -x gamma-scripts.sh
```
1.4. Run the script
 a) 
 ```
 bash gamma-scripts.sh
 ```
 b) via "Open in  terminal" of your distro's GUI file manager right click/open menu
## Step 2 - Installing the game

 - **INSTALL** - to install the game, type in the number that corresponds the option "Install game" in the terminal output of the `gamma-scipts.sh`, then press Enter.

  The script will download latest release from [[github.com/Mord3rca/gamma-launcher]([https://github.com/FaithBeam/stalker-gamma-cli] and automatically proceed with the installation of game files.


***Work in progress***
