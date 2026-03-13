#include <Arduino.h>
#include <math.h>
#define PRESS_PIN A1

static const float VCC=3.3f;
static const float R_FIXED=10000.0f; 
static const int N=16;
static uint16_t buf[N];
static uint32_t sum=0;
static int idx=0;
static float estimateRsensorOhm(float adcAvg)
{
  float vNode = VCC * adcAvg / 4095.0f;
  if (vNode < 0.001f) return INFINITY;
  return R_FIXED * (VCC - vNode) / vNode;
}

void setup()
{
  Serial.begin(115200);
  delay(200);
  analogReadResolution(12); 
  for (int i = 0; i < N; i++) {
    uint16_t x = analogRead(PRESS_PIN);
    buf[i] = x;
    sum += x;
    delay(5);
  }
  Serial.println("Pressure sensor started.");
}

void loop()
{
  uint16_t x = analogRead(PRESS_PIN);

  sum -= buf[idx];
  buf[idx] = x;
  sum += buf[idx];
  idx = (idx + 1) % N;

  float adcAvg=(float)sum / (float)N;
  float vNode=VCC * adcAvg / 4095.0f;
  float rSens=estimateRsensorOhm(adcAvg);

  Serial.print("ADC=");
  Serial.print(adcAvg, 1);
  Serial.print("  V=");
  Serial.print(vNode, 3);
  Serial.print("V  Rsensor=");
  if (isinf(rSens)) Serial.print("inf");
  else Serial.print(rSens, 1);
  Serial.println(" ohm");
  delay(50);
}