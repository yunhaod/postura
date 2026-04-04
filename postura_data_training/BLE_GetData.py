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
        "1 for good, 2 for bad")
    classification = int(input("What is the posture status for these data?"))
    dict = {1:"Good",
            2: "Bad"}
    filename = "1_data.csv"
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

        with open(filename, "a", newline='') as f:
            fields = ["LT", 'RT', 'LB', 'RB', 'Classification']
            writer = csv.writer(f)
            #writer.writerow(fields)

            try:
                while True:
                    # Read characteristics
                    def handle_data(sender, data):
                        value = struct.unpack('<4h', data)

                        print("Decoded:", value)
                        row = list(value[:4]) + [classification]  # keep first 4
                        writer.writerow(row)
                        f.flush()

                    await client.start_notify(sensorCharacteristic, handle_data)

                    while True:
                        await asyncio.sleep(1)

            except KeyboardInterrupt:
                print("Stopping data collection.")


asyncio.run(main())