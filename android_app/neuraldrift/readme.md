# neuralDrift application for Android

This guide indicates the steps to setup your system to compile the neuralDrift Android application, which was written using [Processing](https://processing.org/). The instructions here assume that you are working in a PC with Windows 8.1 64-bit version and an Android device >= 2.3.3. Instructions for Mac and Linux users can be found in links of the [More Information](#more-information) section of this document. The setup is divided in [Android Device Setup](#android-device-setup) (Smartphone or Tablet), and [PC Setup](#pc-setup).

##	Android Device Setup
1. Turn on **"USB Debugging"** on your device - this process varies by device and which version of Android you have. Try one of the following methods:
  *	Menu > Applications > Development, then enable USB debugging
  * On the Nexus tablets, Settings > About tablet, then click on the Build number seven times to activate USB debugging.

## PC Setup

1. Download Processing version 2.2.1 for Windows 64-bit: <br/>
https://processing.org/download/

2. Download the latest release of the Android SDK Tools (**In the SDK Tools Only** section) <br/>
http://developer.android.com/sdk/index.html <br/>

3. Run Android SDK Manager, select and install the following packages:
  * Tools > Android SDK Tools
  *	Tools > Android SDK Platform-tools
  * Tools > Android SDK Build-tools
  *	Android 2.3.3 (API 10) > SDK Platform
  *	Extras > Android Support Library
  *	Extras > Google USB Driver
  <br/><br/>

4. Install the drivers to run ADB in our device, instructions for each device change
http://developer.android.com/tools/extras/oem-usb.html#InstallingDriver

5. Download and Install the JDK 8 (lates releasse) x86 version </br> http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html

6. Add your Java bin folder to the System Variable "Path". Java bin folder is usually located at: ``` C:\Program Files (x86)\Java\jdk1.8.0_05\bin ```

7. Download the file AndroidMode.zip from the latest Processing Android Release: </br>
  https://github.com/processing/processing-android/releases

8. Run Processing and locate the Sketchbook folder (Go File > Preferences), then copy the Folder ```AndroidMode``` to the ```modes``` folder located in your Sketchbook.

9. Restart Processing

10. In Processing, change mode to Android Mode:  https://processing.org/reference/environment/#Programming_modes
Select the location of the Android SDK</br> (You can see path in the Android SDK Manager window)

11. To enable Bluetooth connectivity, add the Ketai Library to Processing:<br/> Open Processing, go to Sketch > Import Library > Add Library and select Ketai, install it and restart Processing

##	Test the Setup

After configuring the Android device and your PC following the instructions in the previous sections, you will be able to generate an Android app using a Sketch created in Processing.

1.	Connect your Android device to the PC
2.	Create a new sketch in Processing:
  ``` java
  void setup(){
  size(400,400);
  }

  void draw(){
  fill(0,255,0);
  rect(mouseX,mouseY,50,50);
  }
  ```
3. Click Sketch> Run on Device
4. Once the application starts in your Android device, touch the screen of your Android device
5. A green square will be drawn in every point in the screen where your finger is present.

## Compiling neuralDrift App

1. Open neuraldrift.pde
3. Click Skets, Run Device

## More Information

Processing-Android<br/>
https://github.com/processing/processing-android/wiki

Android SDK<br/>
http://developer.android.com/sdk/index.html </br>
http://developer.android.com/sdk/installing/index.html?pkg=tools <br/>
http://developer.android.com/tools/sdk/tools-notes.html

Ketai Library<br/>
https://code.google.com/p/ketai/
