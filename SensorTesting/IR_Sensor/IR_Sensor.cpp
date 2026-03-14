#include "AK9752.h"

void AK9752_init() {
  Wire.begin();
  Wire.setClock(100000);

  // Soft reset
  Wire.beginTransmission(AK9752_ADDR);
  Wire.write(0x16);
  Wire.write(0xFF);
  Wire.endTransmission();
  delay(200);

  // Set continuous mode
  Wire.beginTransmission(AK9752_ADDR);
  Wire.write(0x15);
  Wire.write(0xFD);
  Wire.endTransmission();
  delay(200);
}

int16_t AK9752_readIR() {
  // Check DRDY bit in ST1
  Wire.beginTransmission(AK9752_ADDR);
  Wire.write(0x04);
  Wire.endTransmission(false);
  Wire.requestFrom(AK9752_ADDR, 1);
  uint8_t st1 = Wire.read();

  if (!(st1 & 0x01)) return INT16_MIN;

  // Read INTCAUSE (required before reading data)
  Wire.beginTransmission(AK9752_ADDR);
  Wire.write(0x05);
  Wire.endTransmission(false);
  Wire.requestFrom(AK9752_ADDR, 1);
  Wire.read();

  // Read IR data
  Wire.beginTransmission(AK9752_ADDR);
  Wire.write(0x06);
  Wire.endTransmission(false);
  Wire.requestFrom(AK9752_ADDR, 2);
  uint8_t irl = Wire.read();
  uint8_t irh = Wire.read();

  // Read ST2 to unlock registers
  Wire.beginTransmission(AK9752_ADDR);
  Wire.write(0x0A);
  Wire.endTransmission(false);
  Wire.requestFrom(AK9752_ADDR, 1);
  Wire.read();

  return (int16_t)((irh << 8) | irl);
}