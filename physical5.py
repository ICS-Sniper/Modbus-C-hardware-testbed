"""
Plant simulator for PLC5 (Process 5 - High Pressure RO).
Modbus TCP Server address mapping:
  - 100-106: P501 VSD inputs (Active, Ready, OutputFreq[2], Faulted, Auto, Run)
  - 107-113: P502 VSD inputs (Active, Ready, OutputFreq[2], Faulted, Auto, Run)
  - 114-121: MV501-504 valve feedback (DI_ZSO, DI_ZSC for each)
  - 200-203: P501 VSD outputs (Start, Stop, FreqCommand[2])
  - 204-207: P502 VSD outputs (Start, Stop, FreqCommand[2])
  - 208-215: MV501-504 valve commands (DO_Open, DO_Close for each)
"""

from pymodbus.server.sync import StartTcpServer
from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext
from pymodbus.datastore import ModbusSequentialDataBlock
from pymodbus.device import ModbusDeviceIdentification
import threading
import time
import struct


class PhysicalSimulator5:
    """SWaT physical simulator for PLC5 (High Pressure RO system)"""

    def __init__(self, context):
        self.context = context
        self.slave_id = 0x00

        # Physical parameters
        self.p = {
            "f_p501": 2.0 * 1000000000 / 3600,    # P501 flow rate at 100% (mm³/s)
            "f_p502": 2.0 * 1000000000 / 3600,    # P502 flow rate at 100% (mm³/s)
            "speed_min": 10.0,                     # Minimum VSD speed (%)
            "speed_max": 100.0                     # Maximum VSD speed (%)
        }

        # Initial states - P501 VSD
        self.p501_active = False
        self.p501_ready = True
        self.p501_output_freq = 0.0
        self.p501_faulted = False
        self.p501_di_auto = True
        self.p501_di_run = False
        
        # Initial states - P502 VSD
        self.p502_active = False
        self.p502_ready = True
        self.p502_output_freq = 0.0
        self.p502_faulted = False
        self.p502_di_auto = True
        self.p502_di_run = False

        # Valve states - MV501-504
        # Digital outputs from PLC (valve commands)
        self.do_mv501_open = 0
        self.do_mv501_close = 1
        self.do_mv502_open = 0
        self.do_mv502_close = 1
        self.do_mv503_open = 0
        self.do_mv503_close = 1
        self.do_mv504_open = 0
        self.do_mv504_close = 1
        
        # Digital inputs to PLC (valve feedback)
        self.di_mv501_zso = 0
        self.di_mv501_zsc = 1
        self.di_mv502_zso = 0
        self.di_mv502_zsc = 1
        self.di_mv503_zso = 0
        self.di_mv503_zsc = 1
        self.di_mv504_zso = 0
        self.di_mv504_zsc = 1

        # VSD/Pump outputs from PLC (write commands)
        self.do_p501_start = 0
        self.do_p501_stop = 0
        self.p501_freq_command = 0.0
        
        self.do_p502_start = 0
        self.do_p502_stop = 0
        self.p502_freq_command = 0.0

        self.time_interval = 1.0
        self.print_counter = 0

        self._init_registers()

    def _read_bool(self, address):
        result = self.context[self.slave_id].getValues(3, address - 1, count=1)
        return result[0]

    def _write_bool(self, address, value):
        self.context[self.slave_id].setValues(3, address - 1, [value])

    def _read_real(self, address):
        """Read a 32-bit REAL from two consecutive Modbus registers"""
        result = self.context[self.slave_id].getValues(3, address - 1, count=2)
        packed = struct.pack('>HH', result[0], result[1])
        value = struct.unpack('>f', packed)[0]
        return value

    def _write_real(self, address, value):
        """Write a 32-bit REAL to two consecutive Modbus registers"""
        packed = struct.pack('>f', value)
        unpacked = struct.unpack('>HH', packed)
        self.context[self.slave_id].setValues(3, address - 1, list(unpacked))

    def _init_registers(self):
        # P501 VSD inputs (100-106)
        self._write_bool(100, self.p501_active)
        self._write_bool(101, self.p501_ready)
        self._write_real(102, self.p501_output_freq)  # 102-103
        self._write_bool(104, self.p501_faulted)
        self._write_bool(105, self.p501_di_auto)
        self._write_bool(106, self.p501_di_run)
        
        # P502 VSD inputs (107-113)
        self._write_bool(107, self.p502_active)
        self._write_bool(108, self.p502_ready)
        self._write_real(109, self.p502_output_freq)  # 109-110
        self._write_bool(111, self.p502_faulted)
        self._write_bool(112, self.p502_di_auto)
        self._write_bool(113, self.p502_di_run)
        
        # Valve feedback inputs (114-121)
        self._write_bool(114, self.di_mv501_zso)
        self._write_bool(115, self.di_mv501_zsc)
        self._write_bool(116, self.di_mv502_zso)
        self._write_bool(117, self.di_mv502_zsc)
        self._write_bool(118, self.di_mv503_zso)
        self._write_bool(119, self.di_mv503_zsc)
        self._write_bool(120, self.di_mv504_zso)
        self._write_bool(121, self.di_mv504_zsc)

        self._write_bool(200, self.do_p501_start)
        self._write_bool(201, self.do_p501_stop)
        self._write_real(202, self.p501_freq_command)
        
        self._write_bool(204, self.do_p502_start)
        self._write_bool(205, self.do_p502_stop)
        self._write_real(206, self.p502_freq_command)
        
        self._write_bool(208, self.do_mv501_open)
        self._write_bool(209, self.do_mv501_close)
        self._write_bool(210, self.do_mv502_open)
        self._write_bool(211, self.do_mv502_close)
        self._write_bool(212, self.do_mv503_open)
        self._write_bool(213, self.do_mv503_close)
        self._write_bool(214, self.do_mv504_open)
        self._write_bool(215, self.do_mv504_close)

    def read_outputs_from_plc(self):
        """Read PLC commands (DO) from Modbus registers"""
        # P501/P502 VSD commands
        self.do_p501_start = self._read_bool(200)
        self.do_p501_stop = self._read_bool(201)
        self.p501_freq_command = self._read_real(202)
        
        self.do_p502_start = self._read_bool(204)
        self.do_p502_stop = self._read_bool(205)
        self.p502_freq_command = self._read_real(206)
        
        # Valve commands (MV501-504)
        self.do_mv501_open = self._read_bool(208)
        self.do_mv501_close = self._read_bool(209)
        self.do_mv502_open = self._read_bool(210)
        self.do_mv502_close = self._read_bool(211)
        self.do_mv503_open = self._read_bool(212)
        self.do_mv503_close = self._read_bool(213)
        self.do_mv504_open = self._read_bool(214)
        self.do_mv504_close = self._read_bool(215)

    def simulate_actuator(self):
        """Simulate actuator behavior for valves and VSDs (corresponds to plc5.py Actuator())"""
        # Valve loopback (MV501-504) - feedback mirrors commands
        self.di_mv501_zso = self.do_mv501_open
        self.di_mv501_zsc = self.do_mv501_close
        self.di_mv502_zso = self.do_mv502_open
        self.di_mv502_zsc = self.do_mv502_close
        self.di_mv503_zso = self.do_mv503_open
        self.di_mv503_zsc = self.do_mv503_close
        self.di_mv504_zso = self.do_mv504_open
        self.di_mv504_zsc = self.do_mv504_close
        
        # P501 VSD simulation
        if self.do_p501_start and not self.do_p501_stop:
            # VSD starting/running
            if not self.p501_active:
                # Ramp up
                self.p501_output_freq = min(self.p501_output_freq + 5.0, self.p501_freq_command / 100.0)
                if self.p501_output_freq >= (self.p501_freq_command / 100.0) - 1.0:
                    self.p501_active = True
                    self.p501_di_run = True
            else:
                # Running - track speed command
                self.p501_output_freq = self.p501_freq_command / 100.0
        elif self.do_p501_stop or not self.do_p501_start:
            # VSD stopping
            if self.p501_active or self.p501_di_run:
                # Ramp down
                self.p501_output_freq = max(self.p501_output_freq - 5.0, 0.0)
                if self.p501_output_freq <= 1.0:
                    self.p501_active = False
                    self.p501_di_run = False
                    self.p501_output_freq = 0.0

        # P502 VSD simulation
        if self.do_p502_start and not self.do_p502_stop:
            # VSD starting/running
            if not self.p502_active:
                # Ramp up
                self.p502_output_freq = min(self.p502_output_freq + 5.0, self.p502_freq_command / 100.0)
                if self.p502_output_freq >= (self.p502_freq_command / 100.0) - 1.0:
                    self.p502_active = True
                    self.p502_di_run = True
            else:
                # Running - track speed command
                self.p502_output_freq = self.p502_freq_command / 100.0
        elif self.do_p502_stop or not self.do_p502_start:
            # VSD stopping
            if self.p502_active or self.p502_di_run:
                # Ramp down
                self.p502_output_freq = max(self.p502_output_freq - 5.0, 0.0)
                if self.p502_output_freq <= 1.0:
                    self.p502_active = False
                    self.p502_di_run = False
                    self.p502_output_freq = 0.0

    def simulate_plant(self):
        """Simulate plant dynamics (corresponds to plc5.py Plant())
        
        Process 5 (High Pressure RO) has no intermediate tanks.
        Flow dynamics are instantaneous through RO membranes.
        No water level calculations needed.
        """
        # No tank dynamics for P5 - matching plc5.py Plant() implementation
        # which only sets parameters and increments counter
        pass

    def write_inputs_to_plc(self):
        """Write plant feedback (DI/AI) to Modbus registers"""
        # P501 VSD inputs (100-106)
        self._write_bool(100, self.p501_active)
        self._write_bool(101, self.p501_ready)
        self._write_real(102, self.p501_output_freq)  # 102-103
        self._write_bool(104, self.p501_faulted)
        self._write_bool(105, self.p501_di_auto)
        self._write_bool(106, self.p501_di_run)
        
        # P502 VSD inputs (107-113)
        self._write_bool(107, self.p502_active)
        self._write_bool(108, self.p502_ready)
        self._write_real(109, self.p502_output_freq)  # 109-110
        self._write_bool(111, self.p502_faulted)
        self._write_bool(112, self.p502_di_auto)
        self._write_bool(113, self.p502_di_run)
        
        # Valve feedback inputs (114-121)
        self._write_bool(114, self.di_mv501_zso)
        self._write_bool(115, self.di_mv501_zsc)
        self._write_bool(116, self.di_mv502_zso)
        self._write_bool(117, self.di_mv502_zsc)
        self._write_bool(118, self.di_mv503_zso)
        self._write_bool(119, self.di_mv503_zsc)
        self._write_bool(120, self.di_mv504_zso)
        self._write_bool(121, self.di_mv504_zsc)

    def run_cycle(self):
        """One simulation cycle - matches physical4.py structure"""
        self.read_outputs_from_plc()
        self.simulate_actuator()
        self.simulate_plant()
        self.write_inputs_to_plc()

        # Print status every 5 seconds (counter-based throttling)
        self.print_counter += 1
        if self.print_counter % 5 == 0:
            print(
                "[Plant5] P501: Start={0} Speed={1:.1f}Hz Active={2} Run={3} | "
                "P502: Start={4} Speed={5:.1f}Hz Active={6} Run={7}".format(
                    self.do_p501_start,
                    self.p501_output_freq,
                    self.p501_active,
                    self.p501_di_run,
                    self.do_p502_start,
                    self.p502_output_freq,
                    self.p502_active,
                    self.p502_di_run
                )
            )

    def start(self):
        """Main loop - matches physical4.py structure"""
        print("[Plant Simulator 5] Starting...")
        while True:
            try:
                self.run_cycle()
                time.sleep(self.time_interval)
            except Exception as exc:
                print("[Plant Simulator 5] Error: {0}".format(exc))
                time.sleep(1)


def run_modbus_server(context):
    """Run the Modbus TCP server for PLC5"""
    identity = ModbusDeviceIdentification()
    identity.VendorName = "SWAT Simulator"
    identity.ProductCode = "PlantSim5"
    identity.VendorUrl = "http://github.com/bashwork/pymodbus/"
    identity.ProductName = "SWAT Process5 Simulator"
    identity.ModelName = "PlantSim V5.0"
    identity.MajorMinorRevision = "1.0.0"

    print("[Physical5] Starting Modbus TCP server on 0.0.0.0:506")
    StartTcpServer(context, identity=identity, address=("0.0.0.0", 506))


if __name__ == "__main__":
    store = ModbusSlaveContext(
        hr=ModbusSequentialDataBlock(1, [0] * 400)
    )
    context = ModbusServerContext(slaves=store, single=True)

    plant_sim = PhysicalSimulator5(context)

    server_thread = threading.Thread(
        target=run_modbus_server, args=(context,), daemon=True
    )
    server_thread.start()

    time.sleep(2)
    plant_sim.start()
