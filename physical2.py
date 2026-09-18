"""
Plant simulator for PLC2 (Process 2).
Modbus TCP Server address mapping:
  - 100-113: Digital Inputs (PLC reads)
  - 200-209: Digital Outputs (PLC writes)
"""

from pymodbus.server.sync import StartTcpServer
from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext
from pymodbus.datastore import ModbusSequentialDataBlock
from pymodbus.device import ModbusDeviceIdentification
import threading
import time


class PhysicalSimulator2:
    """SWaT physical simulator for PLC2 (loopback IO)."""

    def __init__(self, context):
        self.context = context
        self.slave_id = 0x00

        # Digital outputs from PLC (write commands)
        self.do_mv201_open = 0
        self.do_mv201_close = 0
        self.do_p201_start = 0
        self.do_p202_start = 0
        self.do_p203_start = 0
        self.do_p204_start = 0
        self.do_p205_start = 0
        self.do_p206_start = 0
        self.do_p207_start = 0
        self.do_p208_start = 0

        # Digital inputs to PLC (feedback)
        self.di_mv201_zso = 0
        self.di_mv201_zsc = 1
        self.di_p201_run = 0
        self.di_p202_run = 0
        self.di_p203_run = 0
        self.di_p204_run = 0
        self.di_p205_run = 0
        self.di_p206_run = 0
        self.di_p207_run = 0
        self.di_p208_run = 0
        self.di_ls201 = 0
        self.di_ls202 = 0
        self.di_lsl203 = 0
        self.di_lsll203 = 0

        self.time_interval = 1.0  # scan interval (s)
        self.print_counter = 0  # counter for print throttling
        self._init_registers()

    def _read_bool(self, address):
        result = self.context[self.slave_id].getValues(3, address - 1, count=1)
        return result[0]

    def _write_bool(self, address, value):
        self.context[self.slave_id].setValues(3, address - 1, [value])

    def _init_registers(self):
        # Initialize DI (100-113)
        self._write_bool(100, self.di_mv201_zso)
        self._write_bool(101, self.di_mv201_zsc)
        self._write_bool(102, self.di_p201_run)
        self._write_bool(103, self.di_p202_run)
        self._write_bool(104, self.di_p203_run)
        self._write_bool(105, self.di_p204_run)
        self._write_bool(106, self.di_p205_run)
        self._write_bool(107, self.di_p206_run)
        self._write_bool(108, self.di_p207_run)
        self._write_bool(109, self.di_p208_run)
        self._write_bool(110, self.di_ls201)
        self._write_bool(111, self.di_ls202)
        self._write_bool(112, self.di_lsl203)
        self._write_bool(113, self.di_lsll203)

        # Initialize DO (200-209)
        self._write_bool(200, self.do_mv201_open)
        self._write_bool(201, self.do_mv201_close)
        self._write_bool(202, self.do_p201_start)
        self._write_bool(203, self.do_p202_start)
        self._write_bool(204, self.do_p203_start)
        self._write_bool(205, self.do_p204_start)
        self._write_bool(206, self.do_p205_start)
        self._write_bool(207, self.do_p206_start)
        self._write_bool(208, self.do_p207_start)
        self._write_bool(209, self.do_p208_start)

    def read_outputs_from_plc(self):
        self.do_mv201_open = self._read_bool(200)
        self.do_mv201_close = self._read_bool(201)
        self.do_p201_start = self._read_bool(202)
        self.do_p202_start = self._read_bool(203)
        self.do_p203_start = self._read_bool(204)
        self.do_p204_start = self._read_bool(205)
        self.do_p205_start = self._read_bool(206)
        self.do_p206_start = self._read_bool(207)
        self.do_p207_start = self._read_bool(208)
        self.do_p208_start = self._read_bool(209)

    def simulate_actuator(self):
        # Valve loopback
        self.di_mv201_zso = self.do_mv201_open
        self.di_mv201_zsc = self.do_mv201_close

        # Pump loopback
        self.di_p201_run = self.do_p201_start
        self.di_p202_run = self.do_p202_start
        self.di_p203_run = self.do_p203_start
        self.di_p204_run = self.do_p204_start
        self.di_p205_run = self.do_p205_start
        self.di_p206_run = self.do_p206_start
        self.di_p207_run = self.do_p207_start
        self.di_p208_run = self.do_p208_start

        # Switches remain static in this simple simulator
        self.di_ls201 = 0
        self.di_ls202 = 0
        self.di_lsl203 = 0
        self.di_lsll203 = 0

    def write_inputs_to_plc(self):
        self._write_bool(100, self.di_mv201_zso)
        self._write_bool(101, self.di_mv201_zsc)
        self._write_bool(102, self.di_p201_run)
        self._write_bool(103, self.di_p202_run)
        self._write_bool(104, self.di_p203_run)
        self._write_bool(105, self.di_p204_run)
        self._write_bool(106, self.di_p205_run)
        self._write_bool(107, self.di_p206_run)
        self._write_bool(108, self.di_p207_run)
        self._write_bool(109, self.di_p208_run)
        self._write_bool(110, self.di_ls201)
        self._write_bool(111, self.di_ls202)
        self._write_bool(112, self.di_lsl203)
        self._write_bool(113, self.di_lsll203)

    def run_cycle(self):
        self.read_outputs_from_plc()
        self.simulate_actuator()
        self.write_inputs_to_plc()

        # Print every 5 seconds (counter-based throttling)
        self.print_counter += 1
        if self.print_counter % 5 == 0:
            print(
                "[Plant2] MV201_DO_Open={0} MV201_DI_ZSO={1} "
                "P201_Run={2} P202_Run={3} P203_Run={4} P204_Run={5} "
                "P205_Run={6} P206_Run={7} P207_Run={8} P208_Run={9}".format(
                    self.do_mv201_open,
                    self.di_mv201_zso,
                    self.di_p201_run,
                    self.di_p202_run,
                    self.di_p203_run,
                    self.di_p204_run,
                    self.di_p205_run,
                    self.di_p206_run,
                    self.di_p207_run,
                    self.di_p208_run
                )
            )

    def start(self):
        print("[Plant Simulator 2] Starting...")
        while True:
            try:
                self.run_cycle()
                time.sleep(self.time_interval)
            except Exception as exc:
                print("[Plant Simulator 2] Error: {0}".format(exc))
                time.sleep(1)


def run_modbus_server(context):
    identity = ModbusDeviceIdentification()
    identity.VendorName = "SWAT Simulator"
    identity.ProductCode = "PlantSim2"
    identity.VendorUrl = "http://github.com/bashwork/pymodbus/"
    identity.ProductName = "SWAT Process2 Simulator"
    identity.ModelName = "PlantSim V2.0"
    identity.MajorMinorRevision = "1.0.0"

    print("[Physical2] Starting Modbus TCP server on 0.0.0.0:503")
    StartTcpServer(context, identity=identity, address=("0.0.0.0", 503))


if __name__ == "__main__":
    store = ModbusSlaveContext(
        hr=ModbusSequentialDataBlock(1, [0] * 400)
    )
    context = ModbusServerContext(slaves=store, single=True)

    plant_sim = PhysicalSimulator2(context)

    server_thread = threading.Thread(
        target=run_modbus_server, args=(context,), daemon=True
    )
    server_thread.start()

    time.sleep(2)
    plant_sim.start()
