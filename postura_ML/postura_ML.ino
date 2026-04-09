#include <TensorFlowLite.h>
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "postura_ble.h"
#include "postura_model.h" //this is the model we've trained and has been converted into a c array file, needs to be flashed

const int kInputSize = 9;
const int kOutputSize = 1;


//Python expects : LT, RT, LB, RB

////looking at it from front
//pin A0 is top right, pin A2 is bottom right
//pin A1 is top left, pin A3 is bottom left

int pins[NUM_PSENSORS] = {A1, A0, A3, A2};
//                        LT  RT  LB  RB

//for normalizing data set
const float robust_center[4] = {258.5, 375.5, 360.0, 249.5};
const float robust_scale[4]  = {440.25, 833.25, 824.75, 997.0};

constexpr int kTensorArenaSize = 8 * 1024;
alignas(16) uint8_t tensor_arena[kTensorArenaSize];

tflite::AllOpsResolver resolver;
tflite::MicroInterpreter* interpreter = nullptr;

int max_index(float* arr, int size) {
    int max_i = 0;
    for (int i = 1; i < size; i++) {
        if (arr[i] > arr[max_i]) max_i = i;
    }
    return max_i;
}

void setup() {
    Serial.begin(115200);
    BLEsetup();

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
    BLEDevice central = BLE.central();
    float readings[NUM_PSENSORS];
    ReadPressureSensors(readings);
    for (int i = 0; i < NUM_PSENSORS; i++) {
        Serial.println(readings[i]);
    }

    int16_t lt_invalid    = (readings[0] < 0.0f) ? 1 : 0;
    int16_t rt_invalid    = (readings[1] < 0.0f) ? 1 : 0;
    int16_t lb_invalid    = (readings[2] < 0.0f) ? 1 : 0;
    int16_t rb_invalid    = (readings[3] < 0.0f) ? 1 : 0;
    int16_t total_invalid = lt_invalid + rt_invalid + lb_invalid + rb_invalid;

    float* input = interpreter->input(0)->data.f;

    // Scale pressure cols — zero invalid first 
    for (int i = 0; i < 4; i++) {
        float val = (readings[i] < 0.0f) ? 0.0f : readings[i];
        input[i] = (val - robust_center[i]) / robust_scale[i];
    }

    // Flags pass through unscaled
    input[4] = (float)total_invalid;
    input[5] = (float)lt_invalid;
    input[6] = (float)rt_invalid;
    input[7] = (float)lb_invalid;
    input[8] = (float)rb_invalid;

    if (interpreter->Invoke() != kTfLiteOk) {
        Serial.println("Invoke failed!");
        return;
    }

    float* output = interpreter->output(0)->data.f;
    int predicted_posture = (output[0] > 0.5f) ? 1 : 0;

    Serial.print("Predicted Posture: ");
    Serial.println(predicted_posture);
    if (central) {
        Serial.print("Connected to: ");
        Serial.println(central.address());
        while (central.connected()) {
            if (send_status == true) {
                PostureChar.writeValue((uint8_t)predicted_posture);
            }
        }
        Serial.println("Disconnected");
    }
    delay(400);
}