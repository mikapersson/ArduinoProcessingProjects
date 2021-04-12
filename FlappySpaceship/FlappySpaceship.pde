// Main file
import processing.serial.*;  // enable communication with Arduino
import processing.sound.*;   // enable sound 

// For Arduino communication
Serial port;
String received = null;
float sensorVal = 0;    // read amplitude of spaceship
char calibTime = '4';  // seconds

// Properties of spaceship
final int ssWidth = 150;
final int ssHeight = 200;
final float easing = 0.05;
PShape spaceshipSVG;
PImage spaceBG;  // background
Spaceship spaceship;
final int xPos = 400;
float yPos = 450;
float targetAmplitude;
float prevAmplitude = yPos;

// Calibration variables
boolean sentK = false;
boolean sentct = false;

// Font and sounds
PFont font;
SoundFile bgSound;

// STATES
int STATE;
final int START = 0;
final int CALIBRATING = 1;
final int FLYING = 2;
final int PAUSE = 3;

// Timers 
float currentTime = millis();
float lastPressed;  // when a button was last pressed

void setup(){
  // Start by calibrating the sensor
  port = new Serial(this, Serial.list()[0], 9600);  // communicate with the arduino
  //calibrateSensor();
  STATE = START;
  
  size(1600, 900);  // size of background image
  spaceBG = loadImage("space.jpg");
  spaceshipSVG = loadShape("spaceship.svg");
  shapeMode(CENTER);
  spaceship = new Spaceship(xPos, yPos, ssWidth, ssHeight);  
  
  // Font and sounds
  font = createFont("FlappyBirdy.ttf", 32);
  textFont(font);
  bgSound = new SoundFile(this, "backgroundsound.wav");
  bgSound.play();
}

void draw(){
  currentTime = millis();
  background(spaceBG);
  
  switch(STATE){
    case START:
      println("STATE: START");
      fill(255,255,255);
      textSize(200);
      text("FLAPPY SPACESHIP", width/3-180, height/3);
      textSize(100);
      text("Press SPACE to start flying", width/3-120, height/3+100);
      
      if (keyPressed && key == ' '){
        STATE = CALIBRATING;
        lastPressed = currentTime;
      } 
      break;
    case CALIBRATING:
      println("STATE: CALIBRATING");
      fill(255,255,255);
      textSize(200);
      text("CALIBRATING SENSORS", width/3-280, height/3+100);
      
      // Check if the Arduino has sent new sensor data
      if(port.available() > 0){
        received = port.readStringUntil('\n');
        if(received != null){
          print("New data string: " + received);
          if(!sentK){
            port.write(75);
            sentK = true;
          }
          if(!sentct && sentK){
            port.write(calibTime); 
            sentct = true;
            delay((int(calibTime)-'0')*1000);
          } 
        }
      }     
      
      if(sentK && sentct){  // Calibration finished
        delay((int(calibTime)-'0')*1000);
        STATE = FLYING;  // weehoooo
      }
      break;
    case FLYING:
      
      // Check if the Arduino has sent new sensor data
      if(port.available() > 0){
        received = port.readStringUntil('\n');
        if(received != null){
          print("New data string: " + received);
          sensorVal = float(received);
          if(Float.isNaN(sensorVal)){  // make sure that sensorVal is not NaN
            sensorVal = 255/2; 
          }
        }
      }
      
      background(spaceBG);
      //println("Sensor value: " + sensorVal);  
      
      // Compute new target amplitude of spaceship
      targetAmplitude = map(sensorVal, 0, 255, ssWidth/2, height-ssWidth/2);
      //spaceship.yPos = mouseY;
      
      // Create new asteroid (or not)
      
      // Move asteroids
      
      // Move spaceship
      spaceship.yPos += (targetAmplitude - prevAmplitude) * easing;
      println("Space Y: " + spaceship.yPos);
      
      // Detect collision
      
      spaceship.drawSpaceship();
      
      prevAmplitude = spaceship.yPos;
  
      
      break;
  }
}

/*
void calibrateSensor(){
  println("Sending K to arduino");
  port.write(75);
  delay(20);
  port.write(calibTime);
  println("Started calibration");
  delay((int(calibTime)-'0')*1000);
  println("Calibration completed");
}*/
