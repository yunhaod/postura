#ifndef SENSORS_H
#define SENSORS_H

#include <Arduino.h>
#include <math.h>

#define FILTER_N 4
#define NUM_PSENSORS 5
typedef struct{
    int      pin;
    uint16_t buf[FILTER_N];
    uint32_t sum;
    int      idx;
}PressureSensor;
 
extern PressureSensor pressureSensors[NUM_PSENSORS];

void  PressureSensorSetup(int pins[NUM_PSENSORS]);
bool  ReadPressureSensors(float out[NUM_PSENSORS]);

#endif