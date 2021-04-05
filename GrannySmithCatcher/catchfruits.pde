import processing.serial.*;  // enable reading from Arduino
import processing.sound.*;   // enable sound 

// The code would be cleaner if objects were used. 

// Arduino/potentiometer inputs
Serial port;
float potent1 = 0;
float potent2 = 0;

// Dimensions of catcher/disc
int discw = 80;          
int disch = 20;
float easing = 0.1;  // how smooth does the discs move? (easing)

// Attributes of the discs of the players
int player1X = 0;
int player1Y = 0;
float targetplayer1X = 0;
int pplayer1X = player1X;   // previous x-value of player 1
int player2X = 0;
int player2Y = 0;
float targetplayer2X = 0;
int pplayer2X = player1X;

// Attributes of fruit
int dropped = 0;
float fx = 0;
float fy = 10000;
int fr = 15;
float init_speed = 10;      
float speed = init_speed;  // fall speed
float gravitation = 1.013;
float air = 5;             // noise in x-coordinate

// Timers
float fallTime = 0;            // for how long the fruit has fallen
float maxFallTime = 1;         // maximum fall time
float lwbd = 0.5;              // sample waiting time between gone fruit and fruit dropped uniformly on the given interval
float upbd = 1.5;
float timer = 1000*random(lwbd, upbd);
float lastPressed = millis();  // when a button was last pressed
float pressInterval = 200;
float pausedAt = 0;            // helps calculate pause time

// Scores
int score1 = 0;
int streak1 = 0;
boolean caught1 = false;
int score2 = 0;
int streak2 = 0;
boolean caught2 = false;

// Start menu
boolean started = false;
PFont font;

// Available states
final int START = 0;
final int GAME = 1;
final int PAUSE = 2;
int STATE = START;

// For sound
SoundFile blip;
boolean soundPlayed = false;

void settings(){
  
  fullScreen();
}

void setup() {
  frameRate(200);
  ellipseMode(RADIUS);
  port = new Serial(this, "COM7", 9600);
  port.bufferUntil('\n');
  
  player1X = width/2;
  player1Y = height*5/6;
  
  player2X = width/2;
  player2Y = height*5/6;
  
  font = createFont("SourceCodePro-Regular.ttf", 32);
  textFont(font);
  
  blip = new SoundFile(this, "catch.wav");
}

void draw(){
  background(0);
  float currentTime = millis();
  
  switch(STATE){
    case START:
      textSize(60);
      text("FRUIT CATCHER", width/3+50, height/3);
      textSize(30);
      text("Press SPACE to start game", width/3+62, height/3+50);
      
      if (keyPressed && key == ' '){
        started = true;
        STATE = GAME;
        lastPressed = currentTime;
      } 
      break;
      
    case GAME:  
     // Check if game is paused
     if (keyPressed && key == ' ' && (currentTime - lastPressed) > pressInterval){
       STATE = PAUSE; 
       pausedAt = millis();
        lastPressed = currentTime;
       break;
     }
      
     targetplayer1X = map(potent1, 255, 0, 0, width-discw);
     targetplayer2X = map(potent2, 255, 0, 0, width-discw);
      
     // Determine if fruit should fall and where using random numbers
     if (currentTime > timer && fallTime == 0){  // drop fruit
       fx = random(fr+100, width-fr-100);
       fy = 0;
       fallTime = currentTime;
       caught1 = false;
       caught2 = false;
       dropped++;
       speed = init_speed;
       soundPlayed = false;
     } else if (currentTime - fallTime > maxFallTime*1000 && timer < currentTime) {  // time to restart timer
       timer = currentTime + 1000*random(lwbd, upbd);
       fallTime = 0;
     }  // else fruit is falling
       
       
     // Draw and move fruit
     drawFruit();   
     fx += random(-air, air);  
     fy += speed;   
     speed *= gravitation;
      
     // Calculate new position 
     player1X += (targetplayer1X - pplayer1X) * easing;
     player2X += (targetplayer2X - pplayer2X) * easing;
     
     // Draw discs
     drawDiscs();
     
     // Determine if the fruit is catched or not
     catchHandler1(player1X, player1Y);
     catchHandler2(player2X, player2Y);
     if ((caught1 || caught2)  && !soundPlayed){  
       fy = height + fr;  // make fruit disappear
       blip.play();
       soundPlayed = true;
     }
     
     // Determine if fruit was dropped 
     if ((player1Y + disch) < fy && !caught1){
       streak1 = 0;
     }
     if ((player2Y + disch) < fy && !caught2){
       streak2 = 0;
     }   
     
     displayScores();
     
     // Update previous values
     pplayer1X = player1X;
     pplayer2X = player2X;
     
     break;
     
    case PAUSE:
      drawFruit();
      drawDiscs();
      displayScores();
      
      fill(255, 255, 255);
      textSize(60);
      text("GAME IS PAUSED", width/3+50, height/3);
      textSize(30);
      text("Press SPACE to resume game", width/3+65, height/3+50);  
      
      if (keyPressed && key == ' ' && (currentTime - lastPressed) > pressInterval){
        STATE = GAME;
        float pauseTime = currentTime - pausedAt;
        lastPressed = currentTime;
        
        if (fallTime == 0){  // fruit is not falling
          timer += pauseTime;
        } else {             // fruit is falling
          fallTime += pauseTime;
        }
      }
      
      break;  
    
    default:
      break;
  }
  
  // For debugging
  println("STATE: " + STATE);
  println("Current Time: " + currentTime + "\nLast Pressed:  " + lastPressed + "\nTimer: " + timer + "\nFall Time: " + fallTime + "\n");
  
}

// Draw fruit function
void drawFruit(){
fill(0, 255, 0);
ellipse(fx, fy, fr, fr);  
}

// Draw discs function
void drawDiscs(){
  fill(255, 0, 255);  // magenta
  rect(player1X, player1Y, discw, disch);
  fill(0, 0, 255);    // blue
  rect(player2X, player2Y, discw, disch);
}

// Display scores function
void displayScores(){
fill(255, 0, 255);
   text("Player 2", width-270, 160);
   stroke(255, 0, 255);
   strokeWeight(3);
   line(width-270, 170, width-100, 170);
   text("Score: " + score1, width-270, 200);
   text("Streak: " + streak1, width-270, 225);
   
   fill(0, 0, 255);
   text("Player 1", 100, 160);
   stroke(0, 0, 255);
   strokeWeight(3);
   line(100, 170, 270, 170);
   text("Score: " + score2, 100, 200);
   text("Streak: " + streak2, 100, 225);
   noStroke();
}


// Determine if player1 has caught the fruit given the coordinates of the disc (x,y).
void catchHandler1(float x, float y){
   if ((y-fr <= fy && fy <= y+disch+fr) && (fx >= x-fr && fx <= x+discw+fr) && !caught1) {
     score1++;
     streak1++;
     caught1 = true;
   } 
}

// Determine if player1 has caught the fruit given the coordinates of the disc (x,y).
void catchHandler2(float x, float y){
   if ((y-fr <= fy && fy <= y+disch+fr) && (fx >= x-fr && fx <= x+discw+fr) && !caught2) {
     score2++;
     streak2++;
     caught2 = true;
   } 
}

void serialEvent(Serial port){
  String received = port.readStringUntil('\n');
  float[] vals = float(split(received, ' '));
  potent1 = vals[0];
  potent2 = vals[1];
}
