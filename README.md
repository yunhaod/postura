<div align="center">

<img src="https://github.com/yunhaod/postura/blob/main/imgs/Postura_image.png" width="220" alt="Postura Logo"/>

# Postura

**An Embedded Smart Cushion for Real-Time Posture Classification**

*Senior Design Project · Impact Innovation Lab*

</div>

---

## Table of Contents

1. [Project Summary](#project-summary)
2. [System Architecture](#system-architecture)
3. [Hardware & Sensors](#hardware--sensors)
4. [Posture Classes](#posture-classes)
5. [Step 1 — Collecting Training Data](#step-1--collecting-training-data)
6. [Step 2 — Data Preprocessing](#step-2--data-preprocessing)
7. [Step 3 — Training the Model](#step-3--training-the-model)
8. [Step 4 — Deploying to the Microcontroller](#step-4--deploying-to-the-microcontroller)
9. [iOS App](#ios-app)
10. [Training Data](#training-data)

---

## Project Summary

**Postura** is an embedded smart cushion that detects and classifies a user's sitting posture using onboard pressure and flex sensors. A lightweight neural network runs directly on the microcontroller — no cloud or external server required — and sends posture predictions to an iOS app via **Bluetooth Low Energy (BLE)**.

The iOS app gives the user real-time feedback on:
- Whether their posture is **good or bad**
- **How long** they've spent in each posture throughout the session

The end-to-end pipeline spans hardware, embedded firmware, machine learning, and mobile development.

---

## System Architecture

The diagram below shows how data flows through the full system — from raw sensor readings on the cushion all the way to posture feedback on the phone.

```
┌─────────────────────────────┐
│        Smart Cushion        │
│                             │
│  Pressure Sensors (×4)      │
│             │               │
│             ▼               │
│  Arduino Nano 33 BLE        │
│  └─ TFLite Model Inference  │
└─────────────┬───────────────┘
              │  BLE
              ▼
┌─────────────────────────────┐
│         iOS App             │
│                             │
│  • Posture classification   │
│  • Good / bad indicator     │
│  • Duration per posture     │
└─────────────────────────────┘
```

---

## Hardware & Sensors

**Microcontroller:** Arduino Nano 33 BLE

The cushion uses four sensor channels as input features to the ML model:

| Sensor | Location / Role |
|---|---|
| Left Top Pressure | Upper-left region of the seat |
| Right Top Pressure | Upper-right region of the seat |
| Left Bottom Pressure | Lower-left region of the seat |
| Right Bottom Pressure | Lower-right region of the seat |

---

## Posture Classification

It determines whether posture is good or bad, and if bad, classifies the specific type. This keeps the problem structured and makes it easier to give actionable feedback.

| Label | Good/Bad | Description |
|---|---|---|
| Good posture | ✅ Good | Balanced, upright sitting position |
| Bad posture | ❌ Bad | Rounded, collapsed lower back, other bad postures |

---

## Step 1 — Collecting Training Data

Before the model can be trained, labeled sensor data must be collected for each posture class.

**How it works:**
1. Upload the Arduino sketch to the Nano 33 BLE
2. Sit in the target posture on the cushion
3. Run the Python data collection script

The script will:
- Connect to the Arduino over BLE
- Stream live sensor readings from all 4 channels
- Save the readings to a labeled **CSV file**

One CSV is collected per posture class, then merged for training. The resulting dataset contains rows of five sensor values, each labeled with a posture class.

> 📁 Pre-collected datasets are available on [Google Drive](https://drive.google.com/drive/folders/1llwXYXDqBAFsbgVDumwpWMneEyu6bSd-)

---

## Step 2 — Data Preprocessing

Raw sensor values cannot be fed directly into the model because the sensors sensitivity is roughly a little different


$$x' = \frac{x - \mu}{\sigma}$$

| Symbol | Meaning |
|---|---|
| $x$ | Raw sensor value |
| $M$ | Median of that feature across the training set |
| $IQR$ | Interquartile range of that feature across the training set |
| $x'$ | Normalized value fed into the model |

> ⚠️ **Important:** $\M$ and $\IQR$ are computed **only from training data**. The same values are then applied to normalize the validation and test sets — this prevents data leakage.

---

## Step 3 — Training the Model

Model training is done in the **Jupyter Notebook** and follows these steps:

**1. Load the CSV dataset**

Combine all per-posture CSVs into a single dataframe with a label column.

**2. Normalize features**

Apply the standardization formula from Step 2 to all five sensor columns.

**3. Train the neural network**

A simple feedforward neural network is trained to map the six normalized sensor values to a posture class. The model is kept small deliberately — it needs to fit on a microcontroller.

**4. Convert to TensorFlow Lite**

TFLite is a compressed, optimized format designed for microcontrollers and mobile devices. The trained Keras model is converted like so:

```python
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()
```

**5. Export as a C header file**

The TFLite binary is embedded into a C array and saved as a `.h` header file that the Arduino firmware can include directly.

---

## Step 4 — Deploying to the Microcontroller

Once the model is exported, place the generated header file in the Arduino firmware directory:

```
postura_data_training/Postura_BLE_GetTrainingData
├── Postura_BLE_GetTrainingData
└── postura_model.h        ← generated in Step 3
```

At runtime, the Arduino will:

1. **Load** the TFLite model from flash memory
2. **Read** all six sensor channels
3. **Run inference** — passing sensor values through the model to get a posture prediction
4. **Transmit** the predicted class to the iOS app via BLE

---

## iOS App

The companion iOS app connects to the cushion over BLE and displays three pieces of information:

- **Posture classification** — what posture the user is currently in (e.g., "Spine Slouch")
- **Quality indicator** — a simple good / bad label
- **Duration tracking** — how long the user has been in each posture during the current session

---

## Training Data

Jupiter notebook and pre-collected training datasets for all posture classes are available here:

📁 **Google Drive:** https://drive.google.com/drive/folders/1llwXYXDqBAFsbgVDumwpWMneEyu6bSd-

---

<div align="center">
  <sub>Built with TensorFlow Lite · BLE · iOS · Arduino</sub>
</div>
