#include <bluefruit.h>
#include <Arduino.h>

BLEService PostureService = BLEService("a3721400-00b0-4240-ba50-05ca45bf8abc");
BLECharacteristic PostureChar = BLECharacteristic("a3721400-00b0-4240-ba50-05ca45bf8dec");
BLECharacteristic CommandChar = BLECharacteristic("a3721400-00b0-4240-ba50-05ca45bf8def");

bool send_status = false;
volatile uint8_t posture_status = 0;
//the number indicates which spot on the cushion is not being fulfilled.
//63 = perfect
// 000 000
// 111 111
// Numbers will be respectively mapped to where the pressure sensor is placed on the cushion
// See sensor placing according to the diagram in the bom?

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
  PostureChar.setFixedLen(1);   
  PostureChar.begin();

  CommandChar.setProperties(CHR_PROPS_WRITE | CHR_PROPS_READ);
  CommandChar.setPermission(SECMODE_OPEN, SECMODE_OPEN);
  CommandChar.setFixedLen(1); 
  CommandChar.setWriteCallback(commandWritten);
  CommandChar.begin();
}

void loop() {
  // put your main code here, to run repeatedly:

    if (send_status == true && Bluefruit.connected()){
      //if the posture changed, send an update
      if (posture_status != determine_posture()){
        //sending a 1 indicates good posture
        posture_status = determine_posture();
        PostureChar.notify8(posture_status);
        Serial.println("Notification sent");
    }
  }
}

void commandWritten(uint16_t conn_hdl, BLECharacteristic* chr, uint8_t* data, uint16_t len) {
  if (len < 1) return;

  uint8_t command = data[0];
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
