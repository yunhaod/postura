#include "AK9752.h"

void setup() {
  Serial.begin(115200);
  delay(3000);
  AK9752_init();
  Serial.println("starting");
}

void loop() {
  int16_t irRaw = AK9752_readIR();
  if (irRaw != INT16_MIN) {
    Serial.println(irRaw);
  }
  delay(150);
}