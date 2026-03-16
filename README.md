Senior Design Project for Impact Innovation Lab
<br>

![Postura Logo](https://github.com/yunhaod/postura/blob/main/imgs/Postura_image.png)
<br>
Postura: Embedded cushion with sensors that utilizes ML to predict posture status
<br>
iOS app receives posture predict and the duration of good or bad posture
<br>

Google Drive for Training Model: https://drive.google.com/drive/folders/1llwXYXDqBAFsbgVDumwpWMneEyu6bSd-?usp=sharing

<br>

The datas utilized are: 
[
Left top pressure, right top pressure
left bottom pressure, right bottom pressure
IR sensor, flex sensor
]
<br>

The postures detected and predicted are grouped by whether they're good or bad, and bad postures are further classified into more precise reasonings:
<br>
<br>
Good: Good posture, no explanation :) <br>
Bad: neck slouching, spine slouch, left leaning, right leaning, everything bad :(
<br><br>
To collect data, run BLE_GetData.py and Postura_BLE_GetTrainingData.ino file. These are meant for collecting an already established physical hardware to 
trasnmit sensor data through BLE to a python script, written into a csv file. This file is useful for training the model in the jupiter notebook. Prior to training the model, each sensor data should be normalized to prevent a feature from dominating merely because of its scale (a sensor with ranges -500 to 500 might have more weight than a sensor from range -30 to 30, even though thats not true). 
We compute the mean and stardard deviation of the training set(not the validation or test set). Apply the transformation of x' = \frac{x - \mu}{\sigma} for all x for that feature. 

<br>
The jupiter notebook then converts the simple neural network model into a tflite file, which is written into a c header file. This file should then be moved into the same directory as the file thats then loaded onto the Arduino Nano 33 BLE, which will process the BLE connections and send predictions invoked on the current sensor data that its receiving. 
