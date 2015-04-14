/* 
 VERY IMPORTANT:
 Set bluetooth, bluetooth admin and internet sketch permissions in processing.

*/
//
/* This code presents the Graphic User Interface utilized for the 
project neuralDrift (http://neuraldrift.net/)
Commands are sent from a PC via Bluetooth, and they control the 
phase shown (Standby, Phase1, Phase2, Training and Game) as well as the 
level of the bar indicators during the Game phase.

The size of the elements considers the screen size and resolution of the original (2012) Nexus 7,
(http://en.wikipedia.org/wiki/Nexus_7_%282012_version%29). 
7 in, 8:5 aspect ratio, and  1280 x 800 pixels 
*/

//required for BT enabling on startup

import android.content.Intent;
import android.os.Bundle;
import ketai.net.bluetooth.*;
import ketai.ui.*;
import ketai.net.*;
import processing.core.*;
import processing.data.*;


PFont fontMy;
boolean bReleased = true; // Flag to send only data only during the first finger tap
KetaiBluetooth bt;
boolean isConfiguring = true;
KetaiList klist;
ArrayList devicesDiscovered = new ArrayList();
int indexDatum = 1;
int screenDisplay = 0;

//Global variables Ana
graphics dontTouchMe; //everything needed to make it pretty.

//data inputs
int p1DataIn;
int p2DataIn;

int maxValue = 100;

//UI results to be returned to playerUI class.
// as the UI needs a float between 0 and 1,
// uiResult = uiDataIn/maxValue
float p1Result;
float p2Result;

//the previous result, as Processing perpetually loops.
float prevResult1;
float prevResult2;

//byte auxiliar
byte powerBoth;
String stringPower = null;

//Player UI's
PlayerUI player1;
PlayerUI player2;


//********************************************************************
// The following code is required to enable bluetooth at startup.
//********************************************************************

void onCreate(Bundle savedInstanceState) {
  super.onCreate(savedInstanceState);
  bt = new KetaiBluetooth(this);
}

void onActivityResult(int requestCode, int resultCode, Intent data) {
  bt.onActivityResult(requestCode, resultCode, data);
}

void setup() {
  size(displayWidth, displayHeight);
  frameRate(30);
  orientation(LANDSCAPE);
  background(0);

  //start listening for BT connections
  bt.start();
  //at app start select device…
  isConfiguring = true;
  //font size
  fontMy = createFont("SansSerif", 40);
  textFont(fontMy);

  //a default, initial prevResult to avoid any exceptions/errors
  prevResult1 = 0;
  prevResult2 = 0;

  //call UI's
  player1 = new PlayerUI(140, 200, 100, 520);
  player2 = new PlayerUI(1050, 200, 100, 520);

  //call graphics
  dontTouchMe = new graphics();
}

void draw() {
  /*
  calibration graphic functions
   
   an initial loading sequence:
   dontTouchMe.initialDisplay();
   
   if  whatever command for calibrations phase 1
   dontTouchMe.displayCalibrations1();
   
   if  whatever command for calibrations phase 2
   dontTouchMe.displayCalibrations2();
   
   if  whatever command for calibrations phase 3
   dontTouchMe.displayInitialize();
   
   if  whatever command for calibrations being complete
   dontTouchMe.displayCalibrationsComplete();
   
   if  whatever command for calibrations error
   dontTouchMe.displayCalibrationsError();
   
   */


  // At app start select device (PC that will send the Control Commands)
  if (isConfiguring)
  {
    ArrayList names;
    background(78, 93, 75);
    klist = new KetaiList(this, bt.getPairedDeviceNames());
    isConfiguring = false;
    println("isConfiguring = 1");
  }
  else
  {

    background(0, 0, 0);
    if ((mousePressed) && (bReleased == true))
    {
      //send data with BT
      byte[] data = {
        'N', 'e', 'u', 'r', 'a', 'l', ' ', 'D', 'r', 'i', 'f', 't', '\r'
      };
      bt.broadcast(data);
      //first tap off to send next message
      bReleased = false;
      println("isConfiguring = 0");
    }
    if (mousePressed == false)
    {
      bReleased = true; //finger is up
    }

    if (screenDisplay == 0) // Standby = Initial loading sequence
    {
      dontTouchMe.initialDisplay();
    }
    else if (screenDisplay == 1) // Phase1 = Calibration phase 1 
    {
      dontTouchMe.displayCalibrations1();
    }
    else if (screenDisplay == 2) // Phase2 = Calibration phase 2 
    {
      dontTouchMe.displayCalibrations2();
    } 
    else if (screenDisplay == 3) // Training = PC trains the classifier 
    {
      dontTouchMe.displayInitialize();
    }  
    else if (screenDisplay == 4) // Game
    {
      //display the graphics
      dontTouchMe.display();
      //custom function to display and update playerUI functions
      players();
    }
  }
}

void onKetaiListSelection(KetaiList klist) {
  String selection = klist.getSelection();
  bt.connectToDeviceByName(selection);
  //dispose of list for now
  klist = null;
}

//Call back method to manage data received
void onBluetoothDataEvent(String who, byte[] data) {
  if (isConfiguring)
    return;
  println("Byte received");
  println(int(data[0]));
  if (int(data[0])>=187)
  {
    if (int(data[0]) == 187) //0xBB = Standby
    {
      screenDisplay = 0;
    }
    if (int(data[0]) == 204) //0xCC = Phase1
    {
      screenDisplay = 1;
    }
    if (int(data[0]) == 221) //0xDD = Phase2
    {
      screenDisplay = 2;
    }
    if (int(data[0]) == 238) //0xEE = Training
    {
      screenDisplay = 3;
    }
    if (int(data[0]) == 255) //0xFF = Game
    {
      screenDisplay = 4;
    }
  } 
  else // If the byte received is different to 0xBB, 0xCC, 0xDD, 0xEE, or 0xFF, the byte
       // contains information about the power level of each player
  {   
    powerBoth = data[0];
    stringPower = binary(powerBoth);
    // The low nibble is the power for Player 1 form 0 to 10
    p1DataIn = 10*(int(unbinary(stringPower.substring(0, 4))));
    // The high nibble is the power for Player 2 form 0 to 10
    p2DataIn = 10*(int(unbinary(stringPower.substring(4, 8))));
    println(p1DataIn);
    println(p2DataIn);
  }
}

void players() {
// calculate the result as : input data/ maximum possible data (it will take values between 0 and 1)
  p1Result = float(p1DataIn)/maxValue;
  p2Result = float(p2DataIn)/maxValue;
// update the player UI; return the result of input data/max data
  player1.updateFloat(p1Result);
  player2.updateFloat(p2Result);
// display the updated UI
  player1.display(); 
  player2.display();
}

