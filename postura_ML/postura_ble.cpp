#include "postura_ble.h"
#include <Arduino.h>
#include <ArduinoBLE.h>

BLEService PostureService = BLEService("a3721400-00b0-4240-ba50-05ca45bf8abc");
BLECharacteristic PostureChar("a3721400-00b0-4240-ba50-05ca45bf8dec", (uint16_t)(BLERead | BLENotify), 1, true);
BLECharacteristic CommandChar("a3721400-00b0-4240-ba50-05ca45bf8def", (uint16_t)(BLERead | BLEWrite), 1, true);

bool send_status = false;
volatile uint8_t posture_status = 0;
//the number indicates which spot on the cushion is not being fulfilled.
//63 = perfect
// 000 000
// 111 111
// Numbers will be respectively mapped to where the pressure sensor is placed on the cushion
// See sensor placing according to the diagram in the bom?

void BLEsetup(){
  BLE.setLocalName("Postura");
  BLE.setAdvertisedService(PostureService);

  StartBLEservice();

  BLE.setEventHandler(BLEConnected, connect_callback);
  BLE.setEventHandler(BLEDisconnected, disconnect_callback);

  BLE.advertise();
}


void StartBLEservice() {
  PostureService.addCharacteristic(PostureChar);
  PostureService.addCharacteristic(CommandChar);
  BLE.addService(PostureService);

  CommandChar.setEventHandler(BLEWritten, commandWritten);
}

void connect_callback(BLEDevice central) {
  Serial.print("Connected: ");
  Serial.println(central.address());
}

void disconnect_callback(BLEDevice central) {
  Serial.print("Disconnected: ");
  Serial.println(central.address());
}


void commandWritten(BLEDevice central, BLECharacteristic chr) {
    if (chr.valueLength() < 1) return;
    uint8_t command = chr.value()[0];
    Serial.println("Command Written");
    if (command == 3) {
        send_status = true;
        Serial.println("Posture Status can be sent");
    } else {
        send_status = false;
        Serial.println("Posture Status cannot be sent");
    }
}


//determines if the posture is good
uint8_t determine_posture(){
  return 63;
}

