# neuralDrift

neuralDrift is a collaborative multiplayer neurogame based on brain-computer interfaces.

## Description
[Pacific Rim](http://en.wikipedia.org/wiki/Pacific_Rim_%28film%29)
showed how two pilots can *drift* together in a Jeager robot to combat Kaiju giant monsters.
Inspired by this collaborative mind control technology, neuralDrift lets two players control
a motorized robot by syncing their brain waves. The project was completed during [WearHacks 2014](http://www.wearhacks.com/)
(the first hackathon on wearables to be held in North America) under 36 hours.

The game consists of a LEGO&copy; MINDSTORMS&copy; EV3 robot, an Android device displaying the game state, and requires two EEG devices supported by [MuLES](https://github.com/MuSAELab/MuLES). Only Windows operating systems are currently supported.


## Installation

### 1. Download project

You can either download the zip file of the project and extract it, or clone the repository.

### 2. Download and install dependencies:

- MATLAB (tested with R2013a) with the Instrument Control Toolbox
- [MuLES](https://github.com/MuSAELab/MuLES)
	* Follow the installation instructions for configuring specific EEG devices (i.e., installing SDKs and pairing devices with Bluetooth).
- [QUT EV3 MATLAB toolkit](https://code.google.com/p/matlab-toolboxes-robotics-vision/source/browse/#svn%2Fmatlab%2Frobot%2Ftrunk)
	* Put the folder **EV3** in **neuraldrift\scripts\**.
- Install the app **neuralDrift** in your Android device provided in **neuraldrift\android_app\**
	- Enable the option [**Unknown source**](http://www.cnet.com/how-to/how-to-install-apps-outside-of-google-play/) in your device
	- Copy the apk file onto your device
	- Use a file manager to locate the apk file and install it
		- Note. Alternatively, **the neuralDrift** Android app can be compiled using Processing, see **readme.md** in **neuraldrift\android_app\neuralDrift\** for instructions.


## Usage

1. Pair your Android device with the PC (Only for the first time).
2. Launch the **neuralDrift** Android app on your Android device.
3. Power on the EEG devices and set them on the 2 players.
4. Open the **main_neuraldrift.m** script and change default parameters if needed (Android device name, player names, feature extraction parameters, MATLAB path, etc.)
5. Make sure MATLAB's current folder is **neuraldrift\scripts**, then launch **main_neuraldrift()**.
6. Follow the training procedure and start drifting!
7. Various commands (make sure to be focused on Figure 1 before using the commands):
	* Start the game <s>
	* Turn robot motors ON/OFF: <SPACE>
	* Restart game: <r>
	* Escape game: <Esc>
	* Print information system state: <n>


## License

neuralDrift is licensed under the [MIT License](LICENSE.txt).

## About us

[Team members](http://neuraldrift.net/?page_id=12).
