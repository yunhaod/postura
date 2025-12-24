#include <bluefruit.h>
#include <Arduino.h>

BLEService PostureService = BLEService("a3721400-00b0-4240-ba50-05ca45bf8abc");
BLECharacteristic PostureChar = BLECharacteristic("a3721400-00b0-4240-ba50-05ca45bf8dec");
BLECharacteristic CommandChar = BLECharacteristic("a3721400-00b0-4240-ba50-05ca45bf8def");

#define DATA_SIZE 2

bool send_status = false;
bool posture_status = false;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  Bluefruit.configUuid128Count(5);
  Bluefruit.begin();
  Bluefruit.setTxPower(4);  
  Bluefruit.setName("Postura");

  setupBLE();

  // Start advertising
  Bluefruit.Periph.setConnectCallback(connect_callback);
  Bluefruit.Periph.setDisconnectCallback(disconnect_callback);
  Bluefruit.Advertising.addService(PostureService);
  Bluefruit.Advertising.start();
  Serial.println("Start advertising");
  
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


void setupBLE(){
  PostureService.begin();

  PostureChar.setProperties(CHR_PROPS_NOTIFY);
  PostureChar.setPermission(SECMODE_OPEN, SECMODE_NO_ACCESS);
  PostureChar.setFixedLen(DATA_SIZE * sizeof(short));   
  PostureChar.begin();

  CommandChar.setProperties(CHR_PROPS_WRITE | CHR_PROPS_WRITE_WO_RESP);
  CommandChar.setPermission(SECMODE_OPEN, SECMODE_NO_ACCESS);
  CommandChar.setFixedLen(DATA_SIZE * sizeof(short)); 
  CommandChar.setWriteCallback(commandWritten);
  CommandChar.begin();
}

void loop() {
  // put your main code here, to run repeatedly:
    if (send_status == true){
      //if the posture changed, send an update
      if (posture_status != determine_posture()){
        //sending a 1 indicates good posture
        PostureChar.notify8(uint8_t(posture_status));
    }
  }
}

void commandWritten(uint16_t conn_hdl, BLECharacteristic* chr, uint8_t* data, uint16_t len) {
  if (len < 1) return;

  uint8_t command = data[0];

  if (command == 3) {
    send_status = true;
  } else {
    send_status = false;
  }
}

//determines if the posture is good
bool determine_posture(){
  return true;
}
