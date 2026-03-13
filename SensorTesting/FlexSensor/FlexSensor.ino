#include <Arduino.h>

#define FLEX_PIN A0

static const float R_FIXED = 22000.0f;
static const float VCC = 3.3f;
static const int N = 16;
static uint16_t buf[N];
static uint32_t sum = 0;
static int idx = 0;

static float estimateRflexFromADC(float adcAvg, float adcMax)
{
  float vNode = (VCC * adcAvg) / adcMax;

  if (vNode < 0.001f) return INFINITY;
  return R_FIXED * (VCC - vNode) / vNode;
}

void setup()
{
  Serial.begin(115200);
  delay(200);

  analogReadResolution(12); 
  for (int i = 0; i < N; i++) {
    uint16_t x = analogRead(FLEX_PIN);
    buf[i] = x;
    sum += x;
    delay(5);
  }

  Serial.println("Flex sensor started.");
}

void loop()
{
  uint16_t x = analogRead(FLEX_PIN);

  sum -= buf[idx];
  buf[idx] = x;
  sum += buf[idx];
  idx = (idx + 1) % N;

  float adcAvg = (float)sum / (float)N;
  float rFlex = estimateRflexFromADC(adcAvg, 4095.0f);

  Serial.print("ADC(avg)=");
  Serial.print(adcAvg, 1);
  Serial.print("  Rflex~");
  if (isinf(rFlex)) Serial.print("inf");
  else Serial.print(rFlex, 1);
  Serial.println(" ohm");

  delay(50);
}