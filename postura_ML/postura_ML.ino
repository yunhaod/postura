#include <TensorFlowLite.h>
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "postura_ble.h"
#include "postura_model.h"

const int kInputSize  = 9;
const int kOutputSize = 1;

int pins[NUM_PSENSORS] = {A0, A3, A1, A2};

const float robust_center[4] = {260.0, 174.0, 420.0, 323.0};
const float robust_scale[4]  = {496.0, 352.0, 255.25, 281.25};

constexpr int kTensorArenaSize = 8 * 1024;
alignas(16) uint8_t tensor_arena[kTensorArenaSize];

tflite::AllOpsResolver resolver;
tflite::MicroInterpreter* interpreter = nullptr;

int runInference() {
    float readings[NUM_PSENSORS];
    ReadPressureSensors(readings);

    for (int i = 0; i < NUM_PSENSORS; i++) {
        Serial.print("P"); Serial.print(i); Serial.print(": ");
        Serial.print(readings[i]); Serial.println(" kOhm");
    }

    int16_t lt_invalid = (readings[0] < 0.0f) ? 1 : 0;
    int16_t rt_invalid = (readings[1] < 0.0f) ? 1 : 0;
    int16_t lb_invalid = (readings[2] < 0.0f) ? 1 : 0;
    int16_t rb_invalid = (readings[3] < 0.0f) ? 1 : 0;
    int16_t total_invalid = lt_invalid + rt_invalid + lb_invalid + rb_invalid;

    if (total_invalid == NUM_PSENSORS) {
        Serial.println("No one seated.");
        return -1;
    }

    float* input = interpreter->input(0)->data.f;

    for (int i = 0; i < 4; i++) {
        float val = (readings[i] < 0.0f)
                    ? 0.0f : readings[i];
        input[i] = (val - robust_center[i]) / robust_scale[i];
    }

    input[4] = (float)total_invalid;
    input[5] = (float)lt_invalid;
    input[6] = (float)rt_invalid;
    input[7] = (float)lb_invalid;
    input[8] = (float)rb_invalid;

    if (interpreter->Invoke() != kTfLiteOk) {
        Serial.println("Invoke failed!");
        return -1;
    }

    float* output = interpreter->output(0)->data.f;
    Serial.print("Model output: "); Serial.println(output[0]);
    return (output[0] > 0.5f) ? 1 : 0;
}

void setup() {
    Serial.begin(115200);
    BLEsetup(); // BLEsetup handles everything including StartBLEservice, don't call it again

    const tflite::Model* model = tflite::GetModel(postura_model);
    if (model->version() != TFLITE_SCHEMA_VERSION) {
        Serial.println("Model schema mismatch!");
        while (1);
    }

    static tflite::MicroInterpreter static_interpreter(
        model, resolver, tensor_arena, kTensorArenaSize, nullptr);
    interpreter = &static_interpreter;

    if (interpreter->AllocateTensors() != kTfLiteOk) {
        Serial.println("AllocateTensors failed!");
        while (1);
    }

    Serial.println("Model loaded OK");
    PressureSensorSetup(pins);
}

void loop() {
    BLE.poll(); 

    if (device_connected && send_status) {
        int predicted_posture = runInference();

        Serial.print("Predicted Posture: ");
        Serial.println(predicted_posture);

        if (predicted_posture >= 0) {
            PostureChar.writeValue((uint8_t)predicted_posture);
            Serial.println("Wrote posture to BLE");
        }

        delay(400);
    }
}