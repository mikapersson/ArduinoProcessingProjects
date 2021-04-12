// Main file
import processing.serial.*;  // enable communication with Arduino
import processing.sound.*;   // enable sound 

// For Arduino communication
Serial port;
String received = null;
float readAmplitude = 0;    // read amplitude of spaceship
float readOffset = 0;       // read offsett of spaceship
char calibTime = '2';       // seconds

// Properties of spaceship
final int ssWidth = 150;
final int ssHeight = 200;
final float easing = 0.05;
final float offsetEasing = 0.01;
PShape spaceshipSVG;
PImage spaceBG;  // background
Spaceship spaceship;
final int middleX = 400;
final int maxOffset = 200;
float yPos = 450;
float targetAmplitude;
float targetOffset;
float prevAmplitude = yPos;
float prevOffset = 0;
final int minAmplitude = 50;
int maxAmplitude;
int highscore = 0;

// Asteroid properties
final int minRadius = 100;
final int maxRadius = 500;
final int flySpeed = 25;
ArrayList<Asteroid> asteroids;

// Calibration variables
boolean sentK = false;
boolean sentct = false;
boolean recK = false;

// Font and sounds
PFont font;
PFont scoreFont;  // since I can't get flappy bird font to present digits or colon
SoundFile bgSound;
SoundFile blip;
SoundFile explosion;

// STATES
int STATE;
final int START = 0;
final int CALIBRATING = 1;
final int FLYING = 2;
final int CRASHED = 3;
final int PAUSED = 4;

// Timers 
float currentTime = millis();
float lastPressed = millis();  // when a button was last pressed
float lastAsteroid;
float minWait = 1000*0.5;
float maxWait = 1000*1.5;
float asteroidDelay = random(minWait, maxWait);
float pressInterval = 200;  
float pausedAt;

void setup(){
  size(1600, 900);  // size of background image
  spaceBG = loadImage("space.jpg");
  spaceshipSVG = loadShape("spaceship.svg");
  shapeMode(CENTER);
  spaceship = new Spaceship(middleX, yPos, ssWidth, ssHeight);  
  asteroids = new ArrayList<Asteroid>();
  maxAmplitude = height - minAmplitude;
  
  port = new Serial(this, Serial.list()[0], 9600);  // communicate with the arduino
  STATE = START;
  
  // Font and sounds
  font = createFont("FlappyBirdy.ttf", 32);
  scoreFont = createFont("8bitOperatorPlus8-Bold.ttf", 32);
  textFont(font);
  bgSound = new SoundFile(this, "backgroundsound.wav");
  bgSound.play();
  blip = new SoundFile(this, "blip.wav");
  explosion = new SoundFile(this, "explosion.wav");
}

void draw(){
  currentTime = millis();
  background(spaceBG);
  
  switch(STATE){
    case START:
      fill(255,255,255);
      textSize(200);
      text("FLAPPY SPACESHIP", width/3-180, height/3);
      textSize(100);
      text("Press SPACE to start flying", width/3-120, height/3+100);
      
      if (keyPressed && key == ' '){
        STATE = CALIBRATING;
        lastPressed = currentTime;
        delay(100);
      } 
      break;
    case CALIBRATING:
      fill(255,255,255);
      textFont(font, 200);
      text("CALIBRATING SENSORS", width/3-280, height/3+100);
      
      // Check if the Arduino has sent new sensor data
      if(port.available() > 0){
        received = port.readStringUntil('\n');
        if(received != null){
          println("New data string: " + received);
          
          // Send K to Arduino
          if(!sentK){  
            port.write(75);
            println("Sent K to Arduino");
            sentK = true;
          }
          
          // Receive K from Arduino, thus it's ready to receive calibTime
          if(sentK && !recK){
            if(received.equals("K\n")){
              println("received K");
              recK = true;
            }
          }
          
          // Send calibTime to Arduino
          if(!sentct && recK){
            port.write(calibTime); 
            println("Sent calibTime to Arduino");
            sentct = true;
            delay((int(calibTime)-'0')*1000);
          } 
        }
      }     
      
      if(sentK && sentct && recK){  // Calibration finished
        delay((int(calibTime)-'0')*1000);
        STATE = FLYING;  // weehoooo
      }
      break;
    case FLYING:
      // Check if game is paused
      if(gamePaused()){
        STATE = PAUSED;
        pausedAt = currentTime;
        break;
      }
    
      // Check if the Arduino has sent new sensor data
      if(port.available() > 0){
        received = port.readStringUntil('\n');
        if(received != null){
          //print("New data string: " + received);  // received contains \n
          
          float[] vals = float(split(received, ' '));
          readAmplitude = vals[0];
          readOffset = vals[1];
          if(Float.isNaN(readAmplitude)){  // make sure that sensorVal is not NaN
            readAmplitude = 255/2; 
            readOffset = 0;
          }
        }
      }
      
      background(spaceBG); 
      
      // Compute new target amplitude of spaceship
      targetAmplitude = map(readAmplitude, 255, 0, minAmplitude, maxAmplitude);
      targetOffset = readOffset;
      
      // Create new asteroid (or not)
      if(currentTime > lastAsteroid + asteroidDelay){
        Asteroid newAsteroid = new Asteroid(random(minAmplitude+100, maxAmplitude-100), random(minRadius, maxRadius)); 
        asteroids.add(newAsteroid);
        
        asteroidDelay = random(minWait, maxWait);
        lastAsteroid = currentTime;
      }
      
      // Move and draw asteroids
      for(Asteroid a : asteroids){
        a.xPos -= flySpeed; 
        a.drawAsteroid();
        a.rotation++;
      }
      
      // Move spaceship
      spaceship.yPos += (targetAmplitude - prevAmplitude) * easing;
      spaceship.xPos += (targetOffset - prevOffset) * offsetEasing;  
      
      // Detect collision
      for(Asteroid a : asteroids){
        // Compute distance between spaceship and asteroid 'a'
        float distance = dist(spaceship.xPos, spaceship.yPos, a.xPos, a.amplitude);
        if(distance < a.radius/2.5){
          STATE = CRASHED;
          highscoreHandler();
          explosion.play();
          break;
        }
      }
      
      // Remove asteroids that have passed
      ArrayList<Asteroid> toRemove = new ArrayList<Asteroid>();
      for(Asteroid a : asteroids){
        // Compute distance between spaceship and asteroid 'a'
        float distance = dist(spaceship.xPos, spaceship.yPos, a.xPos, a.amplitude);
        if(distance >= a.radius/2.5 && a.xPos < spaceship.xPos && !spaceship.pastAsteroids.contains(a)){
          spaceship.pastAsteroids.add(a);
          spaceship.score++;
          highscoreHandler();
          blip.play();
          break;
        }
      }
      asteroids.removeAll(toRemove);
      
      // Display current score and draw ship
      displayScore();
      spaceship.drawSpaceship();
      
      prevAmplitude = spaceship.yPos;
      prevOffset = spaceship.xPos - middleX;
      
      break;
    case CRASHED:
      textFont(font, 200);
      text("YOU CRASHED", width/3-70, height/3);
      textSize(100);
      text("Press SPACE to retry", width/3-40, height/3+100);
      text("You scored", width/3+40, height - 200);
      textFont(scoreFont, 65);
      text(": " + spaceship.score, width/3 + 325, height-205);
      
      // Decide if game should be restarted
      if (keyPressed && key == ' '){
        restartGame();
        STATE = FLYING;
        lastPressed = currentTime;
        delay(100);
      }
      
      break;
      
    case PAUSED:
      for (Asteroid a : asteroids) {
        a.drawAsteroid();
      }
      spaceship.drawSpaceship();
      
      textFont(font, 150);
      text("PAUSED", width/2-170, height/2);
      
      if (keyPressed && key == ' ' && (currentTime - lastPressed) > pressInterval){
        STATE = FLYING;
        float pauseTime = currentTime - pausedAt;
        lastPressed = currentTime;
        
        lastAsteroid = pausedAt + pauseTime;
      }
    
      break;
  }
}

void displayScore(){
  textFont(font, 80);
  text("SCORE" , 100, 100);
  text("HIGHSCORE" , 100, 170);
  
  textFont(scoreFont, 60);
  text(": " + spaceship.score, 230, 95);
  text(": " + highscore , 320, 165);
}

void highscoreHandler(){
  if(spaceship.score > highscore){
    highscore = spaceship.score;
  }
}

void restartGame(){
  // Reset score
  spaceship.score = 0;
  
  // Reset asteroids
  asteroids = new ArrayList<Asteroid>();
}

boolean gamePaused(){
  if (keyPressed && key == ' ' && (currentTime - lastPressed) > pressInterval){
       pausedAt = millis();
       lastPressed = currentTime;
       return true;
  } else {
    return false; 
  }
}
