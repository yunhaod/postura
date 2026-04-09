#ifndef BLE_POSTURE_H
#define BLE_POSTURE_H

#include <Arduino.h>
#include <ArduinoBLE.h>
#include <math.h>

#define FILTER_N 6
#define NUM_PSENSORS 4

// BLE Service and Characteristics
extern BLEService PostureService;
extern BLECharacteristic PostureChar;
extern BLECharacteristic CommandChar;

// Global state variables
extern bool send_status;
extern volatile uint8_t posture_status;

typedef struct{
    int      pin;
    uint16_t buf[FILTER_N];
    uint32_t sum;
    int      idx;
}PressureSensor;
 
extern PressureSensor pressureSensors[NUM_PSENSORS];

void  PressureSensorSetup(int pins[NUM_PSENSORS]);
bool  ReadPressureSensors(float out[NUM_PSENSORS]);

// Setup functions
void BLEsetup();
void StartBLEservice();

// BLE callbacks
void connect_callback(BLEDevice central);
void disconnect_callback(BLEDevice central);
void commandWritten(BLEDevice central, BLECharacteristic characteristic);

// Posture logic
uint8_t determine_posture();

#endif