"""
Plant simulator for PLC4 (Process 4 - RO Feed & Dosing).
Modbus TCP Server address mapping:
  - 100-101: Digital Inputs P401/P402 (pump feedback)
  - 102-103: LIT401.Pv (REAL, 2 registers)
  - 104-107: LIT401 Alarms (AHH, AH, AL, ALL)
  - 200-201: Digital Outputs P401/P402 (PLC writes)
"""

from pymodbus.server.sync import StartTcpServer
from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext
from pymodbus.datastore import ModbusSequentialDataBlock
from pymodbus.device import ModbusDeviceIdentification
import threading
import time
import struct


class PhysicalSimulator4:
    """SWaT physical simulator for PLC4 (T401 tank and RO Feed system)"""

    def __init__(self, context):
        self.context = context
        self.slave_id = 0x00

        # Physical parameters (from plc4.py)
        self.p = {
            "S_t401": 1.5 * 1000000,              # T401 cross-sectional area (mm²)
            "f_mv302": 2.0 * 1000000000 / 3600,   # MV302 (UF outlet) flow rate (mm³/s)
            "f_p401": 2.0 * 1000000000 / 3600,    # P401/P402 flow rate (mm³/s)
            "LIT401_ALL": 250,                     # alarm low low (mm)
            "LIT401_AL": 800,                      # alarm low (mm)
            "LIT401_AH": 1000,                     # alarm high (mm)
            "LIT401_AHH": 1200                     # alarm high high (mm)
        }

        # Initial states
        self.lit401_pv = 900.0  # initial level (mm) - from plc4.py self.result=[900]
        self.lit401_ahh = 0
        self.lit401_ah = 0
        self.lit401_al = 0
        self.lit401_all = 0
        self.time_interval = 1.0  # scan interval (s)
        self.print_counter = 0  # counter for print throttling

        # Digital outputs from PLC (write commands)
        self.do_p401_start = 0
        self.do_p402_start = 0

        # Digital inputs to PLC (feedback)
        self.di_p401_run = 0
        self.di_p402_run = 0

        # External inputs (from other PLCs via SCADA)
        self.hmip301status = 1
        self.hmip302status = 1
        self.hmimv301close = 0
        self.hmimv302open = 1
        self.hmimv303close = 0
        self.hmimv304close = 0

        self._init_registers()

    def _read_bool(self, address):
        result = self.context[self.slave_id].getValues(3, address - 1, count=1)
        return result[0]

    def _write_bool(self, address, value):
        self.context[self.slave_id].setValues(3, address - 1, [value])

    def _read_real(self, address):
        """Read a 32-bit REAL from two consecutive Modbus registers"""
        result = self.context[self.slave_id].getValues(3, address - 1, count=2)
        # Convert two 16-bit registers to a 32-bit float (big-endian)
        packed = struct.pack('>HH', result[0], result[1])
        value = struct.unpack('>f', packed)[0]
        return value

    def _write_real(self, address, value):
        """Write a 32-bit REAL to two consecutive Modbus registers"""
        # Convert float to two 16-bit registers (big-endian)
        packed = struct.pack('>f', value)
        unpacked = struct.unpack('>HH', packed)
        self.context[self.slave_id].setValues(3, address - 1, list(unpacked))

    def _init_registers(self):
        # Initialize DI (100-101)
        self._write_bool(100, self.di_p401_run)
        self._write_bool(101, self.di_p402_run)

        # Initialize LIT401 Pv (102-103) and alarms (104-107)
        self._write_real(102, self.lit401_pv)
        self._write_bool(104, self.lit401_ahh)
        self._write_bool(105, self.lit401_ah)
        self._write_bool(106, self.lit401_al)
        self._write_bool(107, self.lit401_all)

        # Initialize DO (200-201)
        self._write_bool(200, self.do_p401_start)
        self._write_bool(201, self.do_p402_start)

    def read_outputs_from_plc(self):
        """Read PLC commands (DO) from Modbus registers"""
        self.do_p401_start = self._read_bool(200)
        self.do_p402_start = self._read_bool(201)

    def simulate_actuator(self):
        """Pump state transitions based on PLC commands"""
        # Pump loopback
        self.di_p401_run = self.do_p401_start
        self.di_p402_run = self.do_p402_start

    def simulate_plant(self):
        """Simulate T401 tank level dynamics"""
        h_t401 = 0.0

        # Inlet from UF filtration (P301 or P302 running, MV301 closed, MV302 open, MV303 closed, MV304 closed)
        if (self.hmip301status == 2 or self.hmip302status == 2) and \
           self.hmimv301close == 1 and self.hmimv302open == 1 and \
           self.hmimv303close == 1 and self.hmimv304close == 1:
            h_t401 += self.p['f_mv302'] / self.p['S_t401']

        # Outlet to RO (P401 or P402 running)
        if self.di_p401_run == 1 or self.di_p402_run == 1:
            h_t401 -= self.p['f_p401'] / self.p['S_t401']

        # Update level
        self.lit401_pv += h_t401 * self.time_interval

        # Boundary protection
        if self.lit401_pv < 0:
            self.lit401_pv = 0.0
        elif self.lit401_pv > 1400:
            self.lit401_pv = 1400.0

        # Calculate alarms
        self.lit401_ahh, self.lit401_ah, self.lit401_al, self.lit401_all = \
            self._calculate_alarms(
                self.lit401_pv,
                self.p['LIT401_AHH'],
                self.p['LIT401_AH'],
                self.p['LIT401_AL'],
                self.p['LIT401_ALL']
            )

    def _calculate_alarms(self, pv, sahh, sah, sal, sall):
        """Calculate 4 alarm states based on thresholds"""
        ahh = 1 if pv >= sahh else 0
        ah = 1 if pv >= sah else 0
        al = 1 if pv <= sal else 0
        all_alarm = 1 if pv <= sall else 0
        return ahh, ah, al, all_alarm

    def write_inputs_to_plc(self):
        """Write plant feedback (DI) to Modbus registers"""
        # Digital inputs
        self._write_bool(100, self.di_p401_run)
        self._write_bool(101, self.di_p402_run)

        # Analog inputs: LIT401
        self._write_real(102, self.lit401_pv)

        # LIT401 alarms
        self._write_bool(104, self.lit401_ahh)
        self._write_bool(105, self.lit401_ah)
        self._write_bool(106, self.lit401_al)
        self._write_bool(107, self.lit401_all)

    def run_cycle(self):
        self.read_outputs_from_plc()
        self.simulate_actuator()
        self.simulate_plant()
        self.write_inputs_to_plc()

        # Print every 5 seconds (counter-based throttling)
        self.print_counter += 1
        if self.print_counter % 5 == 0:
            print(
                "[Plant4] LIT401={0:.1f}mm (AHH={1} AH={2} AL={3} ALL={4}) | "
                "P401={5} P402={6}".format(
                    self.lit401_pv,
                    self.lit401_ahh,
                    self.lit401_ah,
                    self.lit401_al,
                    self.lit401_all,
                    self.di_p401_run,
                    self.di_p402_run,
                )
            )

    def start(self):
        print("[Plant Simulator 4] Starting...")
        while True:
            try:
                self.run_cycle()
                time.sleep(self.time_interval)
            except Exception as exc:
                print("[Plant Simulator 4] Error: {0}".format(exc))
                time.sleep(1)


def run_modbus_server(context):
    identity = ModbusDeviceIdentification()
    identity.VendorName = "SWAT Simulator"
    identity.ProductCode = "PlantSim4"
    identity.VendorUrl = "http://github.com/bashwork/pymodbus/"
    identity.ProductName = "SWAT Process4 Simulator"
    identity.ModelName = "PlantSim V4.0"
    identity.MajorMinorRevision = "1.0.0"

    print("[Physical4] Starting Modbus TCP server on 0.0.0.0:505")
    StartTcpServer(context, identity=identity, address=("0.0.0.0", 505))


if __name__ == "__main__":
    store = ModbusSlaveContext(
        hr=ModbusSequentialDataBlock(1, [0] * 400)
    )
    context = ModbusServerContext(slaves=store, single=True)

    plant_sim = PhysicalSimulator4(context)

    server_thread = threading.Thread(
        target=run_modbus_server, args=(context,), daemon=True
    )
    server_thread.start()

    time.sleep(2)
    plant_sim.start()
