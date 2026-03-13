#include <TensorFlowLite.h>
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "postura_ble.h"
#include "postura_model.h" //this is the model we've trained and has been converted into a c array file, needs to be flashed

const int kInputSize = 7;
const int kOutputSize = 6;

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
    const tflite::Model* model = tflite::GetModel(postura_model_tflite);
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
}

void loop() {
    BLE.poll();

    // Replace with real IMU readings
    float x = 0.0, y = 0.0, z = 0.0;
    float a = 0.0, b = 0.0, c = 0.0, d = 0.0;
    float sensor_data[kInputSize] = {a, b, c, d, x, y, z};

    float* input = interpreter->input(0)->data.f;
    for (int i = 0; i < kInputSize; i++) {
        input[i] = sensor_data[i];
    }

    if (interpreter->Invoke() != kTfLiteOk) {
        Serial.println("Invoke failed!");
        return;
    }

    float* output = interpreter->output(0)->data.f;
    int predicted_posture = max_index(output, kOutputSize);

    Serial.print("Predicted Posture: ");
    Serial.println(predicted_posture);

    delay(100);
}