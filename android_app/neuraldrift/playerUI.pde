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
  color fillA = color(255, 200, 0);
  color fillB = color(0, 200, 255);
  color fillC;

  //constructor

  PlayerUI(int tempX, int tempY, float tempWidth, float tempHeight) {

    barX = tempX;
    barY = tempY;
    barWidth = round(tempWidth);
    barHeight = round(tempHeight);
  }





  //update
  //make sure that tempInput is float between 0 and 1
  void updateFloat(float tempInput) {

    inputHeight = (1-tempInput) * barHeight ; 


    fillC = lerpColor(fillB, fillA, tempInput);
  }

  //update if using integers
  void updateInt(int tempInput) {
    inputHeight = (tempInput/100) * barHeight;

    fillC = lerpColor(fillB, fillA, tempInput/100);
  }

  //display

  void display() {


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

