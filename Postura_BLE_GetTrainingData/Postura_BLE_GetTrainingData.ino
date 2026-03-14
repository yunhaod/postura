#include <bluefruit.h>
#include <Arduino.h>
#include "sensors.h"

BLEService PostureService = BLEService("a3721400-00b0-4240-ba50-05ca45bf8abc");
BLECharacteristic SensorChar = BLECharacteristic("b3721400-00b0-4240-ba50-05ca45bf8dec");
int pins[NUM_PSENSORS] = {A0, A1, A2, A3};


void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  Bluefruit.configUuid128Count(5);
  Bluefruit.begin();
  Bluefruit.setTxPower(4);  
  Bluefruit.setName("Postura");

  StartBLEservice();

  // Start advertising
  Bluefruit.Periph.setConnectCallback(connect_callback);
  Bluefruit.Periph.setDisconnectCallback(disconnect_callback);
  Bluefruit.Advertising.addService(PostureService);
  Bluefruit.Advertising.start();
  Serial.println("Start advertising");
  PressureSensorSetup(pins);
}

// callback invoked when central connects
void connect_callback(uint16_t conn_handle)
{
  // Get the reference to current connection
  BLEConnection* connection = Bluefruit.Connection(conn_handle);

  char central_name[32] = { 0 };
  connection->getPeerName(central_name, sizeof(central_name));

  Serial.print("Connected to ");
  Serial.println(central_name);
}

void disconnect_callback(uint16_t conn_handle, uint8_t reason)
{
  (void) conn_handle;
  (void) reason;

  Serial.println();
  Serial.print("Disconnected, reason = 0x"); Serial.println(reason, HEX);
}


void StartBLEservice(){
  PostureService.begin();

  SensorChar.setProperties(CHR_PROPS_NOTIFY);
  SensorChar.setPermission(SECMODE_OPEN, SECMODE_NO_ACCESS);
  SensorChar.setFixedLen(7);   
  SensorChar.begin();
}

void loop() {
  // put your main code here, to run repeatedly:

    if (Bluefruit.connected()){
        // the expected data fields are = ["LT", 'RT', 'LM', 'RM', 'LB', 'RB', 'IR']
        //get the data from the sensors
        float readings[NUM_PSENSORS];
          if (ReadPressureSensors(readings)) {
              for (int i = 0; i < NUM_PSENSORS; i++) {
                  Serial.println(readings[i]);
              }
          } else {
              Serial.println("One or more sensors invalid.");
          }

        uint16_t sensor_data[7] = {1,2,3,4,5,6,7};
        SensorChar.notify(sensor_data, 7);
        Serial.println("Sensor Data Sent sent");
    }
  }


