//TEST CODE 
#include <Arduino.h>
#include "sensors.h"
//looking at it from front
//pin 0 is top right, pin2 is bottom right
//pin 1 is top left, pin 3 is bottom left

//top left can have connection issue due to wire placement 

int pins[NUM_PSENSORS] = {A1, A0, A3, A2};
//                        LT  RT  LB  RB

#define FlexSensorPin A0
//flex sensor is absolutely useless and would just introduce noise

void setup() {
  Serial.begin(115200);
  while (!Serial) delay(10);
  PressureSensorSetup(pins);
}

void loop() {
  float readings[NUM_PSENSORS];
  if (ReadPressureSensors(readings)) {
    for (int i = 0; i < 4; i++) {
      Serial.print("P"); Serial.print(i); Serial.print(": ");
      Serial.print(readings[i]); Serial.println(" ohms");
    }
  } else {
    Serial.println("One or more pressure sensors invalid.");
  }
  delay(300);
}
