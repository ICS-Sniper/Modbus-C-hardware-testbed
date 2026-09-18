#!/usr/bin/env python2

# NOTE: https://pymodbus.readthedocs.io/en/latest/examples/asynchronous-server.html

from pymodbus.server.async_io import StartTcpServer
from pymodbus.server.async_io import StartUdpServer
from pymodbus.server.async_io import StartSerialServer

from pymodbus.device import ModbusDeviceIdentification
from pymodbus.datastore import ModbusSequentialDataBlock
from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext
from pymodbus.transaction import ModbusRtuFramer, ModbusAsciiFramer

import argparse
import asyncio
import threading
import time
from datetime import datetime
from queue import Queue, Empty
import struct
import os, sys
base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(base_dir)
from utils_warmRestart import SCADA_TAGS

tags_to_log = ['HMI.P1.State','HMI.P2.State','HMI.P3.State','HMI.P4.State','HMI.P5.State','HMI.P6.State','HMI.P101.Status','HMI.P102.Status','HMI.MV101.Status','HMI.MV201.Status','HMI.FIT101.Pv','HMI.LIT101.Pv','HMI.LS201.Alarm','HMI.LS202.Alarm','HMI.LSL203.Alarm','HMI.LSLL203.Alarm','HMI.P201.Status','HMI.P202.Status','HMI.P203.Status','HMI.P204.Status','HMI.P205.Status','HMI.P206.Status','HMI.P207.Status','HMI.P208.Status','HMI.FIT201.Pv','HMI.AIT201.Pv','HMI.AIT202.Pv','HMI.AIT203.Pv','HMI.P301.Status','HMI.P302.Status','HMI.FIT301.Pv','HMI.LIT301.Pv','HMI.PSH301.Alarm','HMI.DPSH301.Alarm','HMI.DPIT301.Pv','HMI.MV301.Status','HMI.MV302.Status','HMI.MV303.Status','HMI.MV304.Status','HMI.LS401.Alarm','HMI.LIT401.Pv','HMI.P401.Status','HMI.P402.Status','HMI.P403.Status','HMI.P404.Status','HMI.UV401.Status','HMI.AIT401.Pv','HMI.AIT402.Pv','HMI.FIT401.Pv','HMI.AIT501.Pv','HMI.AIT502.Pv','HMI.AIT503.Pv','HMI.AIT504.Pv','HMI.FIT501.Pv','HMI.FIT502.Pv','HMI.FIT503.Pv','HMI.FIT504.Pv','HMI.MV501.Status','HMI.MV502.Status','HMI.MV503.Status','HMI.MV504.Status','HMI.P501.Status','HMI.P502.Status','HMI.LSL601.Alarm','HMI.LSL602.Alarm','HMI.LSL603.Alarm','HMI.LSH601.Alarm','HMI.LSH602.Alarm','HMI.LSH603.Alarm','HMI.P601.Status','HMI.P602.Status','HMI.P603.Status']

def snapshot_producer(q):
    global context
    while context is None:
        print("Producer: Waiting for context to be initialized...")
        time.sleep(1)

    print("Producer: Context initialized, starting data collection...")
    try:
        while True:
            ts = datetime.now().strftime("%d/%b/%Y %H:%M:%S")
            tag_entries = {} # a disctionary of offset -> value
            # We only log holding registers for now
            hr_values = context[0].getValues(3, 0, 999)
            # print(f"[{ts}] Holding Registers: {hr_values}")
            for i, val in enumerate(hr_values):
                tag_entries[i] = val
            q.put((tag_entries, ts))
            time.sleep(10)
    except Exception as e:
        print(f"Producer error: {e}")
    finally:
        print("Stopping snapshot producer...")
        q.put(None)

def snapshot_consumer(q, filename):
    while True:
        try:
            item = q.get_nowait()
        except Empty:
            continue

        if item is None:
            break

        tagentries, ts = item # a dictionary of offset -> value

        tagvalues = ['x'] * len(tags_to_log)

        for tag_tuple in SCADA_TAGS:
            tag_name = tag_tuple[0]
            offset, count = tag_tuple[1], tag_tuple[2]
            if tag_name in tags_to_log:
                if count == 1: # INT
                    tagvalues[tags_to_log.index(tag_name)] = str(tagentries.get(offset, 'x'))
                elif count == 2: # REAL
                    registers = [tagentries.get(offset, 'x'), tagentries.get(offset+1, 'x')]
                    if 'x' not in registers:
                        value = struct.unpack('>f', struct.pack('>HH', registers[0], registers[1]))[0]
                    else:
                        value = 'x'
                    tagvalues[tags_to_log.index(tag_name)] = f"{value:.3f}"
                else:
                    tagvalues[tags_to_log.index(tag_name)] = 'x'

        values = ts+','
        for ctr in range(0,len(tags_to_log)):
            values = values + str(tagvalues[ctr])

            if ctr<len(tags_to_log)-1:
                values = values + ','
            else:
                values = values + "\n"

        with open(filename, "a") as f:
            f.write(values)
            f.flush()
            os.fsync(f.fileno())
        time.sleep(10)

def fsync_dir(path):
    dir_fd = os.open(os.path.dirname(path) or ".", os.O_DIRECTORY)
    try:
        os.fsync(dir_fd)
    finally:
        os.close(dir_fd)

def create_log_file(path):
    # Ensure path exists
    if not os.path.exists(path):
        raise FileNotFoundError("Path does not exist")

    # List all files in the directory
    files = [f for f in os.listdir(path) if f.endswith(".csv")]

    # Extract numeric part of file names (ignore non-numeric ones)
    nums = []
    for f in files:
        name, ext = os.path.splitext(f)
        if name.isdigit():
            nums.append(int(name))

    # Determine the next file number
    next_num = max(nums) + 1 if nums else 1
    new_file = os.path.join(path, str(next_num) + ".csv")

    headers = "t_stamp,"

    for ctr in range(0,len(tags_to_log)):
        headers = headers + tags_to_log[ctr]

        if ctr<len(tags_to_log)-1:
            headers  = headers  + ','
        else:
            headers  = headers  + '\n'
    fd = os.open(new_file, os.O_WRONLY | os.O_CREAT | os.O_APPEND | os.O_SYNC)
    with os.fdopen(fd, "w") as f:
            f.write(headers)
            f.flush()
            os.fsync(f.fileno())
            # print("Saved headers")
            time.sleep(0.5)
    fsync_dir(new_file)
    return os.path.abspath(new_file)

context = None  # to be used by producer thread

async def run_server():
    global context
    parser = argparse.ArgumentParser()

    # NOTE: network
    parser.add_argument("-i", type=str, dest="ip", help="server ip")
    # NOTE: allows non standard port to test without sudo
    parser.add_argument("-p", type=int, dest="port", default=502, help="port number")
    parser.add_argument(
        "-m", type=int, dest="mode", choices=[1], default=1, help="mode"
    )
    # NOTE: tags
    parser.add_argument(
        "-d",
        type=int,
        dest="discrete_inputs",
        choices=list(range(1, 1000)),
        default=10,
        help="number of discrete inputs",
    )
    parser.add_argument(
        "-c",
        type=int,
        dest="coils",
        choices=list(range(1, 1000)),
        default=10,
        help="number of coils",
    )
    parser.add_argument(
        "-r",
        type=int,
        dest="input_registers",
        choices=list(range(1, 1000)),
        default=10,
        help="number of input registers",
    )
    parser.add_argument(
        "-R",
        type=int,
        dest="holding_registers",
        choices=list(range(1, 1000)),
        default=10,
        help="number of holding registers",
    )

    args = parser.parse_args()

    # configure the service logging
    # import logging
    # logging.basicConfig()
    # log = logging.getLogger()
    # log.setLevel(logging.DEBUG)

    # NOTE: initialize everthing to 0
    store = ModbusSlaveContext(
        di=ModbusSequentialDataBlock(0, [0] * args.discrete_inputs),
        co=ModbusSequentialDataBlock(0, [0] * args.coils),
        ir=ModbusSequentialDataBlock(0, [0] * args.input_registers),
        hr=ModbusSequentialDataBlock(0, [0] * args.holding_registers),
        zero_mode=False,
    )

    # NOTE: use 0-based addressing mapped internally to 1-based
    context = ModbusServerContext(slaves=store, single=True)
    print("Context initialized successfully")

    # TODO: server id information
    identity = ModbusDeviceIdentification()
    identity.VendorName = "Pymodbus"
    identity.ProductCode = "PM"
    identity.VendorUrl = "http://github.com/bashwork/pymodbus/"
    identity.ProductName = "Pymodbus Server"
    identity.ModelName = "Pymodbus Server"
    identity.MajorMinorRevision = "1.0"
    server = await StartTcpServer(
        context, identity=identity, address=('0.0.0.0', args.port), defer_start=True
    )
    # await server.serve_forever()

    # Chanyuan: Adding logging codes
    logfilename = create_log_file("/home/ubuntu/test-setup/scadalogs")
    print(f"Created log file: {logfilename}")

    q = Queue()

    # Start the logging consumer thread
    consumer_thread = threading.Thread(target=snapshot_consumer, args=(q, logfilename))
    consumer_thread.daemon = True
    consumer_thread.start()
    print("Consumer thread started")

    # Start the logging producer thread
    producer_thread = threading.Thread(target=snapshot_producer, args=(q,))
    producer_thread.daemon = True
    producer_thread.start()
    print("Producer thread started")
    print(f"Server started on {args.ip}:{args.port}")

    ## End of Logging code: Chanyuan

    try:
        print("Starting server forever...")
        await server.serve_forever()
    except KeyboardInterrupt:
        print("Server shutting down...")
    except Exception as e:
        print(f"Server error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("Cleaning up...")
        q.put(None)

if __name__ == "__main__":
    asyncio.run(run_server(), debug=True)
