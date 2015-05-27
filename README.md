# neuralDrift v2.0

**neuralDrift** is a collaborative multiplayer neurogame based on brain-computer interfaces.

## Description

Inspired by the movie [Pacific Rim](http://en.wikipedia.org/wiki/Pacific_Rim_%28film%29),
in which collaborative mind control technology allows the use of futuristic giant robots,
the game lets two players – Jaeger pilots – control a robot by syncing their brain waves.
The project was completed under 36 hours during [WearHacks 2014](http://www.wearhacks.com/),
the first wearables hackathon to be held in North America. 

The game consists in a LEGO&copy; MINDSTORMS&copy; EV3 robot, an Android device displaying the game state, and requires two EEG devices supported by [MuLES](https://github.com/MuSAELab/MuLES).


## Installation

### 1. Download project

You can either download the zip file of the project and extract it, or clone the git.

### 2. Download and install dependencies:

- MATLAB (tested with R2013a) with the Instrument Control Toolbox
- [MuLES](https://github.com/MuSAELab/MuLES)
	* Follow the installation instructions for configuring specific EEG devices (i.e., installing SDKs and pairing devices with Bluetooth).
- [QUT EV3 MATLAB toolkit](https://code.google.com/p/matlab-toolboxes-robotics-vision/source/browse/#svn%2Fmatlab%2Frobot%2Ftrunk)
	* Put the folder ```EV3``` in ```/neuralDrift/scripts```.
- Compile Processing code/Install executable on Android device

## Usage

1. Launch the **neuralDrift** Android app on your Android device.
2. Power on the EEG devices and set them on the 2 players.
3. Open the **main_neuraldrift.m** script and change default parameters if needed (Android device name, player names, feature extraction parameters, MATLAB path, etc.)
4. Make sure MATLAB's current folder is ```neuraldrift/scripts```, then launch ```main_neuraldrift()```.
5. Follow the training procedure and start drifting!
6. Various commands (make sure to be focused on Figure 1 before using the commands):
	* Turn robot motors ON/OFF: <SPACE>
	* Restart game: <r>
	* Escape game: <Esc>
	* Print information system state: <n>

## License

neuralDrift is licensed under the [GPLv2 license](LICENSE.md).

## About us

[Team members](http://neuraldrift.net/?page_id=12).
