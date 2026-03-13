#ifndef BLE_POSTURE_H
#define BLE_POSTURE_H

#include <Arduino.h>
#include <ArduinoBLE.h>

// BLE Service and Characteristics
extern BLEService PostureService;
extern BLECharacteristic PostureChar;
extern BLECharacteristic CommandChar;

// Global state variables
extern bool send_status;
extern volatile uint8_t posture_status;

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