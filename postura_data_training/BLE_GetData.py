import csv
import asyncio
from bleak import BleakScanner, BleakClient
from PyObjCTools import KeyValueCoding

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
            print('Found Postura')
            break
    if not logger:
        print('Postura not found')
        return

    address = str(KeyValueCoding.getKey(logger.details[0], 'identifier'))
    async with BleakClient(address, timeout=12.0) as client:
        print("Services:")
        svcs = client.services
        for service in svcs:
            print(service)

        #TODO: Enter the new characteristics id 
        sensorCharacteristic = "b3721400-00b0-4240-ba50-05ca45bf8dec"

        with open(filename, "w", newline='') as f:
            fields = ["LT", 'RT', 'LB', 'RB', 'IR', 'Flex','Classification']
            writer = csv.writer(f)
            writer.writerow(fields)

            try:
                while True:
                    # Read characteristics
                    sensor = await client.read_gatt_char(sensorCharacteristic)
                  

                    posture = classification
                    print("Pressure:", sensor)

                    #write to the csv file
                    data = sensor + [posture]
                    writer.writerow(data)
                    f.flush()  # Ensure data is written to the file

                    await asyncio.sleep(10)
            except KeyboardInterrupt:
                print("Stopping data collection.")


asyncio.run(main())
