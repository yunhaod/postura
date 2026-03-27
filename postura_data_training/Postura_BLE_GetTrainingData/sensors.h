#ifndef SENSORS_H
#define SENSORS_H

#include <Arduino.h>
#include <math.h>
#include <Wire.h>

#define FILTER_N 16
#define NUM_PSENSORS 5
#define AK9752_ADDR 0x64

typedef struct{
    int      pin;
    uint16_t buf[FILTER_N];
    uint32_t sum;
    int      idx;
}PressureSensor;
 
extern PressureSensor pressureSensors[NUM_PSENSORS];

void  PressureSensorSetup(int pins[NUM_PSENSORS]);
bool  ReadPressureSensors(float out[NUM_PSENSORS]);
void FlexSensorSetup(int pin);
float ReadFlexSensor(int pin);
void IRSensorSetup();
int16_t ReadIRSensor();

#endif