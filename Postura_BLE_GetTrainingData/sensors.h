#ifndef SENSORS_H
#define SENSORS_H

#include <Arduino.h>
#include <math.h>

#define FILTER_N 16
#define NUM_SENSORS 6

typedef struct{
    int      pin;
    uint16_t buf[FILTER_N];
    uint32_t sum;
    int      idx;
}PressureSensor;
 
extern PressureSensor pressureSensors[NUM_SENSORS];

void  PressureSensorSetup(int pins[NUM_SENSORS]);
bool  ReadPressureSensors(float out[NUM_SENSORS]);

#endif