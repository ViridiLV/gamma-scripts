# S.T.A.L.K.E.R G.A.M.M.A Community Linux Install/Setup shell scripts

Community made scripts made to semi-automatically install gamma and  set up a bottle to play the game on Linux systems.

Includes a step-by-step guide.

# Guide
## Step 0 - obtaining dependencies to run the scripts

For scripts to work need libraries/packages that it uses.

- **For Ubuntu/Debian systems:**
```
apt install flatpak wget tar
```

For Others... *to be included*

## Step 1 - getting the scripts

Scripts are maintained in a rolling release manner, meaning you get them straight from the github repo.
Version numbers inside the scripts are informative for troubleshooting logs.

- **1.1** Open a terminal instance in the main directory where your gamma and anomaly files will be.

  Then make a folder and `cd` into it in your terminal.

  For example:
  ```
  cd /home/$USER/Games/GAMMA
  ```
- **1.2.** Download the script file:

```
wget https://raw.githubusercontent.com/ViridiLV/gamma-scripts/refs/heads/main/gamma-scripts.sh
```

- **1.3.** Make it executable(this is optional if you choose to execute from already open terminal)

```
chmod -x gamma-scripts.sh
```
- **1.4.** Run the script

  - **a)** 
  ```
  bash gamma-scripts.sh
  ```
  - **b)** via "Open in  terminal" of your distro's GUI file manager right click/open menu
    
## Step 2 - Installing the game

 - **INSTALL** - to install the game, type in the number that corresponds the option "Install game", then press Enter.

  The script will download latest release from [https://github.com/FaithBeam/stalker-gamma-cli] 
  
  After that the script will proceed to install the game using it. 
## Step 3 - Set up the game

Step 2 only lets you obtain game files, as if you installed the game on Windows, however this does not enable you to play GAMMA on Linux.
To play GAMMA on Linux you need to set up a working wine/proton compability layer with the needed dependencies.

This process often brings in a lot of user error and difficulty for newcomers.

The setup script aims to streamline this  process by scripting the set up of flatpak Bottles and making a bottle with dependencies for you with as little amount of user input as possible.

3.1 With the script open and idle, type in the number that corresponds the option "setup GAMMA", then press Enter.

3.2 If you don't have flatpak bottles installed, the script will attempt to install flatpak bottles.

It will ask permission to do so, simply type y and hit enter to allow the installation of Bottles.

3.3.If Bottles does not have filesystem=host access, it may prompt you to input sudo password. 

Not having acess to files game files may cause missing QT.dll errors later.

3.4 Then, if the bottles just got installed and was not installed and set up previously, the script will prompt you to open Bottles and complete initial setup.

Once done, press X to close bottles, then select the script terminal window and enter anything to continue

3.5 When prompted, press ok on the small pop up screens.

You may have a couple of small pop up windows saying ".dll registered succesfully".

Simply press OK, or hit enter to continue.

3.6. The script will return to the action selection screen, at this point the bottle is set up and you can launch ModOrganizer from the StalkerGAMMA bottle in bottles to start playing the game.

## Step 4 - Troubleshooting

The `logs` folder contains a log file of the terminal output.

***Work in progress***
