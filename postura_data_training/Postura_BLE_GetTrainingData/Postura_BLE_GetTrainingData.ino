#include <bluefruit.h>
#include <Arduino.h>
#include "sensors.h"

BLEService PostureService = BLEService("a3721400-00b0-4240-ba50-05ca45bf8abc");
BLECharacteristic SensorChar = BLECharacteristic("b3721400-00b0-4240-ba50-05ca45bf8dec");
int pins[NUM_PSENSORS] = {A4, A1, A2, A3};
#define FlexSensorPin A0

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  Bluefruit.configUuid128Count(5);
  Bluefruit.begin();
  Bluefruit.setTxPower(4);  
  Bluefruit.setName("Postura");
  Bluefruit.Advertising.addName();

  StartBLEservice();

  // Start advertising
  Bluefruit.Periph.setConnectCallback(connect_callback);
  Bluefruit.Periph.setDisconnectCallback(disconnect_callback);
  Bluefruit.Advertising.addService(PostureService);
  Bluefruit.Advertising.start();
  Serial.println("Start advertising");
  PressureSensorSetup(pins);
  FlexSensorSetup(FlexSensorPin);
  IRSensorSetup();
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
  // 5 int16 = 10 bytes
  SensorChar.setFixedLen(10);   
  SensorChar.begin();
}

void loop() {
  // put your main code here, to run repeatedly:

  if (Bluefruit.connected()){
      // the expected data fields are = ["LT", 'RT', 'LB', 'RB', "Flex"]
      //get the data from the sensors
      float readings[NUM_PSENSORS];
        if (ReadPressureSensors(readings)) {
            for (int i = 0; i < NUM_PSENSORS; i++) {
                Serial.println(readings[i]);
            }
        } else {
            Serial.println("One or more sensors invalid.");
        }
      float rFlex = ReadFlexSensor(FlexSensorPin);
      int16_t sensor_data[5] = {readings[0],readings[1],readings[2],readings[3],rFlex};
      SensorChar.notify(sensor_data, sizeof(sensor_data));
      Serial.println("Sensor Data Sent sent");
  }
}



//TEST CODE 
// #include <Arduino.h>
// #include <Wire.h>
// #include "sensors.h"

// int pins[NUM_PSENSORS] = {A4, A1, A2, A3}; // adjust to match yours

// void setup() {
//   Serial.begin(115200);
//   while (!Serial) delay(10);
//   PressureSensorSetup(pins);
// }

// void loop() {
//   float readings[NUM_PSENSORS];
//   if (ReadPressureSensors(readings)) {
//     for (int i = 0; i < 4; i++) {
//       Serial.print("P"); Serial.print(i); Serial.print(": ");
//       Serial.print(readings[i]); Serial.println(" ohms");
//     }
//   } else {
//     Serial.println("One or more pressure sensors invalid.");
//   }
//   delay(300);
// }
