# neuralDrift application for android

This guide indicates the steps to setup your system to generate Android apps using processing. While the instructions here assume that that you are working in a PC with Windows (8.1) 64-bit, and an Android device >= 2.3.3 instructions for Mac and Linux users can be found in links of the [Reference](#foo) section of this document. The setup is divided in [PC setup](#pC setup) and [Phone/Table setup](#android device setup).

## PC setup

1. Download processing Windows 64-bit: <br/>
https://processing.org/download/

2. Download the latest release of the Android SDK Tools
SDK Tools Release Notes: <br/>
http://developer.android.com/tools/sdk/tools-notes.html <br/>
Download links (In the SDK Tools Only section):<br/>
http://developer.android.com/sdk/index.html

3. Run Android SDK Manager and select the following packages:
  * Tools > Android SDK Tools
  *	Tools > Android SDK Platform-tools
  *	Android 2.3.3 (API 10) > SDK Platform
  *	Extras > Android Support Repository
  *	Extras > Google USB Driver
  <br/><br/>
4. Run Processing, add Android Mode for Processing

5. Restart Processing

6. Change to Android Mode

7. Select the location of the Android SDK (You can see it in the Android SDK Manager window)

8. For Bluetooth connectivity, add the [Ketai Library](https://code.google.com/p/ketai/) to Processing:<br/> Open Processing, go to Sketch > Import Library > Add Library and select Ketai, install it and restart Processing

##	Android device
1.	Turn on "USB Debugging" on your device - this process varies by device and which version of the OS you have installed. Try one of the following:
•	Menu → Applications → Development, then enable USB debugging
•	On the Nexus tablets, Settings → About tablet, then click on the Build number seven times to activate USB debugging.
2.	If you are running Windows or Linux, you need to read Google's Using Hardware Devices documentation to install a special USB driver and take care of additional settings.
3.	Test

1.	Connect your Android device to the PC
2.	Create a new sketch in Processing:
void setup(){
size(400,400);
}

void draw(){
fill(0,255,0);
rect(mouseX,mousey,50,50);
}

3.	Click in the Run button in the Processing
4.	Extra information

Processing-Android
https://github.com/processing/processing-android/wiki

Android SDK
http://developer.android.com/sdk/index.html

# This is a <H1> cosa_tag
