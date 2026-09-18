"""
Plant simulator for PLC3 (Process 3 - UF Feed).
Modbus TCP Server address mapping:
  - 100-111: Digital Inputs (valves, pumps, switches)
  - 112-113: LIT301.Pv (REAL, 2 registers)
  - 114-117: LIT301 Alarms (AHH, AH, AL, ALL)
  - 200-209: Digital Outputs (PLC writes)
"""

from pymodbus.server.sync import StartTcpServer
from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext
from pymodbus.datastore import ModbusSequentialDataBlock
from pymodbus.device import ModbusDeviceIdentification
import threading
import time
import struct


class PhysicalSimulator3:
    """SWaT physical simulator for PLC3 (T301 tank and UF Feed system)"""

    def __init__(self, context):
        self.context = context
        self.slave_id = 0x00

        # Physical parameters (from plc3.py)
        self.p = {
            "S_t301": 1.5 * 1000000,              # T301 cross-sectional area (mm²)
            "f_mv201": 2.0 * 1000000000 / 3600,   # MV201 flow rate (mm³/s)
            "f_p301": 2.0 * 1000000000 / 3600,    # P301/P302 flow rate (mm³/s)
            "LIT301_ALL": 250,                     # alarm low low (mm)
            "LIT301_AL": 800,                      # alarm low (mm)
            "LIT301_AH": 1000,                     # alarm high (mm)
            "LIT301_AHH": 1200                     # alarm high high (mm)
        }

        # Initial states
        self.lit301_pv = 890.0  # initial level (mm) - from plc3.py self.result=[890]
        self.lit301_ahh = 0
        self.lit301_ah = 0
        self.lit301_al = 0
        self.lit301_all = 0
        self.time_interval = 1.0  # scan interval (s)
        self.print_counter = 0  # counter for print throttling

        # Digital outputs from PLC (write commands)
        self.do_mv301_open = 0
        self.do_mv301_close = 1
        self.do_mv302_open = 0
        self.do_mv302_close = 1
        self.do_mv303_open = 0
        self.do_mv303_close = 1
        self.do_mv304_open = 0
        self.do_mv304_close = 1
        self.do_p301_start = 0
        self.do_p302_start = 0

        # Digital inputs to PLC (feedback)
        self.di_mv301_zso = 0
        self.di_mv301_zsc = 1
        self.di_mv302_zso = 0
        self.di_mv302_zsc = 1
        self.di_mv303_zso = 0
        self.di_mv303_zsc = 1
        self.di_mv304_zso = 0
        self.di_mv304_zsc = 1
        self.di_p301_run = 0
        self.di_p302_run = 0
        self.di_psh301 = 0
        self.di_dpsh301 = 0

        # External inputs (from other PLCs via SCADA)
        self.hmimv201open = 0  # from PLC2
        self.hmip101status = 1  # from PLC1 (1=stopped, 2=running)

        self._init_registers()

    def _read_bool(self, address):
        result = self.context[self.slave_id].getValues(3, address - 1, count=1)
        return result[0]

    def _write_bool(self, address, value):
        self.context[self.slave_id].setValues(3, address - 1, [value])

    def _init_registers(self):
        # Initialize DI (100-115)
        self._write_bool(100, self.di_mv301_zso)
        self._write_bool(101, self.di_mv301_zsc)
        self._write_bool(102, self.di_mv302_zso)
        self._write_bool(103, self.di_mv302_zsc)
        self._write_bool(104, self.di_mv303_zso)
        self._write_bool(105, self.di_mv303_zsc)
        self._write_bool(106, self.di_mv304_zso)
        self._write_bool(107, self.di_mv304_zsc)
        self._write_bool(108, self.di_p301_run)
        self._write_bool(109, self.di_p302_run)
        self._write_bool(110, self.di_psh301)
        self._write_bool(111, self.di_dpsh301)

        # Initialize DO (200-211)
        self._write_bool(200, self.do_mv301_open)
        self._write_bool(201, self.do_mv301_close)
        self._write_bool(202, self.do_mv302_open)
        self._write_bool(203, self.do_mv302_close)
        self._write_bool(204, self.do_mv303_open)
        self._write_bool(205, self.do_mv303_close)
        self._write_bool(206, self.do_mv304_open)
        self._write_bool(207, self.do_mv304_close)
        self._write_bool(208, self.do_p301_start)
        self._write_bool(209, self.do_p302_start)

    def read_outputs_from_plc(self):
        self.do_mv301_open = self._read_bool(200)
        self.do_mv301_close = self._read_bool(201)
        self.do_mv302_open = self._read_bool(202)
        self.do_mv302_close = self._read_bool(203)
        self.do_mv303_open = self._read_bool(204)
        self.do_mv303_close = self._read_bool(205)
        self.do_mv304_open = self._read_bool(206)
        self.do_mv304_close = self._read_bool(207)
        self.do_p301_start = self._read_bool(208)
        self.do_p302_start = self._read_bool(209)

    def simulate_actuator(self):
        # Valve loopback
        self.di_mv301_zso = self.do_mv301_open
        self.di_mv301_zsc = self.do_mv301_close
        self.di_mv302_zso = self.do_mv302_open
        self.di_mv302_zsc = self.do_mv302_close
        self.di_mv303_zso = self.do_mv303_open
        self.di_mv303_zsc = self.do_mv303_close
        self.di_mv304_zso = self.do_mv304_open
        self.di_mv304_zsc = self.do_mv304_close

        # Pump loopback
        self.di_p301_run = self.do_p301_start
        self.di_p302_run = self.do_p302_start

        # Switches remain static in this simple simulator
        self.di_psh301 = 0
        self.di_dpsh301 = 0

    def simulate_plant(self):
        """Simulate T301 tank level dynamics"""
        h_t301 = 0.0

        # Inlet flow: MV201 open AND P101 running
        if self.hmimv201open == 1 and self.hmip101status == 2:
            h_t301 += self.p['f_mv201'] / self.p['S_t301']

        # Outlet flow: P301 OR P302 running
        if self.di_p301_run == 1 or self.di_p302_run == 1:
            h_t301 -= self.p['f_p301'] / self.p['S_t301']

        # Update level
        self.lit301_pv += h_t301 * self.time_interval

        # Boundary protection
        if self.lit301_pv < 0:
            self.lit301_pv = 0.0
        elif self.lit301_pv > 1400:
            self.lit301_pv = 1400.0

        # Calculate alarms
        self.lit301_ahh, self.lit301_ah, self.lit301_al, self.lit301_all = \
            self._calculate_alarms(
                self.lit301_pv,
                self.p['LIT301_AHH'],
                self.p['LIT301_AH'],
                self.p['LIT301_AL'],
                self.p['LIT301_ALL']
            )

    def _calculate_alarms(self, pv, sahh, sah, sal, sall):
        """Calculate 4 alarm states based on thresholds"""
        ahh = 1 if pv >= sahh else 0
        ah = 1 if pv >= sah else 0
        al = 1 if pv <= sal else 0
        all_alarm = 1 if pv <= sall else 0
        return ahh, ah, al, all_alarm

    def _read_real(self, address):
        """Read REAL value from Modbus register (2 registers)"""
        result = self.context[self.slave_id].getValues(3, address - 1, count=2)
        # Convert two 16-bit registers to 32-bit float
        high = result[0]
        low = result[1]
        bytes_data = struct.pack('>HH', high, low)
        return struct.unpack('>f', bytes_data)[0]

    def _write_real(self, address, value):
        """Write REAL value to Modbus register (2 registers)"""
        # Convert 32-bit float to two 16-bit registers
        bytes_data = struct.pack('>f', value)
        high, low = struct.unpack('>HH', bytes_data)
        self.context[self.slave_id].setValues(3, address - 1, [high, low])

    def write_inputs_to_plc(self):
        # Digital inputs
        self._write_bool(100, self.di_mv301_zso)
        self._write_bool(101, self.di_mv301_zsc)
        self._write_bool(102, self.di_mv302_zso)
        self._write_bool(103, self.di_mv302_zsc)
        self._write_bool(104, self.di_mv303_zso)
        self._write_bool(105, self.di_mv303_zsc)
        self._write_bool(106, self.di_mv304_zso)
        self._write_bool(107, self.di_mv304_zsc)
        self._write_bool(108, self.di_p301_run)
        self._write_bool(109, self.di_p302_run)
        self._write_bool(110, self.di_psh301)
        self._write_bool(111, self.di_dpsh301)

        # Analog inputs: LIT301
        self._write_real(112, self.lit301_pv)

        # LIT301 alarms
        self._write_bool(114, self.lit301_ahh)
        self._write_bool(115, self.lit301_ah)
        self._write_bool(116, self.lit301_al)
        self._write_bool(117, self.lit301_all)

    def run_cycle(self):
        self.read_outputs_from_plc()
        self.simulate_actuator()
        self.simulate_plant()
        self.write_inputs_to_plc()

        # Print every 5 seconds (counter-based throttling)
        self.print_counter += 1
        if self.print_counter % 5 == 0:
            print(
                "[Plant3] LIT301={0:.1f}mm (AHH={1} AH={2} AL={3} ALL={4}) | "
                "MV301: O={5} C={6} | MV302: O={7} C={8} | "
                "MV303: O={9} C={10} | MV304: O={11} C={12} | "
                "P301={13} P302={14}".format(
                    self.lit301_pv,
                    self.lit301_ahh,
                    self.lit301_ah,
                    self.lit301_al,
                    self.lit301_all,
                    self.di_mv301_zso,
                    self.di_mv301_zsc,
                    self.di_mv302_zso,
                    self.di_mv302_zsc,
                    self.di_mv303_zso,
                    self.di_mv303_zsc,
                    self.di_mv304_zso,
                    self.di_mv304_zsc,
                    self.di_p301_run,
                    self.di_p302_run,
                )
            )

    def start(self):
        print("[Plant Simulator 3] Starting...")
        while True:
            try:
                self.run_cycle()
                time.sleep(self.time_interval)
            except Exception as exc:
                print("[Plant Simulator 3] Error: {0}".format(exc))
                time.sleep(1)


def run_modbus_server(context):
    identity = ModbusDeviceIdentification()
    identity.VendorName = "SWAT Simulator"
    identity.ProductCode = "PlantSim3"
    identity.VendorUrl = "http://github.com/bashwork/pymodbus/"
    identity.ProductName = "SWAT Process3 Simulator"
    identity.ModelName = "PlantSim V3.0"
    identity.MajorMinorRevision = "1.0.0"

    print("[Physical3] Starting Modbus TCP server on 0.0.0.0:504")
    StartTcpServer(context, identity=identity, address=("0.0.0.0", 504))


if __name__ == "__main__":
    store = ModbusSlaveContext(
        hr=ModbusSequentialDataBlock(1, [0] * 400)
    )
    context = ModbusServerContext(slaves=store, single=True)

    plant_sim = PhysicalSimulator3(context)

    server_thread = threading.Thread(
        target=run_modbus_server, args=(context,), daemon=True
    )
    server_thread.start()

    time.sleep(2)
    plant_sim.start()
