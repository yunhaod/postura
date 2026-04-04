#include <Arduino.h>
#include <math.h>
#include "sensors.h"

static const float VCC=3.3f;
static const float R_FIXED=10000.0f; 

static const float FLEX_VCC       = 3.3f;
static const float FLEX_R_FIXED   = 22000.0f;
static const float FLEX_ADC_MAX   = 4095.0f;  // 12-bit resolution
static const int   FLEX_BUF_SIZE  = 16;

static uint32_t flexSum = 0;
static int      flexIdx = 0;
static uint16_t flexBuf[FILTER_N];

PressureSensor pressureSensors[NUM_PSENSORS];

//PRESSURE SENSOR FUNCTIONS

void PressureSensorSetup(int pins[NUM_PSENSORS])
{
    // Use the Arduino-provided analogReadResolution if supported (e.g., on nRF52/SAMD)
    analogReadResolution(12);

    for (int s = 0; s < NUM_PSENSORS; s++) {
        pressureSensors[s].pin = pins[s];
        pressureSensors[s].sum = 0;
        pressureSensors[s].idx = 0;
        
        // Initial fill of the buffer to avoid starting at zero
        for (int i = 0; i < FILTER_N; i++) {
            uint16_t x = analogRead(pins[s]);
            pressureSensors[s].buf[i] = x;
            pressureSensors[s].sum += x;
            delay(1); // Small delay for ADC stability during init
        }
    }
    Serial.println("Sensors Initialized.");
}

static float estimateRsensorOhm(float adcAvg)
{
    // 4095.0f for 12-bit resolution
    float vNode = VCC * adcAvg / 4095.0f;
    if (vNode < 0.001f) return INFINITY;
    return R_FIXED * (VCC - vNode) / vNode;
}

bool ReadPressureSensors(float out[NUM_PSENSORS])
{
    bool valid = true;
    for (int i = 0; i < NUM_PSENSORS; i++) {
        uint16_t x = analogRead(pressureSensors[i].pin);

        // Rolling average logic
        pressureSensors[i].sum -= pressureSensors[i].buf[pressureSensors[i].idx];
        pressureSensors[i].buf[pressureSensors[i].idx] = x;
        pressureSensors[i].sum += x;
        pressureSensors[i].idx = (pressureSensors[i].idx + 1) % FILTER_N;

        float avg = (float)pressureSensors[i].sum / (float)FILTER_N;
        out[i] = estimateRsensorOhm(avg) / 1000;

        if (out[i] < 0) valid = false;
    }
    return valid;
}

//FLEX SENSOR FUNCTIONS

static float estimateRflex(float adcAvg)
{
    float vNode = (FLEX_VCC * adcAvg) / FLEX_ADC_MAX;
    if (vNode < 0.001f) return INFINITY;
    return FLEX_R_FIXED * (FLEX_VCC - vNode) / vNode;
}

void FlexSensorSetup(int pin)
{
    flexSum = 0;
    flexIdx = 0;

    analogReadResolution(12);

    for (int i = 0; i < FLEX_BUF_SIZE; i++) {
        uint16_t x = analogRead(pin);
        flexBuf[i] = x;
        flexSum   += x;
        delay(5);
    }
}
 
float ReadFlexSensor(int pin)
{
    uint16_t x  = analogRead(pin);
    flexSum    -= flexBuf[flexIdx];
    flexBuf[flexIdx] = x;
    flexSum    += x;
    flexIdx     = (flexIdx + 1) % FLEX_BUF_SIZE;

    float adcAvg = (float)flexSum / (float)FLEX_BUF_SIZE;
    return estimateRflex(adcAvg);
}

//READ IR SENSOR FUNCTIONS
void IRSensorSetup(){
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
};

int16_t ReadIRSensor(){
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
};