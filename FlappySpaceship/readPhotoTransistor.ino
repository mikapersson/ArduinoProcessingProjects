const int readPins[6] = {A0};
const int nrPins = sizeof(readPins)/sizeof(readPins[0]);  // there is at least one pin

// Constants for calibration and storing read value
int lowerBound = 1023;   // to be decreased
int upperBound = 0;      // to be increased
int readValue = 0;

boolean startedCalibration = false;
boolean calibTimeReceived = false;

void setup() {
  Serial.begin(9600);
  for(int i = 0; i < nrPins; i++){
    pinMode(readPins[i], INPUT);
  }

  // testSpecific(5);  // for debugging
  calibrateSensor();
}


void loop() {
  
  readValue = getValues();
  int toSend = map(readValue, lowerBound, upperBound, 0, 255);
  if (toSend <= 255 && 0 <= toSend){
    Serial.println(toSend); 
  }
    
  delay(50);
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
        }  // calibration finished
  
        Serial.print("Lower bound: "); Serial.print(lowerBound); Serial.print(" and upper bound: "); Serial.println(upperBound);
      }  
    }
  }
}

int readCalibTime(){
  Serial.println("Awaiting calibration time");
  while(!calibTimeReceived){
    if(Serial.available()){
      char received = Serial.read();  
      if(isDigit(received)){
        calibTimeReceived = true;
        Serial.print("Received: '"); Serial.print(received); Serial.println("', VALID");
        int calibTime = received - '0';
        Serial.flush();
        return calibTime * 1000;  // return in milliseconds
      } else {
        Serial.print("Received: '"); Serial.print(received);
        Serial.println("', NOT VALID");
        Serial.flush();
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

int getValues(){
  int cumSum = 0;
  for(int i = 0; i < nrPins; i++){
    cumSum += analogRead(readPins[i]);
  }
  return cumSum/nrPins;
}
