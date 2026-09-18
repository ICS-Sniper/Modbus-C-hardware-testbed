"""
Plant simulator for PLC6 (Process 6 - Product Water).
Modbus TCP Server address mapping:
  - 100-108: Digital Inputs P601/P602/P603 (Auto, Run, Fault feedback)
  - 109-114: Level switches (LSL601/602/603, LSH601/602/603)
  - 200-202: Digital Outputs P601/P602/P603 (PLC writes - start commands)
"""

from pymodbus.server.sync import StartTcpServer
from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext
from pymodbus.datastore import ModbusSequentialDataBlock
from pymodbus.device import ModbusDeviceIdentification
import threading
import time


class PhysicalSimulator6:
    """SWaT physical simulator for PLC6 (Product Water system)"""

    def __init__(self, context):
        self.context = context
        self.slave_id = 0x00

        # Physical parameters for three tanks (T601, T602, T603)
        self.p = {
            "S_t601": 1.0 * 1000000,         # T601 cross-sectional area (mm²)
            "S_t602": 1.0 * 1000000,         # T602 cross-sectional area (mm²)
            "S_t603": 1.0 * 1000000,         # T603 cross-sectional area (mm²)
            "f_p601": 1.0 * 1000000000 / 3600,  # P601 flow rate (mm³/s)
            "f_p602": 1.0 * 1000000000 / 3600,  # P602 flow rate (mm³/s)
            "f_p603": 1.0 * 1000000000 / 3600,  # P603 flow rate (mm³/s)
            "LSL_level": 200,                # LSL alarm level (mm)
            "LSH_level": 700                 # LSH alarm level (mm)
        }

        # Tank levels (mm) - matches plc6.py result1=[200], result2=[200]
        self.lit601_pv = 200.0  # Initial level T601
        self.lit602_pv = 200.0  # Initial level T602
        self.lit603_pv = 200.0  # Initial level T603

        # Level switch states
        self.lsl601_alarm = False
        self.lsl602_alarm = False
        self.lsl603_alarm = False
        self.lsh601_alarm = False
        self.lsh602_alarm = False
        self.lsh603_alarm = False

        # Digital inputs to PLC (feedback)
        self.p601_di_auto = True
        self.p601_di_run = False
        self.p601_di_fault = False
        
        self.p602_di_auto = True
        self.p602_di_run = False
        self.p602_di_fault = False
        
        self.p603_di_auto = True
        self.p603_di_run = False
        self.p603_di_fault = False

        # Digital outputs from PLC (write commands)
        self.do_p601_start = 0
        self.do_p602_start = 0
        self.do_p603_start = 0

        # External inputs (inflow from other processes)
        self.inflow_t601 = 0.5 * 1000000000 / 3600  # Inflow to T601 (mm³/s)
        self.inflow_t602 = 0.5 * 1000000000 / 3600  # Inflow to T602 (mm³/s)
        self.inflow_t603 = 0.5 * 1000000000 / 3600  # Inflow to T603 (mm³/s)

        self.time_interval = 1.0
        self.print_counter = 0

        self._init_registers()

    def _read_bool(self, address):
        result = self.context[self.slave_id].getValues(3, address - 1, count=1)
        return result[0]

    def _write_bool(self, address, value):
        self.context[self.slave_id].setValues(3, address - 1, [value])

    def _read_real(self, address):
        """Read REAL value from Modbus register (2 registers)"""
        import struct
        result = self.context[self.slave_id].getValues(3, address - 1, count=2)
        high = result[0]
        low = result[1]
        bytes_data = struct.pack('>HH', high, low)
        return struct.unpack('>f', bytes_data)[0]

    def _write_real(self, address, value):
        """Write REAL value to Modbus register (2 registers)"""
        import struct
        bytes_data = struct.pack('>f', value)
        high, low = struct.unpack('>HH', bytes_data)
        self.context[self.slave_id].setValues(3, address - 1, [high, low])

    def _init_registers(self):
        # Initialize P601 digital inputs (100-102)
        self._write_bool(100, self.p601_di_auto)
        self._write_bool(101, self.p601_di_run)
        self._write_bool(102, self.p601_di_fault)
        
        # Initialize P602 digital inputs (103-105)
        self._write_bool(103, self.p602_di_auto)
        self._write_bool(104, self.p602_di_run)
        self._write_bool(105, self.p602_di_fault)
        
        # Initialize P603 digital inputs (106-108)
        self._write_bool(106, self.p603_di_auto)
        self._write_bool(107, self.p603_di_run)
        self._write_bool(108, self.p603_di_fault)

        # Initialize level switches (109-114)
        self._write_bool(109, self.lsl601_alarm)
        self._write_bool(110, self.lsl602_alarm)
        self._write_bool(111, self.lsl603_alarm)
        self._write_bool(112, self.lsh601_alarm)
        self._write_bool(113, self.lsh602_alarm)
        self._write_bool(114, self.lsh603_alarm)

        # Initialize digital outputs (200-202)
        self._write_bool(200, self.do_p601_start)
        self._write_bool(201, self.do_p602_start)
        self._write_bool(202, self.do_p603_start)

    def simulate_tank(self, level, inflow, pump_running, flow_rate, area, lsl_level, lsh_level):
        """Simulate tank level dynamics"""
        # Calculate outflow
        outflow = flow_rate if pump_running else 0.0
        
        # Update level (mass balance)
        d_level = (inflow - outflow) / area * self.time_interval
        new_level = max(0, level + d_level)
        
        # Update level switch alarms (matches plc6.py logic)
        lsl_alarm = new_level < lsl_level  # True when level drops below LSL
        lsh_alarm = new_level > lsh_level  # True when level rises above LSH
        
        return new_level, lsl_alarm, lsh_alarm

    def update_inputs(self):
        """Update inputs to PLC (outputs from process)"""
        # P601/602/603 digital inputs
        self._write_bool(100, self.p601_di_auto)
        self._write_bool(101, self.p601_di_run)
        self._write_bool(102, self.p601_di_fault)
        
        self._write_bool(103, self.p602_di_auto)
        self._write_bool(104, self.p602_di_run)
        self._write_bool(105, self.p602_di_fault)
        
        self._write_bool(106, self.p603_di_auto)
        self._write_bool(107, self.p603_di_run)
        self._write_bool(108, self.p603_di_fault)

        # Level switches
        self._write_bool(109, self.lsl601_alarm)
        self._write_bool(110, self.lsl602_alarm)
        self._write_bool(111, self.lsl603_alarm)
        self._write_bool(112, self.lsh601_alarm)
        self._write_bool(113, self.lsh602_alarm)
        self._write_bool(114, self.lsh603_alarm)

    def read_outputs(self):
        """Read outputs from PLC (commands to process)"""
        self.do_p601_start = self._read_bool(200)
        self.do_p602_start = self._read_bool(201)
        self.do_p603_start = self._read_bool(202)

    def run_cycle(self):
        """Main simulation cycle (single iteration)"""
        # Read PLC outputs
        self.read_outputs()

        # Pump loopback (DOL pumps - direct start)
        self.p601_di_run = self.do_p601_start
        self.p602_di_run = self.do_p602_start
        self.p603_di_run = self.do_p603_start

        # Simulate tank levels
        self.lit601_pv, self.lsl601_alarm, self.lsh601_alarm = self.simulate_tank(
            self.lit601_pv, self.inflow_t601, self.p601_di_run,
            self.p["f_p601"], self.p["S_t601"], self.p["LSL_level"], self.p["LSH_level"]
        )
        
        self.lit602_pv, self.lsl602_alarm, self.lsh602_alarm = self.simulate_tank(
            self.lit602_pv, self.inflow_t602, self.p602_di_run,
            self.p["f_p602"], self.p["S_t602"], self.p["LSL_level"], self.p["LSH_level"]
        )
        
        self.lit603_pv, self.lsl603_alarm, self.lsh603_alarm = self.simulate_tank(
            self.lit603_pv, self.inflow_t603, self.p603_di_run,
            self.p["f_p603"], self.p["S_t603"], self.p["LSL_level"], self.p["LSH_level"]
        )

        # Update inputs to PLC
        self.update_inputs()

        # Print status every 5 seconds
        self.print_counter += 1
        if self.print_counter % 5 == 0:
            print(
                "[Plant6] T601: Level={0:.1f}mm, P601_Run={1}, LSL={2}, LSH={3} | "
                "T602: Level={4:.1f}mm, P602_Run={5}, LSL={6}, LSH={7} | "
                "T603: Level={8:.1f}mm, P603_Run={9}, LSL={10}, LSH={11}".format(
                    self.lit601_pv, self.p601_di_run, self.lsl601_alarm, self.lsh601_alarm,
                    self.lit602_pv, self.p602_di_run, self.lsl602_alarm, self.lsh602_alarm,
                    self.lit603_pv, self.p603_di_run, self.lsl603_alarm, self.lsh603_alarm
                )
            )

    def start(self):
        """Start simulation loop (consistent with other physical*.py)"""
        print("[Plant Simulator 6] Starting...")
        while True:
            try:
                self.run_cycle()
                time.sleep(self.time_interval)
            except Exception as exc:
                print("[Plant Simulator 6] Error: {0}".format(exc))
                time.sleep(1)


def run_modbus_server(context):
    identity = ModbusDeviceIdentification()
    identity.VendorName = "SWAT Simulator"
    identity.ProductCode = "PlantSim6"
    identity.VendorUrl = "http://github.com/bashwork/pymodbus/"
    identity.ProductName = "SWAT Process6 Simulator"
    identity.ModelName = "PlantSim V6.0"
    identity.MajorMinorRevision = "1.0.0"

    print("[Physical6] Starting Modbus TCP server on 0.0.0.0:507")
    StartTcpServer(context, identity=identity, address=("0.0.0.0", 507))


if __name__ == "__main__":
    store = ModbusSlaveContext(
        hr=ModbusSequentialDataBlock(1, [0] * 400)
    )
    context = ModbusServerContext(slaves=store, single=True)

    plant_sim = PhysicalSimulator6(context)

    server_thread = threading.Thread(
        target=run_modbus_server, args=(context,), daemon=True
    )
    server_thread.start()

    time.sleep(2)
    plant_sim.start()
