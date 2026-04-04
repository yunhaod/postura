#include <bluefruit.h>
#include <Arduino.h>
#include "sensors.h"

BLEService PostureService = BLEService("a3721400-00b0-4240-ba50-05ca45bf8abc");
BLECharacteristic SensorChar = BLECharacteristic("b3721400-00b0-4240-ba50-05ca45bf8dec");
//Python expects : LT, RT, LB, RB, Flex

////looking at it from front
//pin A0 is top right, pin A2 is bottom right
//pin A1 is top left, pin A3 is bottom left

//top left can have connection issue due to wire placement 

int pins[NUM_PSENSORS] = {A1, A0, A3, A2};
//                        LT  RT  LB  RB

//looking at it from front
//pin 0 is top right, pin2 is bottom right
//pin 1 is top left, pin 3 is bottom left

//top left can have connection issue due to wire placement 

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
  //IRSensorSetup();
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
  // 4 int16 = 8 bytes
  SensorChar.setFixedLen(8);   
  SensorChar.begin();
}

void loop() {
  // put your main code here, to run repeatedly:

  if (Bluefruit.connected()){
      // the expected data fields are = ["LT", 'RT', 'LB', 'RB']
      //get the data from the sensors
      float readings[NUM_PSENSORS];
        if (ReadPressureSensors(readings)) {
            for (int i = 0; i < NUM_PSENSORS; i++) {
                Serial.println(readings[i]);
            }
        } else {
            Serial.println("One or more sensors invalid.");
        }
      int16_t sensor_data[4] = {readings[0],readings[1],readings[2],readings[3]};
      SensorChar.notify(sensor_data, sizeof(sensor_data));
      Serial.println("Sensor Data Sent sent");
  }
  delay(1000);
}
