/* 
 VERY IMPORTANT:
 Set bluetooth, bluetooth admin and internet sketch permissions in processing.
 
 Processing Code:
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
boolean bReleased = true; //no permament sending when finger is tap
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


  //at app start select device
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
      //send with BT
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

    if (screenDisplay == 0)
    {
      dontTouchMe.initialDisplay();
    }
    else if (screenDisplay == 1)
    {
      dontTouchMe.displayCalibrations1();
    }
    else if (screenDisplay == 2)
    {
      dontTouchMe.displayCalibrations2();
    } 
    else if (screenDisplay == 3)
    {
      dontTouchMe.displayInitialize();
    }  

    else if (screenDisplay == 4)
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
    if (int(data[0]) == 187)
    {
      screenDisplay = 0;
    }
    if (int(data[0]) == 204)
    {
      screenDisplay = 1;
    }
    if (int(data[0]) == 221)
    {
      screenDisplay = 2;
    }
    if (int(data[0]) == 238)
    {
      screenDisplay = 3;
    }
    if (int(data[0]) == 255)
    {
      screenDisplay = 4;
    }
  } 
  else
  {   
    powerBoth = data[0];
    stringPower = binary(powerBoth);

    p1DataIn = 10*(int(unbinary(stringPower.substring(0, 4))));
    p2DataIn = 10*(int(unbinary(stringPower.substring(4, 8))));
    println(p1DataIn);
    println(p2DataIn);
  }
}

void players() {
  //if the server is available
  //if (myClient.available() > 0 ) {
  if (true) {
    //read data 4 times for P1
    //    p1DataIn = myClient.read();
    //    println(p1DataIn);
    //    p1DataIn = myClient.read();
    //    println(p1DataIn);
    //    p1DataIn = myClient.read();
    //    println(p1DataIn);
    //    p1DataIn = myClient.read();
    //    println(p1DataIn);
    //    p1DataIn = 80;

    //P2's turn to get read data 4 times
    //    p2DataIn = myClient.read();
    //    println(p2DataIn);
    //    p2DataIn = myClient.read();
    //    println(p2DataIn);
    //    p2DataIn = myClient.read();
    //    println(p2DataIn);
    //    p2DataIn = myClient.read();
    //    println(p2DataIn);
    //    p2DataIn = 50;
  } 
  else {
    //if nothing is found, return whatever previous result has been found
    //and if nothing is ever found then the result will remain as 0.
    p1Result = prevResult1;
    p2Result = prevResult2;
  }

  //P1 CALCULATIONS AND REFRESH STUFF   
  //convert the found data into a float  
  float(p1DataIn);

  if (float(p1DataIn) < maxValue) //if the data found is lower than the max possible value
  {
    //calculate the result as : input data/ maximum possible data
    p1Result = float(p1DataIn)/maxValue;
  } 
  else
  {
    //if it's equal or larger than the max value, return Result as 1.
    p1Result = 1;
  }

  //update the player UI; return the result of input data/max data
  player1.updateFloat(p1Result);

  //if sending int between 1 and 100
  //player1.updateInt(p1Result);

  //display the updated UI
  player1.display();

  //the current result will be the Previous Result next time this program loops.
  prevResult1 = p1Result;

  //P2 STUFF
  // exactly the same as P1's UI refreshing/calculating operations.
  float(p2DataIn);
  if (float(p2DataIn) < maxValue) {
    p2Result = float(p2DataIn)/maxValue;
  } 
  else {
    p2Result = 1;
  }


  player2.updateFloat(p2Result);
  //if sending int between 1 and 100
  //player2.updateInt(p2Result);

  player2.display();

  prevResult2 = p2Result;

  //println(p1DataIn, p2DataIn);
}

