#include <Arduino.h>

const int readPins[6] = {A0, A1, A2, A3, A4, A5};
const int nrPins = sizeof(readPins)/sizeof(readPins[0]);  // there is at least one pin

// Constants for calibration and storing read value
int lowerBound = 1023;   // to be decreased
int upperBound = 0;      // to be increased
int readValue = 0;

int lowerBounds[nrPins];
int upperBounds[nrPins];

// Agreed upon maximum offset of spaceship in x-direction 
float maxOffset = 200;
float offset = 0;

boolean startedCalibration = false;
boolean calibTimeReceived = false;

int getValues(){
  int cumSum = 0;
  for(int i = 0; i < nrPins; i++){
    cumSum += analogRead(readPins[i]);
  }
  return cumSum/nrPins;
}

int readCalibTime(){
  Serial.println("Awaiting calibration time");
  Serial.write("K\n");  // send K back to Processing to let it know that the Arduino is ready for calibration
  while(!calibTimeReceived){
    if(Serial.available()){
      char received = Serial.read();  
      if(isDigit(received)){
        calibTimeReceived = true;
        int calibTime = received - '0';
        Serial.flush();
        return calibTime * 1000;  // return in milliseconds
      } else {
        //Serial.print("Received: '"); Serial.print(received);
        //Serial.println("', NOT VALID");
        Serial.flush();
      }
    }
  }
}

void calibPin(int i){
  int readVal = analogRead(readPins[i]);
  if(lowerBounds[i] > readVal){
    lowerBounds[i] = readVal;
  }
  if(upperBounds[i] < readVal){
    upperBounds[i] = readVal;
  }
}

// Calibrate the phototransistor by moving your hand to and from the sensor. 
// The method is called after the arduino has received an OK from the Processing sketch.
void calibrateSensor(){
  Serial.println("Waiting to receive K from Processing");
  while(!startedCalibration){  // while we haven't received anything
    if(Serial.available()){
      char received = Serial.read();
      Serial.flush();
      if (received == 'K') {
        Serial.println("Received K for calibration");
        int calibTime = readCalibTime();
        startedCalibration = true;
        Serial.println("Started Calibration");
        float startCalib = millis();
        while (startCalib + calibTime > millis()) {
          readValue = getValues();
  
          if(lowerBound > readValue){
            lowerBound = readValue;
          }
          if(upperBound < readValue){
            upperBound = readValue; 
          }

          // Calibrate each pin
          for(int i = 0; i < nrPins; i++){
            calibPin(i);
          }

        }  // calibration finished
  
      }  
    }
  }
}

void testSpecific(int index){
  while(true){
    if(Serial.available()){
      char rec = Serial.read();
      if(isDigit(rec)){
        index = rec - '0';
      }
    } else {
      Serial.print("Index "); 
      Serial.print(index); 
      Serial.print(" has value: "); 
      Serial.println(analogRead(readPins[index]));
    }
  }
}

// Returns the pin with the highest sensor value
int getMaxPinIndex(){
  int maxVal = 0;
  int maxIndex = 0;
  for(int i = 0; i < nrPins; i++){
    int tempRead = analogRead(readPins[i]);
    if(maxVal < tempRead){
      maxVal = tempRead;
      maxIndex = i;
    }
  }

  return maxIndex;
}

int getAmplitude(){
  readValue = getValues();
  int readAmplitude = map(readValue, lowerBound, upperBound, 0, 255);
  int amplitude;  // actual amplitude
  if (readAmplitude <= 255 && 0 <= readAmplitude){
    amplitude = readAmplitude; 
  } else if (readAmplitude < 0) {
    amplitude = 0;
  } else if (readAmplitude > 255){
    amplitude = 255;
  }
  return amplitude;
}

float getOffset(int amplitude){
  if(nrPins == 1) return 0;  // no offset if there is only one sensor 

  if(amplitude <= 0 || amplitude > 255){  // previous offset if there is no amplitude (spaceship is at the top of the screen)
    return offset;  
  } else {  // compute offsett, assumes that six pins are used
     int maxPinIndex = getMaxPinIndex();
     float offset;
     switch(maxPinIndex){
        case 0:
          offset = maxOffset;
          break;
        case 1:
          offset = 3*maxOffset/5;
          break;
        case 2:
          offset = maxOffset/5;
          break;
        case 3:
          offset = -maxOffset/5;
          break;
        case 4:
          offset = -3*maxOffset/5;
          break;
        case 5:
          offset = -maxOffset;
          break;
        default:
          offset = 0;
          break;
     }

     return offset;
  }
}

void sendData(int amplitude, float offset){
  Serial.print(amplitude); Serial.print(" "); Serial.println(offset);
}

void setup() {
  Serial.begin(9600);
  for(int i = 0; i < nrPins; i++){
    pinMode(readPins[i], INPUT);
    lowerBounds[i] = 1023;
    upperBounds[i] = 0;
  }

  calibrateSensor();
  // testSpecific(5);  // for debugging
}


void loop() {
  
  int amplitude = getAmplitude();
  float offset = getOffset(amplitude);
    
  sendData(amplitude, offset);

  delay(50);
}

