#include <Arduino.h>
#include <math.h>
#include "sensors.h"

static const float VCC=3.3f;
static const float R_FIXED=10000.0f; 

PressureSensor pressureSensors[NUM_PSENSORS];

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
        out[i] = estimateRsensorOhm(avg);

        if (out[i] < 0) valid = false;
    }
    return valid;
}