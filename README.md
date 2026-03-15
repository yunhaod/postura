Senior Design Project for Impact Innovation Lab
<br>

![Postura Logo](https://github.com/yunhaod/postura/blob/main/imgs/Postura_image.png)
<br>
Postura: Embedded cushion with sensors that utilizes ML to predict posture status
<br>
iOS app receives posture predict and the duration of good or bad posture
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
trasnmit sensor data through BLE to a python script, written into a csv file. This file is useful for training the model in the jupiter notebook.
