#ifndef AK9752_H
#define AK9752_H

#include <Wire.h>

#define AK9752_ADDR 0x64

void AK9752_init();
int16_t AK9752_readIR();

#endif