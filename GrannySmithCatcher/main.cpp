#include <Arduino.h>

const int potPin1 = 0;
const int potPin2 = 1;

void setup() {
  Serial.begin(9600);
}

void loop() {
  int val1 = map(analogRead(potPin1), 0, 1023, 0, 255);
  int val2 = map(analogRead(potPin2), 0, 1023, 0, 255);

  Serial.print(val1);
  Serial.print(" ");
  Serial.println(val2);
  delay(10);
}