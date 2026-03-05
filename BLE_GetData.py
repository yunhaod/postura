import csv
import asyncio
from bleak import BleakScanner, BleakClient
from PyObjCTools import KeyValueCoding
from datetime import datetime

async def main():
    # Discover devices
    devices = await BleakScanner.discover()
    logger = None
    print("1 for good, 2 for neck slouching, 3 for spine slouch, 4 for left leaning, 5 for right leaning, 6 for everything bad")
    classification = int(input("What is the posture status for these data?"))
    dict = {1:"Good",
            2:"Neck Slouching", 
            3: "Spine Slouching", 
            4: "Left Leaning",
            5: "Right Leaning",
            6: "Everything is bad"}
    filename = dict[classification] + "_data.csv"
    for d in devices:
        if KeyValueCoding.getKey(d.details[0], 'name') == 'Postura':
            logger = d
            print('Found Arduino')
            break
    if not logger:
        print('Arduino not found')
        return

    address = str(KeyValueCoding.getKey(logger.details[0], 'identifier'))
    async with BleakClient(address, timeout=12.0) as client:
        print("Services:")
        svcs = client.services
        for service in svcs:
            print(service)

        #TODO: Enter the new characteristics id 
        pressureCharacteristic = "" #characteristic uuid
        irCharacteristic = "" #characteristic uuid

        with open(filename, "w", newline='') as f:
            fields = ["LT", 'RT', 'LM', 'RM', 'LB', 'RB', 'IR', 'Classification']
            writer = csv.writer(f)
            writer.writerow(fields)

            try:
                while True:
                    # Read characteristics
                    pressure = await client.read_gatt_char(temperatureCharacteristic)
                    ir_reading = await client.read_gatt_char(humidityCharacteristic)
                  
                    ir = int.from_bytes(ir, byteorder='big')

                    posture = classification
                    print("Pressure:", temperature)
                    print("IR :", ir)

                    #write to the csv file
                    data = pressure + [ir , posture]
                    writer.writerow(data)
                    f.flush()  # Ensure data is written to the file

                    await asyncio.sleep(10)
            except KeyboardInterrupt:
                print("Stopping data collection.")


asyncio.run(main())
