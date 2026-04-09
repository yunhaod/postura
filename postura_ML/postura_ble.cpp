#include "postura_ble.h"
#include <Arduino.h>
#include <ArduinoBLE.h>

static const float VCC = 3.3f;
static const float R_FIXED = 10000.0f;

PressureSensor pressureSensors[NUM_PSENSORS];


BLEService PostureService = BLEService("a3721400-00b0-4240-ba50-05ca45bf8abc");
BLECharacteristic PostureChar("a3721400-00b0-4240-ba50-05ca45bf8dec", (uint16_t)(BLERead | BLENotify), 1, true);
BLECharacteristic CommandChar("a3721400-00b0-4240-ba50-05ca45bf8def", (uint16_t)(BLERead | BLEWrite), 1, true);

bool send_status = false;

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


void PressureSensorSetup(int pins[NUM_PSENSORS])
{
    analogReadResolution(12);
    for (int s = 0; s < NUM_PSENSORS; s++) {
        pressureSensors[s].pin = pins[s];
        pressureSensors[s].sum = 0;
        pressureSensors[s].idx = 0;
        for (int i = 0; i < FILTER_N; i++) {
            uint16_t x = analogRead(pins[s]);
            pressureSensors[s].buf[i] = x;
            pressureSensors[s].sum += x;
            delay(10);
        }
    }
    Serial.println("Sensors Initialized.");
}

static float estimateRsensorOhm(float adcAvg)
{
    float vNode = VCC * adcAvg / 4095.0f;
    if (vNode < 0.001f) return INFINITY;
    float resistance = R_FIXED * (VCC - vNode) / vNode;
    // Anything above 3MΩ is no contact, not a valid pressure reading
    if (resistance > 2000000.0f) return INFINITY;
    return resistance;
}

bool ReadPressureSensors(float out[NUM_PSENSORS])
{
    bool valid = true;
    for (int i = 0; i < NUM_PSENSORS; i++) {
        uint16_t x = analogRead(pressureSensors[i].pin);
        pressureSensors[i].sum -= pressureSensors[i].buf[pressureSensors[i].idx];
        pressureSensors[i].buf[pressureSensors[i].idx] = x;
        pressureSensors[i].sum += x;
        pressureSensors[i].idx = (pressureSensors[i].idx + 1) % FILTER_N;

        float avg = (float)pressureSensors[i].sum / (float)FILTER_N;
        float resistance = estimateRsensorOhm(avg);

        if (!isfinite(resistance)) {
            out[i] = -1.0f;  // sentinel for Python invalid flag
            valid = false;
        } else {
            out[i] = resistance / 1000.0f;  // convert to kΩ
        }
    }
    return valid;
}
