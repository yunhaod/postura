# Postura
### Senior Design Project – Impact Innovation Lab

<p align="center">
  <img src="https://github.com/yunhaod/postura/blob/main/imgs/Postura_image.png" width="250">
</p>

**Postura** is an embedded smart cushion that uses onboard sensors and a machine learning model to detect and classify a user's sitting posture.

The system collects sensor data from the cushion, runs a lightweight ML model on the device, and sends posture predictions to an iOS application via Bluetooth Low Energy (BLE).

The iOS app displays:
- Current posture classification
- Whether the posture is **good or bad**
- Duration spent in each posture

---

# System Overview

**Hardware**
- Embedded cushion with multiple sensors
- Microcontroller: **Arduino Nano 33 BLE**

**Software**
- Sensor data collection via BLE
- Python scripts for dataset collection
- Neural network model trained in Jupyter Notebook
- TensorFlow Lite model deployed to the microcontroller
- iOS app for visualization and feedback

---

# Sensors Used

The cushion collects data from the following sensors:

- Left Top Pressure
- Right Top Pressure
- Left Bottom Pressure
- Right Bottom Pressure
- IR Sensor
- Flex Sensor

These values are used as features for the posture classification model.

---

# Posture Classification 

The system first determines whether posture is **good or bad**.  
Bad posture is further classified into more specific categories.

### Good
- Good posture

### Bad
- Neck slouching
- Spine slouch
- Left leaning
- Right leaning
- Severe slouch ("everything bad")

---

# Training Data

Training datasets can be found here:

**Google Drive:**  
https://drive.google.com/drive/folders/1llwXYXDqBAFsbgVDumwpWMneEyu6bSd-

---

# Collecting Sensor Data

To collect training data:

1. Upload the Arduino sketch

2. Run the Python script

The system will:

1. Read live sensor values from the cushion
2. Transmit the data over **BLE**
3. Store the sensor readings in a **CSV file**

The CSV dataset can then be used for training the model in the Jupyter notebook.

---

# Data Preprocessing

Before training, sensor data must be **standardized** so that no feature dominates the model due to scale differences.

Example:

- One sensor range: **-500 to 500**
- Another sensor range: **-30 to 30**

Without normalization, the larger-range feature could bias the model.

We apply **standardization** using the following transformation:

$$
x' = \frac{x - \mu}{\sigma}
$$

Where:

- $x$ = raw sensor value  
- $\mu$ = mean of the feature (computed from the training set)  
- $\sigma$ = standard deviation of the feature

Important:

- Mean and standard deviation are computed **only from the training dataset**
- The same transformation is then applied to validation and test data

---

# Model Training

The training workflow is performed in the **Jupyter Notebook**.

Steps:

1. Load collected CSV data
2. Normalize sensor features
3. Train a simple neural network classifier
4. Convert the trained model to **TensorFlow Lite**

---

# Deployment to the Microcontroller

The trained model is converted into a **TFLite model** and then exported as a **C header file**.

This header file must be placed in the same directory as the Arduino firmware.

The Arduino Nano 33 BLE will then:

1. Load the TFLite model
2. Run inference on incoming sensor data
3. Send posture predictions to the iOS app via BLE

---

# Runtime System Flow
Sensors → Arduino Nano 33 BLE → ML Inference (TFLite) → BLE Transmission → iOS App → Posture Feedback

