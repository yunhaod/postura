import csv
import asyncio
from bleak import BleakScanner, BleakClient
from PyObjCTools import KeyValueCoding
import struct

async def main():
    # Discover devices
    devices = await BleakScanner.discover()
    logger = None
    print(
        "1 for good, 2 for spine slouch, 3 for left leaning, 4 for right leaning, 5 for everything bad")
    classification = int(input("What is the posture status for these data?"))
    dict = {1: "Good",
            2: "Spine Slouching",
            3: "Left Leaning",
            4: "Right Leaning",
            5: "Everything is bad"}
    filename = str(classification) + "_data.csv"
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

        # TODO: Enter the new characteristics id
        sensorCharacteristic = "b3721400-00b0-4240-ba50-05ca45bf8dec"

        with open(filename, "w", newline='') as f:
            fields = ["LT", 'RT', 'LB', 'RB', 'Flex', 'Classification']
            writer = csv.writer(f)
            writer.writerow(fields)

            try:
                while True:
                    # Read characteristics
                    def handle_data(sender, data):
                        value = struct.unpack('<h', data)[0]  # single int16
                        print(f"Raw int16: {value}  →  actual: {value / 100.0:.2f}")

                        print("Decoded:", value)
                        '''
                        row = list(values[:6]) + [classification]  # keep first 6 if those are your sensors
                        writer.writerow(row)
                        f.flush()
                        '''

                    await client.start_notify(sensorCharacteristic, handle_data)

                    while True:
                        await asyncio.sleep(1)

            except KeyboardInterrupt:
                print("Stopping data collection.")


asyncio.run(main())
