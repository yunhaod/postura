#include <TensorFlowLite.h>
#include "posture_model.h"  // Include the model


// Define input and output dimensions
const int kInputSize = 3;  // x, y, z from accelerometer
const int kOutputSize = 6; // 3 gesture classes

// TensorFlow Lite model setup
tflite::MicroInterpreter* interpreter = nullptr;


void setup() {
  Serial.begin(115200);

  // Load the TensorFlow Lite model
  static tflite::MicroErrorReporter micro_error_reporter;
  const tflite::Model* model = tflite::GetModel(posture_model_tflite);
 

  static tflite::MicroInterpreter static_interpreter(
      model, resolver, tensor_arena, kTensorArenaSize, &micro_error_reporter);

  interpreter = &static_interpreter;
 
  // Allocate memory
  interpreter->AllocateTensors();
}


void loop() {
  // Get sensor data (e.g., from accelerometer)
  float sensor_data[kInputSize] = {a, b, c, d, x, y, z};  // Replace with actual sensor readings
  
  // Input the data into the model
  float* input = interpreter->input(0)->data.f;
  for (int i = 0; i < kInputSize; i++) {
    input[i] = sensor_data[i];
  }

  // Run inference
  interpreter->Invoke();
  
  // Get the output (gesture classification)
  float* output = interpreter->output(0)->data.f;
  int predicted_posture = max_index(output, kOutputSize);

  // Print the detected gesture
  Serial.print("Predicted Posture: ");
  Serial.println(predicted_posture);
}

// Helper function to get the index of the highest output
int max_index(float* arr, int size) {
  int max_i = 0;
  for (int i = 1; i < size; i++) {
    if (arr[i] > arr[max_i]) {
      max_i = i;
    }
  }
  return max_i;
}