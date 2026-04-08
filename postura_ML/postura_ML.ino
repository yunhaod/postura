#include <TensorFlowLite.h>
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "postura_ble.h"
#include "postura_model.h" //this is the model we've trained and has been converted into a c array file, needs to be flashed

const int kInputSize = 11;
const int kOutputSize = 2;

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
}

void loop() {
    BLEDevice central = BLE.central();

    // Replace with real IMU readings
    float x = 1, y = 1, z = 1;
    float a = 1, b = 1, c = 1;
    float d = 1, e = 1, f = 1;
    float g = 1, h = 1;
    float sensor_data[kInputSize] = {a, b, c, x, y, z, d, e, f, g, h};

    float* input = interpreter->input(0)->data.f;
    for (int i = 0; i < kInputSize; i++) {
        //apply the normalization of each sensor data and then invoke inference
        input[i] = (sensor_data[i]);
    }

    if (interpreter->Invoke() != kTfLiteOk) {
        Serial.println("Invoke failed!");
        return;
    }

    float* output = interpreter->output(0)->data.f;
    int predicted_posture = max_index(output, kOutputSize);

    Serial.print("Predicted Posture: ");
    Serial.println(predicted_posture);
    if (central) {
        Serial.print("Connected to: ");
        Serial.println(central.address());

    while (central.connected()) {
        if (send_status == true){
            PostureChar.writeValue((uint8_t)predicted_posture);  // send to iOS
        }
    }

    Serial.println("Disconnected");
  }
}