import processing.serial.*;  // enable reading from Arduino
import processing.sound.*;   // enable sound 

// Arduino/potentiometer inputs
Serial port;
float potent1 = 0;
float potent2 = 0;

// Dimensions of catcher/disc
final int discw = 80;          
final int disch = 20;
final float easing = 0.1;  // how smooth does the discs move? (easing)

// Add basket SVG
PShape basket;

// Add background
PImage garden;

// Extra variables for controlling movement if the discs
float targetplayer1X = 0;
float pplayer1X = 0;   // previous x-value of player 1
float targetplayer2X = 0;
float pplayer2X = 0;

float gravitation = 1.02;

// Timers
float lwbd = 1000*0.05;              // sample dropDelay time uniformly on the given interval
float upbd = 1000*0.7;
float timer = 0;
float dropDelay = 0;           // this will be decided at random as mentioned above
float lastPressed = millis();  // when a button was last pressed
float pressInterval = 150;
float pausedAt = 0;            // helps calculate pause time

PFont font;

// Available states
final int START = 0;
final int GAME = 1;
final int PAUSE = 2;
int STATE = START;

// For sound
SoundFile blip;
boolean soundPlayed = false;

// Declare players
Player player1;
Player player2;

// Declare fruits
final int fruitRadius = 15;
ArrayList<Fruit> fruits;  // handles the fruits
int fallingFruit = 0;     // index of falling fruit

void setup() {
  size(1399, 788);
  ellipseMode(RADIUS);
  frameRate(200);
  port = new Serial(this, Serial.list()[0], 9600);
  port.bufferUntil('\n');
  
  // Initialize players
  Disc disc1 = new Disc(width/2, height*5/6, discw, disch, 255, 0, 255);
  Disc disc2 = new Disc(width/2, height*5/6, discw, disch, 0, 0, 255);
  player1 = new Player(1, 0, 0, disc1);
  player2 = new Player(2, 0, 0, disc2);
  
  fruits = new ArrayList<Fruit>();
  
  font = createFont("SourceCodePro-Regular.ttf", 32);
  textFont(font);
  
  blip = new SoundFile(this, "catch.wav");
  
  basket = loadShape("basket.svg");
  shapeMode(CENTER);
  
  garden = loadImage("garden.jpg");
}

void draw(){
  background(garden);
  float currentTime = millis();
  
  println("Pot1: " + potent1 + ", Pot2: " + potent2);
  
  switch(STATE){
    case START:
      fill(0,100,0);
      textSize(60);
      text("GRANNY SMITH CATCHER", width/3-100, height/3);
      textSize(30);
      text("Press SPACE to start game", width/3, height/3+50);
      
      if (keyPressed && key == ' '){
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
      
     // Calculate player movements 
     targetplayer1X = map(potent1, 255, 0, 0, width-discw);
     targetplayer2X = map(potent2, 255, 0, 0, width-discw);
      
     // Determine if fruit should fall and where if so, using random numbers
     if (currentTime - timer > dropDelay){  // drop fruit
     
       // Determine which fruit to drop
       Fruit newFruit;
       float u = random(1);
       if (u < 0.333){
         newFruit = new Fruit(0, 0, fruitRadius, 0, 255, 0, 4, "apple");  // drop green apple
       } else if (0.333 <= u && u < 0.667) {
         newFruit = new Fruit(0, 0, fruitRadius, 255, 0, 0, 6, "red apple");  // drop red apple
       } else {
         newFruit = new Fruit(0, 0, fruitRadius, 255, 165, 0, 8, "orange");  // drop orange
       }
       
       newFruit.xPos = random(290, width-290);
       newFruit.yPos = 0;
       fruits.add(newFruit);
       
       //speed = init_speed;
       soundPlayed = false;
       
       // Decide when to drop next fruit
       dropDelay = getDropDelay();
       timer = currentTime + dropDelay;
     }       
       
     // Draw and move fruit
     for (Fruit f : fruits) {
       f.drawFruit();
       f.yPos += f.fallSpeed;
     }
      
     // Calculate new position 
     player1.disc.xPos += (targetplayer1X - pplayer1X) * easing;
     player2.disc.xPos += (targetplayer2X - pplayer2X) * easing;
     
     // Draw discs
     player1.drawPlayerDisc();
     player2.drawPlayerDisc();
     
     // Draw point description
     drawPoinDescription();
     
     // Determine if the fruit is caught or not
     ArrayList<Fruit> toBeRemoved = new ArrayList<Fruit>();
     for (Fruit f : fruits) {
       catchHandler(player1, f);
       catchHandler(player2, f);
       if (player1.caught.contains(f) || player2.caught.contains(f)){  
         toBeRemoved.add(f);  // fruits that are to be removed
         blip.play();
         soundPlayed = true;
       }
     }
     
     // Remove caught fruit
     fruits.removeAll(toBeRemoved);
     
     // Determine if fruit was dropped in order to determine the player streaks
     for (Fruit f : toBeRemoved) {  // one of the players did not catch the fruit
       if (!player1.caught.contains(f)) {
         player1.streak = 0;
       }
       if (!player2.caught.contains(f)) {
         player2.streak = 0;
       }
     }
     for (Fruit f : fruits) {  // both players missed the fruit
      if (f.yPos > height*5/6 + disch) {
        player1.streak = 0;
        player2.streak = 0;
      }
     }
     
     // Remove fruit that has fallen to far
     ArrayList<Fruit> fallenToFar = new ArrayList<Fruit>();
     for (Fruit f : fruits) {
       if (f.yPos > height+fruitRadius) {
         fallenToFar.add(f);
       }
     }
     fruits.removeAll(fallenToFar);
     
     displayScores();
     
     // Update previous values
     pplayer1X = player1.disc.xPos;
     pplayer2X = player2.disc.xPos;
     
     break;
     
    case PAUSE:
      for (Fruit f : fruits) {
        f.drawFruit();
      }
      player1.drawPlayerDisc();
      player2.drawPlayerDisc();
      displayScores();
      drawPoinDescription();
      
      fill(0, 100, 0);
      textSize(60);
      text("GAME IS PAUSED", width/3, height/3+50);
      textSize(30);
      text("Press SPACE to resume game", width/3+15, height/3+100);  
      
      if (keyPressed && key == ' ' && (currentTime - lastPressed) > pressInterval){
        STATE = GAME;
        float pauseTime = currentTime - pausedAt;
        lastPressed = currentTime;
        
        timer = pausedAt + pauseTime;
      }
      
      break;  
    
    default:
      break;
  }
  
  // For debugging
  // debugging(currentTime);
  
}

void debugging(float currentTime){
  //println("STATE: " + STATE);
  println("Current fruit index: " + fallingFruit);
  println("Current Time: " + currentTime + "\nTimer: " + timer  + "\n");
}

float getDropDelay(){
  return random(lwbd, upbd);
}

// Display scores function
void displayScores(){
fill(255, 0, 255);
   text("Player 2", width-270, 160);
   stroke(255, 0, 255);
   strokeWeight(3);
   line(width-270, 170, width-100, 170);
   text("Score: " + player1.score, width-270, 200);
   text("Streak: " + player1.streak, width-270, 225);
   
   fill(0, 0, 255);
   text("Player 1", 100, 160);
   stroke(0, 0, 255);
   strokeWeight(3);
   line(100, 170, 270, 170);
   text("Score: " + player2.score, 100, 200);
   text("Streak: " + player2.streak, 100, 225);
   noStroke();
}

void drawPoinDescription(){
 // Draw fruits
 fill(0,255,0);
 ellipse(width-250, 400, fruitRadius, fruitRadius);
 fill(255,0,0);
 ellipse(width-250, 450, fruitRadius, fruitRadius);
 fill(255,165,0);
 ellipse(width-250, 500, fruitRadius, fruitRadius);
 
 // Write corresponding point
 fill(0,100,0);
 text(": 1 point", width-231, 394 + fruitRadius);
 text(": 2 points", width-231, 444 + fruitRadius);
 text(": 3 points", width-231, 494 + fruitRadius);
}


// Determine if 'player' has caught the fruit given the coordinates of the disc (x,y).
void catchHandler(Player player, Fruit f){
   float x = player.disc.xPos;
   float y = player.disc.yPos;
   float fr = f.radius;
   float fx = f.xPos;
   float fy = f.yPos;
   
   if ((y-fr <= fy && fy <= y+disch+fr) && (fx >= x-fr-discw/2 && fx <= x+discw+fr-discw/2) && !player.caught.contains(f)) {
     player.score += f.points;
     player.streak++;
     player.caught.add(f);
   } 
}

void serialEvent(Serial port){
  String received = port.readStringUntil('\n');
  if (received != null) {
    float[] vals = float(split(received, ' '));
    potent1 = vals[0];
    potent2 = vals[1];
  }
}

// Class for player disc
class Disc{
  float xPos;
  float yPos;
  float discWidth;
  float discHeight;
  int red;
  int green;
  int blue;
  
  Disc(float x, float y, float w, float h, int r, int g, int b){
    discWidth = w;
    discHeight = h;
    xPos = x;
    yPos = y;
    red = r;
    green = g;
    blue = b;
  }
  
  void moveDisc(float dx, float dy){
    xPos += dx;
    yPos += dy;
  }
    
  
  // Draw discs function
  void drawDisc(){
    shape(basket, xPos, yPos, discWidth, 80);  // basketHeight == 80
  }
}

class Fruit{
  float xPos;
  float yPos;
  float radius;
  int red;
  int green;
  int blue;
  int fallSpeed;
  String type;
  int points;
  
  Fruit(float x, float y, float rad, int r, int g, int b, int fs, String t){
    xPos = x;
    yPos = y;
    radius = rad;
    red = r;
    green = g;
    blue = b;
    fallSpeed = fs;
    type = t;
    
    // Determine how many points the fruit gives
    if (type == "apple") {
      points = 1;
    } else if (type == "banana") {
      points = 2;
    } else {  // orange
      points = 3;
    }
  }
  
  // Draw fruit function
  void drawFruit(){
    fill(red, green, blue);
    ellipse(xPos, yPos, radius, radius);  
  }
  
  void moveFruit(float dx, float dy){
    xPos += dx;
    yPos += dy;
  }
}

class Player{
  int score;
  int streak;
  Disc disc;
  ArrayList<Fruit> caught = new ArrayList<Fruit>();  // contains fruits that have been caught
  int playerNumber;
  
  Player(int pNumber, int scr, int str, Disc d){
    playerNumber = pNumber;
    score = scr;
    streak = str;
    disc = d;
  }
  
  void drawPlayerDisc(){
    disc.drawDisc();
    fill(disc.red, disc.green, disc.blue);
    text("P" + playerNumber, disc.xPos-20, disc.yPos+60);
  }
  
  void movePlayer(float dx, float dy){
    disc.moveDisc(dx, dy);
  }
}
  
  
  
  
  
