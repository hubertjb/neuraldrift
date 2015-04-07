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


  void initialDisplay() {
    imageMode(CENTER);
    image(logo, width/2, 435);
  }

  void display() {
    imageMode(CENTER);
    image(logo, width/2, 435);
    imageMode(CORNER);
    image(p1, 10, 0);
    image(p2, 1000, 0);
    fill(255);
  }

  //display calibrations functions
  void displayCalibrations1() {
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

  void displayCalibrations2() {
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

  void displayInitialize() {
    rectMode(CORNER);
    stroke(0);
    fill(0);
    rect(0, 0, 1280, 800); 
    fill(255);
    textFont(myFont);
    textAlign(CENTER, CENTER);
    text("Neural Handshake Initializing...", 640, 300);
  }

  void displayCalibrationsComplete() {
    rectMode(CORNER);
    stroke(0);
    fill(0);
    rect(0, 0, 1280, 800); 
    fill(255);
    textFont(myFont);
    textAlign(CENTER, CENTER);
    text("Neural handshake complete.", 640, 300);
  }
  void displayCalibrationsError() {
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

