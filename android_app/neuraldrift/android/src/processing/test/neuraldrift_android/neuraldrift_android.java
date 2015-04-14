package processing.test.neuraldrift_android;

import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import android.content.Intent; 
import android.os.Bundle; 
import ketai.net.bluetooth.*; 
import ketai.ui.*; 
import ketai.net.*; 
import processing.core.*; 
import processing.data.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class neuraldrift_android extends PApplet {

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

public void onCreate(Bundle savedInstanceState) {
  super.onCreate(savedInstanceState);
  bt = new KetaiBluetooth(this);
}

public void onActivityResult(int requestCode, int resultCode, Intent data) {
  bt.onActivityResult(requestCode, resultCode, data);
}

public void setup() {
 
  frameRate(30);
  orientation(LANDSCAPE);
  background(0);

  //start listening for BT connections
  bt.start();
  //at app start select device\u2026
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

public void draw() {
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

public void onKetaiListSelection(KetaiList klist) {
  String selection = klist.getSelection();
  bt.connectToDeviceByName(selection);
  //dispose of list for now
  klist = null;
}

//Call back method to manage data received
public void onBluetoothDataEvent(String who, byte[] data) {
  if (isConfiguring)
    return;
  println("Byte received");
  println(PApplet.parseInt(data[0]));
  if (PApplet.parseInt(data[0])>=187)
  {
    if (PApplet.parseInt(data[0]) == 187) //0xBB = Standby
    {
      screenDisplay = 0;
    }
    if (PApplet.parseInt(data[0]) == 204) //0xCC = Phase1
    {
      screenDisplay = 1;
    }
    if (PApplet.parseInt(data[0]) == 221) //0xDD = Phase2
    {
      screenDisplay = 2;
    }
    if (PApplet.parseInt(data[0]) == 238) //0xEE = Training
    {
      screenDisplay = 3;
    }
    if (PApplet.parseInt(data[0]) == 255) //0xFF = Game
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
    p1DataIn = 10*(PApplet.parseInt(unbinary(stringPower.substring(0, 4))));
    // The high nibble is the power for Player 2 form 0 to 10
    p2DataIn = 10*(PApplet.parseInt(unbinary(stringPower.substring(4, 8))));
    println(p1DataIn);
    println(p2DataIn);
  }
}

public void players() {
// calculate the result as : input data/ maximum possible data (it will take values between 0 and 1)
  p1Result = PApplet.parseFloat(p1DataIn)/maxValue;
  p2Result = PApplet.parseFloat(p2DataIn)/maxValue;
// update the player UI; return the result of input data/max data
  player1.updateFloat(p1Result);
  player2.updateFloat(p2Result);
// display the updated UI
  player1.display(); 
  player2.display();
}

//graphics; everything that is not interactive/essential but pretty 
class graphics {

  //variables


    PImage logo;
  PImage p1;
  PImage p2;
  PFont myFont; 


  //constructor
  graphics() {


    myFont = createFont("Exo-Medium", 90, true);
    logo = loadImage("logo.png");
    p1 = loadImage("p1.png");
    p2 = loadImage("p2.png");
  }


  public void initialDisplay() {
    imageMode(CENTER);
    image(logo, width/2, 435);
  }

  public void display() {
    imageMode(CENTER);
    image(logo, width/2, 435);
    imageMode(CORNER);
    image(p1, 10, 0);
    image(p2, 1000, 0);
    fill(255);
  }

  //display calibrations functions
  public void displayCalibrations1() {
    rectMode(CORNER);
    stroke(0);
    fill(0);
    rect(0, 0, 1280, 800); 
    fill(255);
    textFont(myFont);
    textAlign(CENTER, CENTER);
    text("Brain-computer Interface", 640, 300);
    text("Calibration phase 1", 640, 400);
  }

  public void displayCalibrations2() {
    rectMode(CORNER);
    stroke(0);
    fill(0);
    rect(0, 0, 1280, 800); 
    fill(255);
    textFont(myFont);
    textAlign(CENTER, CENTER);
    text("Brain-computer Interface", 640, 300);
    text("Calibration phase 2", 640, 400);
  }

  public void displayInitialize() {
    rectMode(CORNER);
    stroke(0);
    fill(0);
    rect(0, 0, 1280, 800); 
    fill(255);
    textFont(myFont);
    textAlign(CENTER, CENTER);
    text("Neural Handshake Initializing...", 640, 300);
  }

  public void displayCalibrationsComplete() {
    rectMode(CORNER);
    stroke(0);
    fill(0);
    rect(0, 0, 1280, 800); 
    fill(255);
    textFont(myFont);
    textAlign(CENTER, CENTER);
    text("Neural handshake complete.", 640, 300);
  }
  public void displayCalibrationsError() {
    rectMode(CORNER);
    stroke(0);
    fill(0);
    rect(0, 0, 1280, 800); 
    fill(255);
    textFont(myFont);
    textAlign(CENTER, CENTER);
    text("Calibration Error.", 640, 300);
    text("Please try again.", 640, 400);
  }
}

//Player UI

class PlayerUI {

  //variables
  //the bar itself
  int barX; 
  int barY; 
  int barWidth; 
  int barHeight;

  int barWeight = 5;

  //bar inputs
  float inputHeight;

  //colors
  int fillA = color(255, 200, 0);
  int fillB = color(0, 200, 255);
  int fillC;

  //constructor

  PlayerUI(int tempX, int tempY, float tempWidth, float tempHeight) {

    barX = tempX;
    barY = tempY;
    barWidth = round(tempWidth);
    barHeight = round(tempHeight);
  }





  //update
  //make sure that tempInput is float between 0 and 1
  public void updateFloat(float tempInput) {

    inputHeight = (1-tempInput) * barHeight ; 


    fillC = lerpColor(fillB, fillA, tempInput);
  }

  //update if using integers
  public void updateInt(int tempInput) {
    inputHeight = (tempInput/100) * barHeight;

    fillC = lerpColor(fillB, fillA, tempInput/100);
  }

  //display

  public void display() {


    noStroke();
    fill(fillC);
    rect(barX, barY, barWidth, barHeight);

    fill(0);
    rect(barX, barY, barWidth, inputHeight);

    //bar outline
    stroke(255);
    strokeWeight(barWeight);
    noFill(); 
    rect(barX, barY, barWidth, barHeight);
  }
}


  public int sketchWidth() { return displayWidth; }
  public int sketchHeight() { return displayHeight; }
}
